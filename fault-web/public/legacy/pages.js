/*
 * Owner-field filler and draft guard for the public policy/support pages.
 *
 * The privacy policy, support page and deletion page contain no invented owner
 * details. Every owner-specific value is an empty placeholder filled from
 * config.js at runtime through `data-arena-field`. While any value is still a
 * placeholder, the page shows the draft banner and `scripts/check.mjs
 * --release` refuses to pass, so an unfinished policy cannot be published by
 * accident.
 */
(function () {
  'use strict';

  var FIELD_ATTRIBUTE = 'data-arena-field';
  var PLACEHOLDER = /\[\[/;

  function config() {
    return window.ARENA_WEB_CONFIG || {};
  }

  function isPending(value) {
    return value === undefined || value === null || PLACEHOLDER.test(String(value));
  }

  function apply(root) {
    var doc = root || document;
    var nodes = doc.querySelectorAll('[' + FIELD_ATTRIBUTE + ']');
    var pending = [];
    for (var i = 0; i < nodes.length; i += 1) {
      var key = nodes[i].getAttribute(FIELD_ATTRIBUTE);
      var value = config()[key];
      if (isPending(value)) {
        pending.push(key);
        continue;
      }
      var linkPrefix = nodes[i].getAttribute('data-arena-field-link');
      if (linkPrefix && 'href' in nodes[i]) {
        nodes[i].href = linkPrefix + String(value);
      } else {
        nodes[i].textContent = String(value);
      }
    }
    return pending;
  }

  function revealDraftBanner() {
    var banner = document.querySelector('[data-arena-draft]');
    if (!banner) {
      return false;
    }
    var pending = PLACEHOLDER.test(document.body.textContent || '');
    banner.hidden = !pending;
    return pending;
  }

  function ready() {
    apply(document);
    return revealDraftBanner();
  }

  window.ArenaOwnerFields = {
    FIELD_ATTRIBUTE: FIELD_ATTRIBUTE,
    apply: apply,
    isPending: isPending,
    revealDraftBanner: revealDraftBanner,
    ready: ready,
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', ready);
  } else {
    ready();
  }
})();
