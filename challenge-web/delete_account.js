/*
 * External account-deletion request flow for Training Arena.
 *
 * The Google Play User Data policy requires a working web resource where a
 * user can request deletion of their app account without reinstalling the app
 * (support.google.com/googleplay/android-developer/answer/13327111, checked
 * 2026-09-20). This page is that resource.
 *
 * Ownership is verified with the same email one-time-code flow the app uses:
 *   POST {apiBase}/auth/v1/otp      {email, create_user:false}
 *   POST {apiBase}/auth/v1/verify   {type:"email", email, token} -> access_token
 *   POST {apiBase}/functions/v1/arena  {action:"delete_account",params:{}}
 *
 * Safety properties enforced here and checked by test/public_pages.test.mjs
 * and scripts/check.mjs:
 *  - `create_user:false`: the page can never create an account;
 *  - the verified session lives in this closure only (no cookie, no storage,
 *    no analytics, no console output, so no token can leak into a log);
 *  - a failed deletion keeps the session so the user can retry the same
 *    verified request; a completed deletion clears it;
 *  - no guessable token is accepted anywhere;
 *  - every state-changing operation carries an identity token, so a late
 *    response for an abandoned request can neither authenticate another
 *    address nor delete it (forget/restart invalidates pending work).
 */
(function (global) {
  'use strict';

  var OTP_PATH = '/auth/v1/otp';
  var VERIFY_PATH = '/auth/v1/verify';
  var ARENA_PATH = '/functions/v1/arena';
  var EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  var CODE_PATTERN = /^\d{6}$/;

  function normalizeBase(value) {
    return String(value || '').trim().replace(/\/+$/, '');
  }

  function messageFor(stage, status, payload) {
    var providerCode = '';
    if (payload && typeof payload === 'object') {
      if (typeof payload.error_code === 'string') {
        providerCode = payload.error_code;
      } else if (payload.error && typeof payload.error.code === 'string') {
        providerCode = payload.error.code;
      }
    }

    if (stage === 'request') {
      if (status === 0) {
        return { code: 'network', retryable: true,
          message: 'The request could not reach the server. Check your connection and try again.' };
      }
      if (status === 429) {
        return { code: 'rate_limited', retryable: true,
          message: 'Too many codes were requested for this address. Wait a few minutes, then try again.' };
      }
      if (status === 400 || status === 422) {
        return { code: 'email_invalid', retryable: false,
          message: 'That email address was not accepted. Check it and try again.' };
      }
      return { code: 'server', retryable: true,
        message: 'The code could not be sent. Try again in a moment.' };
    }

    if (stage === 'verify') {
      if (status === 0) {
        return { code: 'network', retryable: true,
          message: 'The code could not be checked. Check your connection and try again.' };
      }
      if (status === 429) {
        return { code: 'rate_limited', retryable: true,
          message: 'Too many attempts. Wait a few minutes, then try again.' };
      }
      if (status === 401 || status === 403 || status === 422 ||
          providerCode === 'otp_expired' || providerCode === 'invalid_grant') {
        return { code: 'code_invalid', retryable: false,
          message: 'That code is not valid or has expired. Request a new code and try again.' };
      }
      return { code: 'server', retryable: true,
        message: 'The code could not be checked. Try again in a moment.' };
    }

    if (status === 0) {
      return { code: 'network', retryable: true,
        message: 'The deletion request could not reach the server. Repeating it is safe; try again.' };
    }
    if (status === 401 || status === 403) {
      return { code: 'session_expired', retryable: false,
        message: 'This verification session is no longer valid. If the request already reached us it was processed; otherwise request a new code.' };
    }
    if (payload && typeof payload === 'object' && payload.error &&
        typeof payload.error === 'object') {
      // The backend envelope reports business errors at HTTP 200. That is not
      // a confirmed deletion, so the verified session is kept for a retry.
      return { code: providerCode || 'server', retryable: false,
        message: 'The server did not apply the deletion. Nothing else changed; you can try again or contact support.' };
    }
    return { code: 'server', retryable: true,
      message: 'The server did not confirm the deletion. Repeating the request is safe; try again or contact support.' };
  }

  // A successful deletion must be a real success envelope, never any 2xx.
  function successEnvelope(payload) {
    if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
      return null;
    }
    if (payload.error) {
      return null;
    }
    var data = payload.data;
    if (!data || typeof data !== 'object' || data.ok !== true) {
      return null;
    }
    return { alreadyDeleted: Boolean(data.already_deleted) };
  }

  function createDeletionClient(config, fetchImpl) {
    var cfg = config || {};
    var base = normalizeBase(cfg.apiBase);
    var anonKey = String(cfg.supabaseAnonKey || '');
    var requestFn = fetchImpl ||
      (typeof global.fetch === 'function' ? global.fetch.bind(global) : null);
    var session = null;

    // Monotonic identity marker. Every new request/verify/delete bumps it and
    // captures its value, so a late reply for an abandoned attempt is dropped
    // instead of authenticating or deleting a different address.
    var operationId = 0;

    function begin() {
      operationId += 1;
      return operationId;
    }

    function isCurrent(id) {
      return id === operationId;
    }

    function superseded() {
      return { ok: false, error: { code: 'superseded', retryable: false,
        message: 'This request was replaced by a newer one. Start again.' } };
    }

    function configured() {
      return base !== '' && anonKey !== '' && typeof requestFn === 'function';
    }

    function post(path, body, bearer) {
      return requestFn(base + path, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'apikey': anonKey,
          'authorization': 'Bearer ' + (bearer || anonKey),
        },
        body: JSON.stringify(body),
      }).then(function (response) {
        return response.json().then(
          function (payload) { return { status: response.status, payload: payload }; },
          function () { return { status: response.status, payload: null }; },
        );
      }, function () {
        return { status: 0, payload: null };
      });
    }

    function requestCode(email) {
      var value = String(email || '').trim();
      if (!EMAIL_PATTERN.test(value)) {
        return Promise.resolve({
          ok: false,
          error: { code: 'email_invalid', retryable: false,
            message: 'Enter the email address of the account you want to delete.' },
        });
      }
      if (!configured()) {
        return Promise.resolve({
          ok: false,
          error: { code: 'not_configured', retryable: false,
            message: 'This deletion page is not connected yet. Use the in-app deletion path or contact support.' },
        });
      }
      var id = begin();
      return post(OTP_PATH, { email: value, create_user: false }).then(function (result) {
        if (!isCurrent(id)) {
          return superseded();
        }
        if (result.status >= 200 && result.status < 300) {
          return { ok: true };
        }
        return { ok: false, error: messageFor('request', result.status, result.payload) };
      });
    }

    function verifyCode(email, code) {
      var value = String(email || '').trim();
      var token = String(code || '').replace(/\s+/g, '');
      if (!EMAIL_PATTERN.test(value) || !CODE_PATTERN.test(token)) {
        return Promise.resolve({
          ok: false,
          error: { code: 'code_invalid', retryable: false,
            message: 'Enter the six-digit code from the email.' },
        });
      }
      if (!configured()) {
        return Promise.resolve({
          ok: false,
          error: { code: 'not_configured', retryable: false,
            message: 'This deletion page is not connected yet. Use the in-app deletion path or contact support.' },
        });
      }
      var id = begin();
      return post(VERIFY_PATH, { type: 'email', email: value, token: token })
        .then(function (result) {
          if (!isCurrent(id)) {
            return superseded();
          }
          if (result.status >= 200 && result.status < 300 &&
              result.payload && typeof result.payload.access_token === 'string' &&
              result.payload.access_token !== '') {
            session = result.payload.access_token;
            return { ok: true };
          }
          return { ok: false, error: messageFor('verify', result.status, result.payload) };
        });
    }

    function deleteAccount() {
      if (!session) {
        return Promise.resolve({
          ok: false,
          error: { code: 'not_verified', retryable: false,
            message: 'Verify the account email first.' },
        });
      }
      var id = begin();
      var token = session;
      return post(ARENA_PATH, { action: 'delete_account', params: {} }, token)
        .then(function (result) {
          if (!isCurrent(id)) {
            return superseded();
          }
          var success = successEnvelope(result.payload);
          if (result.status >= 200 && result.status < 300 && success) {
            if (session === token) {
              session = null;
            }
            return { ok: true, alreadyDeleted: success.alreadyDeleted };
          }
          return { ok: false, error: messageFor('delete', result.status, result.payload) };
        });
    }

    function hasSession() {
      return session !== null;
    }

    function forget() {
      // Invalidate any pending request/verify/delete before clearing state.
      operationId += 1;
      session = null;
    }

    return {
      configured: configured,
      requestCode: requestCode,
      verifyCode: verifyCode,
      deleteAccount: deleteAccount,
      hasSession: hasSession,
      forget: forget,
    };
  }

  var api = {
    createDeletionClient: createDeletionClient,
    EMAIL_PATTERN: EMAIL_PATTERN,
    CODE_PATTERN: CODE_PATTERN,
  };

  global.ArenaDeletion = api;
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;
  }
})(typeof window !== 'undefined' ? window : globalThis);
