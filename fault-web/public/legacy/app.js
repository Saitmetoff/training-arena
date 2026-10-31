/*
 * Training Arena challenge landing page.
 *
 * Static, configuration-driven and read-only on GET:
 * - the token only ever goes into `GET /functions/v1/arena?token=...`;
 * - there is no sign-in, no request send, no cookie and no analytics POST;
 * - the Play install route carries the token as the Install Referrer;
 * - the short code and the "reopen this link after installing" instruction
 *   are always visible.
 *
 * Real values come from `config.js` (window.ARENA_WEB_CONFIG). No secret and
 * no service-role key belongs in this file.
 */
(function () {
  'use strict';

  var config = window.ARENA_WEB_CONFIG || {};
  var link = window.ArenaLink;

  var state = {
    token: null,
    status: 'resolving',
    username: '',
    message: '',
    offline: false,
  };

  function byId(id) {
    return document.getElementById(id);
  }

  function esc(value) {
    return String(value == null ? '' : value).replace(/[&<>"']/g, function (character) {
      return {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;',
      }[character];
    });
  }

  function playUrl(token) {
    return link.withReferrer(
      config.playStoreUrl ||
        'https://play.google.com/store/apps/details?id=app.trainingarena.mobile',
      token
    );
  }

  function schemeUrl(token) {
    return 'trainingarena://challenge/' + encodeURIComponent(token);
  }

  function render() {
    var app = byId('challenge-app');
    if (!app) {
      return;
    }
    if (!state.token) {
      app.innerHTML = unavailableHtml(
        'This is not a readable challenge link',
        'Fault links look like https://<host>/c/<code>. Ask your friend for a new live challenge link.'
      );
      return;
    }
    if (state.status === 'resolving') {
      app.innerHTML =
        '<h1 id="screen-title" tabindex="-1">Opening challenge link…</h1>' +
        '<p class="lead">Read-only: nothing is created until you send a request inside the app.</p>' +
        codeCardHtml();
      return;
    }

    var terminal = terminalCopy(state.status);
    if (terminal) {
      app.innerHTML =
        unavailableHtml(terminal.title, state.message || terminal.body) +
        codeCardHtml();
      return;
    }

    var handle = state.username ? '@' + esc(state.username) : 'Your friend';
    var offline = state.status === 'owner_offline';
    var actionTitle = offline ? 'Challenger offline' : 'Live 60-second battle';
    var actionBody = offline
      ? 'Live challenges need both players at the same time. Open the app, sign in and send your request — it is not a replay, and there is no old score to beat.'
      : 'Push-ups or squats, counted by your camera. Both players return and confirm readiness before the battle starts.';

    app.innerHTML =
      '<section class="identity">' +
      '<span class="identity__avatar" aria-hidden="true">' +
      esc(state.username ? state.username.slice(0, 2).toUpperCase() : 'TA') +
      '</span>' +
      '<span class="identity__text"><strong>' +
      handle +
      '</strong><small>challenger · opponent</small></span>' +
      '</section>' +
      '<h1 id="screen-title" tabindex="-1">' +
      handle +
      ' challenges you</h1>' +
      '<p class="lead">Push-ups or squats. 60 seconds, counted by your camera, with the result confirmed by the server.</p>' +
      '<div class="banner banner--' +
      (offline ? 'warning' : 'positive') +
      '"><strong>' +
      esc(actionTitle) +
      '</strong><p>' +
      esc(actionBody) +
      '</p></div>' +
      '<a class="btn btn--primary" href="' +
      esc(schemeUrl(state.token)) +
      '">Open Fault</a>' +
      '<a class="btn btn--secondary" href="' +
      esc(playUrl(state.token)) +
      '" rel="noopener">Get it on Google Play</a>' +
      '<section class="card"><h2>Reopen this link after installing</h2>' +
      '<p>Android App Links and the Play Install Referrer return you to this exact challenge. If nothing reopens, read the short code below to ' +
      handle +
      ' or enter it under Join with code.</p></section>' +
      codeCardHtml() +
      '<section class="card card--flat"><h2>Your camera stays on your phone</h2>' +
      '<p>Camera frames are processed on your device and never uploaded. Only rep counts are sent to the match score.</p></section>';
  }

  function codeCardHtml() {
    return (
      '<section class="card card--code"><h2>Readable short code</h2>' +
      '<p class="code" id="short-code">' +
      esc(link.readableCode(state.token)) +
      '</p>' +
      '<p class="note">Opening this page is read-only. Nothing is created until you send a request inside the app, and a link never replays a past match.</p></section>'
    );
  }

  function terminalCopy(status) {
    switch (status) {
      case 'revoked':
        return {
          title: 'This challenge link was revoked',
          body: 'The owner replaced or revoked it. Ask for a new live challenge link.',
        };
      case 'expired':
        return {
          title: 'This challenge request expired',
          body: 'Requests last 24 hours. Ask for a new live challenge when you are both available.',
        };
      case 'completed':
        return {
          title: 'This challenge already happened',
          body: 'A challenge link is not a rematch. Ask your friend for a new live challenge; nothing is replayed and there is no old score to beat.',
        };
      case 'busy_player':
        return {
          title: 'This player is in another battle',
          body: 'Nothing was sent. Try again after the current battle finishes.',
        };
      case 'blocked':
        return {
          title: 'This challenge is unavailable',
          body: 'You cannot send a challenge to this player. Nothing was sent.',
        };
      case 'unreachable':
        return {
          title: 'The arena is unreachable right now',
          body: 'Challenge availability could not be checked. Nothing was created. Keep the short code and try again later.',
        };
      case 'not_configured':
        return {
          title: 'Challenge availability is not configured',
          body: 'This page cannot check a live challenge yet. Nothing was sent. Keep the short code and try again when the service is available.',
        };
      case 'unavailable':
        return {
          title: 'This challenge link is unavailable',
          body: 'It was revoked, expired, or the account was deleted. A challenge link identifies a person for a new live battle — it never stores or replays a match.',
        };
      default:
        return null;
    }
  }

  function unavailableHtml(title, body) {
    return (
      '<div class="banner banner--warning"><strong>' +
      esc(title) +
      '</strong><p>' +
      esc(body) +
      '</p></div>' +
      '<a class="btn btn--primary" href="' +
      esc(config.publicUrl || 'https://example.invalid') +
      '">Back to Fault</a>'
    );
  }

  function resolveReadOnly(token) {
    var apiBase = String(config.apiBase || '').trim();
    if (!apiBase) {
      state.status = 'not_configured';
      render();
      return;
    }
    var endpoint =
      apiBase.replace(/\/$/, '') +
      '/functions/v1/arena?token=' +
      encodeURIComponent(token);
    fetch(endpoint, {
      method: 'GET',
      headers: { accept: 'application/json' },
      credentials: 'omit',
      cache: 'no-store',
    })
      .then(function (response) {
        if (!response.ok) {
          throw new Error('resolve failed');
        }
        return response.json();
      })
      .then(function (payload) {
        var data = payload && payload.data ? payload.data : null;
        state.status = link.statusFromResolution(data);
        state.username = link.usernameOf(data);
        if (!data || data.available !== true) {
          state.message =
            (data && data.message) ||
            'It was revoked, expired, or the account was deleted.';
        }
        render();
      })
      .catch(function () {
        state.status = 'unreachable';
        render();
      });
  }

  function start() {
    state.token = link.tokenFromLocation(window.location);
    if (!state.token) {
      render();
      return;
    }
    state.status = 'resolving';
    render();
    resolveReadOnly(state.token);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
