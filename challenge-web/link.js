/*
 * Training Arena challenge link parsing.
 *
 * Kept dependency-free and DOM-free so the landing page and Node tests use
 * the same interpretation of a token. No mutation happens here.
 */
(function (root, factory) {
  'use strict';
  if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.ArenaLink = factory();
  }
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';

  var TOKEN_PATTERN = /^[A-Za-z0-9]{6,32}$/;

  function isValidToken(value) {
    return typeof value === 'string' && TOKEN_PATTERN.test(value);
  }

  /** Extracts the token from `/c/<token>` (with optional trailing slash). */
  function tokenFromPath(pathname) {
    var match = /^\/c\/([^/]+)\/?$/.exec(pathname || '');
    if (!match) {
      return null;
    }
    var token = match[1];
    return isValidToken(token) ? token.toLowerCase() : null;
  }

  /** Same fallback used by the app: token query parameter or plain code. */
  function tokenFromQuery(search) {
    var params = new URLSearchParams(search || '');
    var value = params.get('token') || params.get('code');
    if (value && isValidToken(value)) {
      return value.toLowerCase();
    }
    return null;
  }

  function tokenFromLocation(location) {
    return (
      tokenFromPath(location.pathname) ||
      tokenFromQuery(location.search) ||
      null
    );
  }

  /** Groups a token into blocks of four for reading aloud. */
  function readableCode(token) {
    var upper = String(token || '').toUpperCase();
    var out = '';
    for (var i = 0; i < upper.length; i += 1) {
      if (i > 0 && i % 4 === 0) {
        out += '-';
      }
      out += upper[i];
    }
    return out;
  }

  /** Adds the Install Referrer token to the Play URL (best-effort route). */
  function withReferrer(playStoreUrl, token) {
    try {
      var url = new URL(playStoreUrl);
      url.searchParams.set('referrer', 'challenge=' + token);
      return url.toString();
    } catch (error) {
      return playStoreUrl;
    }
  }

  /**
   * Maps a read-only resolve payload `{owner,available,reason}` to the
   * landing state names shared with the app. Unknown input is unavailable.
   */
  function statusFromResolution(payload) {
    if (!payload || typeof payload !== 'object' || payload.available !== true) {
      var reason = payload && typeof payload.reason === 'string' ? payload.reason : '';
      var known = {
        link_revoked: 'revoked',
        revoked: 'revoked',
        request_expired: 'expired',
        expired: 'expired',
        challenge_completed: 'completed',
        match_completed: 'completed',
        completed: 'completed',
      };
      return known[reason] || 'unavailable';
    }
    return payload.owner_offline === true ? 'owner_offline' : 'available';
  }

  function usernameOf(payload) {
    if (payload && payload.owner && typeof payload.owner.username === 'string') {
      return payload.owner.username;
    }
    return '';
  }

  return {
    isValidToken: isValidToken,
    tokenFromPath: tokenFromPath,
    tokenFromQuery: tokenFromQuery,
    tokenFromLocation: tokenFromLocation,
    readableCode: readableCode,
    withReferrer: withReferrer,
    statusFromResolution: statusFromResolution,
    usernameOf: usernameOf,
  };
});
