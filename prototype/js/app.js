/*
 * Training Arena prototype — hash router, screens and interactions.
 *
 * Design preview only: every value is simulated from js/fixtures.js and every
 * state that would need a backend, camera or share sheet says so in the UI.
 * Routes are listed in ROUTES below and documented in design/arena/SCREEN_MAP.md.
 */

(function () {
  'use strict';

  var F = window.ARENA_FIXTURES;
  var main = document.getElementById('main');
  var overlayRoot = document.getElementById('overlay-root');
  var announcer = document.getElementById('live-announcer');
  var previewStateEl = document.querySelector('[data-preview-state]');

  /* ------------------------------------------------------------------ icons */

  var ICONS = {
    back:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M19 12H5M12 5l-7 7 7 7"/></svg>',
    close:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"/></svg>',
    arrow:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14M12 5l7 7-7 7"/></svg>',
    check:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 12.5 9 17.5 20 6.5"/></svg>',
    warning:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 4 2.5 20h19L12 4Z"/><path d="M12 10v4M12 17h.01"/></svg>',
    info:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 11v5M12 8h.01"/></svg>',
    camera:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 8h3l2-3h8l2 3h3v11H3z"/><circle cx="12" cy="13" r="3.5"/></svg>',
    figure:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="5" r="2.5"/><path d="M12 8v7M12 10.5 7 13M12 10.5 17 13M12 15l-3 6M12 15l3 6"/></svg>',
    qr:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><path d="M14 14h3v3h-3zM20 14h1M14 20h1M17 20h1M20 17v4"/></svg>',
    link:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10 14a4 4 0 0 0 6 .5l3-3a4 4 0 0 0-6-6l-1.5 1.5"/><path d="M14 10a4 4 0 0 0-6-.5l-3 3a4 4 0 0 0 6 6L12.5 17"/></svg>',
    share:
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3v12M8 7l4-4 4 4M5 13v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6"/></svg>',
  };

  function icon(name) {
    return ICONS[name] || '';
  }

  /* ---------------------------------------------------------------- helpers */

  function esc(value) {
    return String(value).replace(/[&<>"']/g, function (character) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[character];
    });
  }

  function announce(message) {
    if (announcer) announcer.textContent = message;
  }

  function go(path) {
    var next = '#/' + String(path).replace(/^#?\/?/, '');
    if (location.hash === next) render();
    else location.hash = next;
  }

  function parseHash() {
    var raw = (location.hash || '#/battle').replace(/^#\/?/, '');
    var question = raw.indexOf('?');
    var path = question === -1 ? raw : raw.slice(0, question);
    var query = {};
    if (question !== -1) {
      raw.slice(question + 1).split('&').forEach(function (pair) {
        if (!pair) return;
        var parts = pair.split('=');
        query[decodeURIComponent(parts[0])] = decodeURIComponent(parts.slice(1).join('=') || '');
      });
    }
    return { path: path.replace(/\/+$/, '') || 'battle', query: query };
  }

  function expand(pattern, params) {
    return pattern.replace(/:([A-Za-z0-9]+)/g, function (all, key) {
      return params && params[key] ? params[key] : key;
    });
  }

  function routeFamily(path) {
    return path.split('/')[0];
  }

  function chip(label, variant) {
    return (
      '<span class="chip' + (variant ? ' chip--' + variant : '') + '">' +
      '<span class="chip__dot" aria-hidden="true"></span>' +
      esc(label) +
      '</span>'
    );
  }

  function btn(opts) {
    var classes = ['btn', 'btn--' + (opts.kind || 'secondary')];
    if (opts.block) classes.push('btn--block');
    if (opts.size === 'lg') classes.push('btn--lg');
    var cls = classes.join(' ');
    var actionAttr = opts.action ? ' data-action="' + opts.action + '"' : '';
    var ariaLabel = opts.ariaLabel ? ' aria-label="' + esc(opts.ariaLabel) + '"' : '';
    var leaveAttr = opts.leave
      ? ' data-leave="' + esc(opts.leave) + '" data-leave-href="' + esc(opts.leaveHref || '#/battle') + '"'
      : '';
    if (opts.href) {
      return (
        '<a class="' + cls + '" href="' + esc(opts.href) + '"' + actionAttr + leaveAttr + ariaLabel + '>' + opts.label + '</a>'
      );
    }
    return (
      '<button type="button" class="' + cls + '"' + actionAttr + leaveAttr + ariaLabel +
      (opts.disabled ? ' disabled' : '') +
      (opts.ariaDisabled ? ' aria-disabled="true"' : '') +
      '>' + opts.label + '</button>'
    );
  }

  function identity(profileKey, role, opts) {
    opts = opts || {};
    var profile = F.profiles[profileKey];
    var classes = ['identity'];
    if (opts.accent) classes.push('identity--' + opts.accent);
    if (opts.large) classes.push('identity--lg');
    return (
      '<div class="' + classes.join(' ') + '">' +
      '<span class="identity__avatar" aria-hidden="true">' + esc(profile.initials) + '</span>' +
      '<span class="identity__text">' +
      '<span class="identity__name">' + esc(opts.name || '@' + profile.username) + '</span>' +
      (role ? '<span class="identity__role">' + esc(role) + '</span>' : '') +
      '</span></div>'
    );
  }

  function banner(variant, title, body, actionsHTML) {
    var iconName = variant === 'positive' ? 'check' : variant === 'danger' || variant === 'warning' ? 'warning' : 'info';
    return (
      '<div class="banner' + (variant ? ' banner--' + variant : '') + '">' +
      '<span class="banner__icon" aria-hidden="true">' + icon(iconName) + '</span>' +
      '<div class="grow">' +
      '<p class="banner__title">' + title + '</p>' +
      (body ? '<p class="banner__body">' + body + '</p>' : '') +
      (actionsHTML ? '<div class="banner__actions">' + actionsHTML + '</div>' : '') +
      '</div></div>'
    );
  }

  function screenHead(ctx, opts) {
    opts = opts || {};
    if (!ctx.route.back) return '';
    var href = '#/' + expand(ctx.route.back, ctx.params);
    var leave = ctx.route.leaveConfirm ? ' data-leave="' + esc(ctx.route.leaveConfirm) + '"' : '';
    return (
      '<div class="screen-head">' +
      '<a class="icon-btn" href="' + esc(href) + '" aria-label="' + esc(opts.backLabel || 'Back') + '"' + leave + '>' +
      icon('back') +
      '</a>' +
      (opts.kicker ? '<span class="screen-head__kicker">' + esc(opts.kicker) + '</span>' : '') +
      '</div>'
    );
  }

  function closeHead(label, href) {
    return (
      '<div class="screen-head">' +
      '<a class="icon-btn" href="' + esc(href || '#/battle') + '" aria-label="' + esc(label || 'Close and return to Battle') + '">' +
      icon('close') +
      '</a>' +
      '<span class="screen-head__kicker">Challenge link</span>' +
      '</div>'
    );
  }

  function title(text) {
    return '<h1 class="screen-title" id="screen-title" tabindex="-1">' + esc(text) + '</h1>';
  }

  function hiddenTitle(text) {
    return '<h1 class="visually-hidden" id="screen-title" tabindex="-1">' + esc(text) + '</h1>';
  }

  /* ----------------------------------------------------------------- router */

  var ROUTES = [
    { path: 'battle', docTitle: 'Battle', back: null, nav: 'battle', render: renderBattle },
    { path: 'inbox', docTitle: 'Requests', back: '#/battle', nav: 'battle', render: renderInbox },
    { path: 'c/:token', docTitle: 'Challenge', back: null, nav: null, render: renderChallenge },
    { path: 'c/:token/signin', docTitle: 'Sign in', back: '#/c/:token', nav: null, render: renderSignIn },
    { path: 'c/:token/install', docTitle: 'Install', back: '#/c/:token', nav: null, render: renderInstall },
    { path: 'prepare/:matchId', docTitle: 'Preparation', back: '#/battle', leaveConfirm: 'prepare', nav: null, render: renderPrepare },
    { path: 'match/:matchId/ready', docTitle: 'Ready check', back: '#/battle', leaveConfirm: 'ready', nav: null, render: renderReady },
    { path: 'match/:matchId/countdown', docTitle: 'Countdown', back: '#/battle', leaveConfirm: 'countdown', nav: null, render: renderCountdown },
    { path: 'match/:matchId/live', docTitle: 'Live battle', back: null, leaveConfirm: 'live', nav: null, render: renderLive },
    { path: 'match/:matchId/result', docTitle: 'Result', back: '#/battle', nav: null, render: renderResult },
    { path: 'share/:source', docTitle: 'Share challenge', back: '#/battle', nav: null, render: renderShare },
    { path: 'profile', docTitle: 'Profile', back: null, nav: 'profile', render: renderProfile },
    { path: 'leaderboard', docTitle: 'Leaderboard', back: null, nav: 'leaderboard', render: renderLeaderboard },
    { path: 'settings', docTitle: 'Settings', back: '#/profile', nav: null, render: renderSettings },
  ];

  function matchRoute(path) {
    var segments = path.split('/');
    for (var i = 0; i < ROUTES.length; i += 1) {
      var pattern = ROUTES[i].path.split('/');
      if (pattern.length !== segments.length) continue;
      var params = {};
      var matched = true;
      for (var j = 0; j < pattern.length; j += 1) {
        var part = pattern[j];
        if (part.charAt(0) === ':') params[part.slice(1)] = segments[j];
        else if (part !== segments[j]) {
          matched = false;
          break;
        }
      }
      if (matched) return { route: ROUTES[i], params: params };
    }
    return null;
  }

  /* ------------------------------------------------------------------- sim */

  var simTimers = [];

  function every(ms, fn) {
    var id = window.setInterval(fn, ms);
    simTimers.push(id);
    return id;
  }

  function once(ms, fn) {
    var id = window.setTimeout(fn, ms);
    simTimers.push(id);
    return id;
  }

  function clearSim() {
    simTimers.forEach(function (id) {
      clearInterval(id);
      clearTimeout(id);
    });
    simTimers = [];
  }

  function scoreAt(timeline, t) {
    var last = timeline[0];
    for (var i = 0; i < timeline.length; i += 1) {
      if (timeline[i].t <= t) last = timeline[i];
      else break;
    }
    return last;
  }

  /* ----------------------------------------------------------------- render */

  var ui = {};
  var lastRouteKey = null;
  var currentCtx = null;

  function render() {
    var parsed = parseHash();
    var matched = matchRoute(parsed.path);
    if (!matched) {
      go('battle');
      return;
    }
    var fixture = F.find(matched.route.path, parsed.query.fixture);
    var routeKey = matched.route.path;
    var routeChanged = lastRouteKey !== null && routeKey !== lastRouteKey;
    if (routeKey !== lastRouteKey) ui = {};
    lastRouteKey = routeKey;

    document.documentElement.style.fontSize = parsed.query.zoom === '200' ? '200%' : '100%';
    clearSim();

    var ctx = {
      route: matched.route,
      params: matched.params,
      fixture: fixture,
      data: fixture.data || {},
      query: parsed.query,
      ui: ui,
    };
    currentCtx = ctx;

    document.title = matched.route.docTitle + ' · Training Arena prototype';
    main.innerHTML = matched.route.render(ctx);
    updateNav(matched.route);
    updatePanelReadout(ctx);
    if (previewStateEl) previewStateEl.textContent = 'State: ' + fixture.label + '.';

    var mount = MOUNTS[matched.route.path];
    if (mount) mount(ctx);

    if (routeChanged) {
      var heading = document.getElementById('screen-title');
      if (heading) heading.focus({ preventScroll: true });
      window.scrollTo(0, 0);
    }
  }

  function updateNav(route) {
    Array.prototype.forEach.call(document.querySelectorAll('[data-nav]'), function (item) {
      if (route.nav && item.getAttribute('data-nav') === route.nav) item.setAttribute('aria-current', 'page');
      else item.removeAttribute('aria-current');
    });
  }

  function updatePanelReadout(ctx) {
    var el = document.querySelector('[data-panel-current]');
    if (el && ctx) {
      el.textContent = 'Showing ' + ctx.fixture.id + ' — ' + ctx.fixture.label + '.';
    }
  }

  function setQuery(patch) {
    var parsed = parseHash();
    var query = {};
    Object.keys(parsed.query).forEach(function (key) {
      query[key] = parsed.query[key];
    });
    Object.keys(patch).forEach(function (key) {
      if (patch[key] === null || patch[key] === '') delete query[key];
      else query[key] = patch[key];
    });
    var pairs = Object.keys(query).map(function (key) {
      return encodeURIComponent(key) + '=' + encodeURIComponent(query[key]);
    });
    var next = '#/' + parsed.path + (pairs.length ? '?' + pairs.join('&') : '');
    if (location.hash === next) render();
    else location.hash = next;
  }

  /* ------------------------------------------------------- overlays/dialogs */

  var closeOverlay = null;

  function trapFocus(container) {
    var previous = document.activeElement;
    function focusables() {
      return Array.prototype.filter.call(
        container.querySelectorAll(
          'a[href], button:not([disabled]), select, input:not([disabled]), textarea, [tabindex]:not([tabindex="-1"])'
        ),
        function (el) {
          return el.offsetParent !== null;
        }
      );
    }
    function onKeydown(event) {
      if (event.key === 'Escape') {
        event.preventDefault();
        release();
        return;
      }
      if (event.key !== 'Tab') return;
      var items = focusables();
      if (!items.length) return;
      var first = items[0];
      var last = items[items.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    }
    function release() {
      document.removeEventListener('keydown', onKeydown);
      if (overlayRoot.contains(container)) overlayRoot.innerHTML = '';
      closeOverlay = null;
      if (previous && previous.focus) previous.focus();
    }
    document.addEventListener('keydown', onKeydown);
    closeOverlay = release;
    var items = focusables();
    if (items.length) items[0].focus();
    return release;
  }

  function openDialog(opts) {
    if (closeOverlay) closeOverlay();
    overlayRoot.innerHTML =
      '<div class="dialog" data-dialog-backdrop>' +
      '<div class="dialog__card" role="dialog" aria-modal="true" aria-labelledby="dialog-title">' +
      '<h2 class="dialog__title" id="dialog-title">' + opts.title + '</h2>' +
      '<div class="dialog__body">' + opts.body + '</div>' +
      '<div class="dialog__actions">' +
      (opts.actions || [])
        .map(function (action, index) {
          return (
            '<button type="button" class="btn btn--' + (action.kind || 'secondary') + '" data-dialog-index="' + index + '">' +
            action.label +
            '</button>'
          );
        })
        .join('') +
      '</div></div></div>';

    var dialog = overlayRoot.querySelector('.dialog__card');
    var backdrop = overlayRoot.querySelector('.dialog');
    backdrop.addEventListener('click', function (event) {
      if (event.target === backdrop) closeOverlay && closeOverlay();
    });
    dialog.querySelectorAll('[data-dialog-index]').forEach(function (button) {
      button.addEventListener('click', function () {
        var action = (opts.actions || [])[Number(button.getAttribute('data-dialog-index'))];
        if (closeOverlay) closeOverlay();
        if (action && action.onClick) action.onClick();
      });
    });
    trapFocus(dialog);
  }

  function openPanel() {
    if (closeOverlay) closeOverlay();
    var ctx = currentCtx;
    var family = routeFamily(ctx.route.path);
    var options = F.states
      .filter(function (state) {
        return routeFamily(state.route) === family;
      })
      .map(function (state) {
        return (
          '<option value="' + esc(state.id) + '"' + (state.id === ctx.fixture.id ? ' selected' : '') + '>' +
          esc(state.label) + ' — ' + esc(state.id) +
          '</option>'
        );
      })
      .join('');
    overlayRoot.innerHTML =
      '<div class="panel" data-panel-backdrop>' +
      '<div class="panel__card" role="dialog" aria-modal="true" aria-labelledby="panel-title">' +
      '<div class="panel__head">' +
      '<div><h2 class="panel__title" id="panel-title">Preview states</h2>' +
      '<p class="note">Simulated design data. Switching a state updates the address bar so the same view can be shared.</p></div>' +
      '<button type="button" class="icon-btn" data-panel-close aria-label="Close preview states">' + icon('close') + '</button>' +
      '</div>' +
      '<div class="field"><label for="fixture-select">State for this screen</label>' +
      '<select id="fixture-select">' + options + '</select></div>' +
      '<div class="switch-row"><span class="grow"><strong>200% text size</strong><br><span class="note">Doubles the root font size to check reflow and truncation.</span></span>' +
      '<input class="switch" id="zoom-switch" type="checkbox"' + (ctx.query.zoom === '200' ? ' checked' : '') + ' aria-label="Use 200% text size"></div>' +
      '<div class="switch-row"><span class="grow"><strong>Compress the 60 s round to 12 s</strong><br><span class="note">Preview timing only. Production uses the server clock.</span></span>' +
      '<input class="switch" id="fast-switch" type="checkbox"' + (ctx.query.fast === '0' ? '' : ' checked') + ' aria-label="Compress the round"></div>' +
      '<p class="note" data-panel-current>Showing ' + esc(ctx.fixture.id) + ' — ' + esc(ctx.fixture.label) + '.</p>' +
      '<p class="note">Every value on screen is simulated. Nothing here reaches a server, camera or share sheet.</p>' +
      '</div></div>';

    var panel = overlayRoot.querySelector('.panel__card');
    var backdrop = overlayRoot.querySelector('.panel');
    backdrop.addEventListener('click', function (event) {
      if (event.target === backdrop) closeOverlay && closeOverlay();
    });
    panel.querySelector('[data-panel-close]').addEventListener('click', function () {
      closeOverlay && closeOverlay();
    });
    var select = panel.querySelector('#fixture-select');
    select.addEventListener('change', function () {
      setQuery({ fixture: select.value });
    });
    panel.querySelector('#zoom-switch').addEventListener('change', function (event) {
      setQuery({ zoom: event.target.checked ? '200' : null });
    });
    panel.querySelector('#fast-switch').addEventListener('change', function (event) {
      setQuery({ fast: event.target.checked ? null : '0' });
    });
    trapFocus(panel);
  }

  /* ---------------------------------------------------------------- actions */

  function leaveCopy(kind) {
    var copies = {
      prepare: {
        title: 'Leave preparation?',
        body: 'The match stays open for 10 minutes, then expires. No rating changes if nobody returns.',
        confirm: 'Leave preparation',
      },
      ready: {
        title: 'Cancel this match?',
        body: 'If you leave, the countdown cannot start and the match expires in 10 minutes.',
        confirm: 'Cancel match',
      },
      countdown: {
        title: 'Leave the countdown?',
        body: 'The battle cannot start without you. Leaving counts as abandoning the match.',
        confirm: 'Leave match',
      },
      live: {
        title: 'Leave this battle?',
        body: 'Leaving during a live round forfeits the match. If the service is unreachable, the result is no result and no rating changes.',
        confirm: 'Leave battle',
      },
    };
    return copies[kind] || copies.live;
  }

  function openLeaveDialog(kind, href) {
    var copy = leaveCopy(kind);
    openDialog({
      title: copy.title,
      body: '<p>' + copy.body + '</p>',
      actions: [
        { label: 'Stay', kind: 'secondary' },
        {
          label: copy.confirm,
          kind: 'danger',
          onClick: function () {
            go(String(href || '#/battle').replace('#/', ''));
          },
        },
      ],
    });
  }

  function attemptCopy(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(
        function () {
          announce('Challenge link copied.');
        },
        function () {
          announce('Copy failed. The link is shown on screen.');
        }
      );
    } else {
      announce('Copy unavailable here. The link is shown on screen.');
    }
  }

  function copyLinkDialog() {
    var url = F.link.url;
    openDialog({
      title: 'Copy challenge link',
      body:
        '<p class="url">' + esc(url) + '</p>' +
        '<p class="note">Readable code: <strong>' + esc(F.link.code) + '</strong>.</p>' +
        '<p class="note">The preview uses example.invalid until the owner supplies the real domain (task 05). The production app opens the system share sheet; this prototype only demonstrates the screen.</p>',
      actions: [
        { label: 'Close', kind: 'secondary' },
        { label: 'Copy again', kind: 'primary', onClick: function () { attemptCopy(url); } },
      ],
    });
    attemptCopy(url);
  }

  var actions = {
    'open-preview': function () {
      openPanel();
    },

    'accept-request': function () {
      go('prepare/prep-9f2?fixture=prep-revealed');
    },

    'decline-request': function () {
      openDialog({
        title: 'Decline this request?',
        body: '<p>Nothing is replayed or rescheduled. @zuhra can send a new challenge later.</p>',
        actions: [
          { label: 'Keep request', kind: 'secondary' },
          {
            label: 'Decline',
            kind: 'danger',
            onClick: function () {
              if (currentCtx && currentCtx.route.path === 'inbox') go('inbox?fixture=inbox-empty');
              else go('battle?fixture=battle-clear');
              announce('Request declined. No match was created.');
            },
          },
        ],
      });
    },

    'challenge-friend': function () {
      go('share/new?fixture=share-new');
    },

    'find-opponent': function () {
      go('battle?fixture=battle-searching');
      announce('Ranked search started. Queue seat is simulated.');
    },

    'stop-search': function () {
      go('battle?fixture=battle-clear');
      announce('Search stopped. The queue seat is cancelled.');
    },

    'retry-search': function () {
      go('battle?fixture=battle-searching');
    },

    'join-code': function () {
      openDialog({
        title: 'Join with code',
        body:
          '<div class="field"><label for="code-input">Short code</label>' +
          '<input id="code-input" type="text" autocomplete="off" spellcheck="false" value="' + esc(F.link.code) + '" /></div>' +
          '<p class="note">Simulated. In production the code resolves through the arena API; looking up a code never creates a request or match by itself.</p>',
        actions: [
          { label: 'Cancel', kind: 'secondary' },
          {
            label: 'Join challenge',
            kind: 'primary',
            onClick: function () {
              go('prepare/prep-9f2?fixture=prep-revealed');
            },
          },
        ],
      });
    },

    'send-live-challenge': function () {
      openDialog({
        title: 'Send a live challenge?',
        body:
          '<p>This tells the other player you are ready for a live 60-second battle. It is not a replay and there is no old score to beat.</p>' +
          '<p class="note">Simulated send: in production the request appears in their inbox and expires after 24 hours.</p>',
        actions: [
          { label: 'Cancel', kind: 'secondary' },
          {
            label: 'Send request',
            kind: 'primary',
            onClick: function () {
              go('inbox?fixture=inbox-pending');
              announce('Live challenge sent (simulated).');
            },
          },
        ],
      });
    },

    'challenge-again': function () {
      go('share/new?fixture=share-new');
    },

    'open-signin': function () {
      go('c/' + F.link.token + '/signin?fixture=landing-signed-out');
    },

    'open-install': function () {
      go('c/' + F.link.token + '/install?fixture=landing-not-installed');
    },

    'open-landing': function () {
      go('c/' + F.link.token + '?fixture=landing-default');
    },

    'open-inbox': function () {
      go('inbox?fixture=inbox-pending');
    },

    'sim-signin': function () {
      openDialog({
        title: 'Simulated sign-in',
        body:
          '<p>The prototype cannot open Google or email sign-in. Production (task 05) keeps this challenge pending and returns you to this exact link after sign-in.</p>',
        actions: [
          { label: 'Cancel', kind: 'secondary' },
          {
            label: 'Continue signed in',
            kind: 'primary',
            onClick: function () {
              go('prepare/prep-9f2?fixture=prep-revealed');
            },
          },
        ],
      });
    },

    'sim-install': function () {
      openDialog({
        title: 'Simulated install',
        body:
          '<p>The prototype cannot open Google Play or verify an install. Production uses Android App Links and the Play Install Referrer, then reopens this link automatically.</p>',
        actions: [
          { label: 'Cancel', kind: 'secondary' },
          {
            label: 'Continue after install',
            kind: 'primary',
            onClick: function () {
              go('c/' + F.link.token + '?fixture=landing-default');
            },
          },
        ],
      });
    },

    'sim-share-sheet': function () {
      openDialog({
        title: 'Simulated share sheet',
        body:
          '<p>Production opens the system share sheet with this new challenge text and link. Opening a share sheet is never counted as a referral, and no recipient is created until someone accepts.</p>' +
          '<p class="note">The prototype does not open a share sheet and records nothing.</p>',
        actions: [
          { label: 'Close', kind: 'secondary' },
          {
            label: 'Copy link instead',
            kind: 'primary',
            onClick: function () {
              copyLinkDialog();
            },
          },
        ],
      });
    },

    'copy-link': function () {
      copyLinkDialog();
    },

    'practice-rep': function () {
      ui.practice = true;
      render();
      announce('Practice rep counted, 1 of 1. Unscored.');
    },

    'ready-up': function () {
      if (!ui.practice) {
        announce('Take the practice rep first.');
        return;
      }
      go('match/m1/ready?fixture=ready-waiting');
    },

    'cancel-match': function () {
      openLeaveDialog('ready', '#/battle');
    },

    'retry-inbox': function () {
      go('inbox?fixture=inbox-pending');
    },

    'tracking-rescan': function () {
      if (ui.live && ui.live.unfreezeYou) ui.live.unfreezeYou();
    },

    'opponent-recover': function () {
      if (ui.live && ui.live.unfreezeOpp) ui.live.unfreezeOpp();
    },

    'opponent-forfeit': function () {
      go('match/m1/result?fixture=result-win');
      announce('Forfeit confirmed by the server (simulated).');
    },

    'leave-to-result': function () {
      go('match/m1/result?fixture=result-no-result');
    },

    'retry-connection': function () {
      openDialog({
        title: 'Retrying the service',
        body: '<p>Still unreachable in this prototype. Production reconciles the match conservatively before it can ever declare a winner.</p>',
        actions: [{ label: 'Close', kind: 'secondary' }],
      });
    },

    'share-challenge': function () {
      var from =
        currentCtx && currentCtx.route.path === 'match/:matchId/result' ? currentCtx.fixture.id : 'result-win';
      go('share/result?fixture=share-result&from=' + encodeURIComponent(from));
    },

    'share-format': function (el) {
      var format = el.getAttribute('data-format') === 'feed' ? 'feed' : 'story';
      ui.shareFormat = format;
      render();
      var next = document.querySelector('[data-format="' + format + '"]');
      if (next) next.focus();
      announce('Showing the ' + (format === 'story' ? 'story 9:16' : 'feed 4:5') + ' export.');
    },

    'start-new-challenge': function () {
      go('battle?fixture=battle-clear');
      announce('Ready for a new challenge. The previous result stays as history.');
    },

    'report-user': function () {
      openDialog({
        title: 'Report @' + F.profiles.zuhra.username,
        body:
          '<div class="field"><label for="report-reason">Reason</label>' +
          '<input id="report-reason" type="text" value="Inappropriate behaviour" /></div>' +
          '<p class="note">Simulated. Production sends the report to the arena API with the match id.</p>',
        actions: [
          { label: 'Cancel', kind: 'secondary' },
          {
            label: 'Send report',
            kind: 'primary',
            onClick: function () {
              announce('Report sent (simulated).');
            },
          },
        ],
      });
    },

    'sign-out': function () {
      openDialog({
        title: 'Sign out?',
        body: '<p>You will need to sign in again to accept or send challenges.</p>',
        actions: [
          { label: 'Stay signed in', kind: 'secondary' },
          {
            label: 'Sign out',
            kind: 'danger',
            onClick: function () {
              go('battle?fixture=battle-clear');
              announce('Signed out (simulated).');
            },
          },
        ],
      });
    },

    'delete-account': function () {
      openDialog({
        title: 'Delete account?',
        body: '<p>This removes your profile, challenge links and request history. Receipts shared by other players keep their immutable snapshot. Simulated — nothing is deleted.</p>',
        actions: [
          { label: 'Cancel', kind: 'secondary' },
          {
            label: 'Delete everything',
            kind: 'danger',
            onClick: function () {
              announce('Account deletion is simulated only.');
            },
          },
        ],
      });
    },

    'change-username': function () {
      openDialog({
        title: 'Change username',
        body:
          '<div class="field"><label for="username-input">New username</label>' +
          '<input id="username-input" type="text" value="' + esc(F.profiles.you.username) + '" /></div>' +
          '<p class="note">Usernames are unique. Changing one does not invalidate your challenge link.</p>',
        actions: [
          { label: 'Cancel', kind: 'secondary' },
          {
            label: 'Save (simulated)',
            kind: 'primary',
            onClick: function () {
              announce('Username change is simulated only.');
            },
          },
        ],
      });
    },
  };

  document.addEventListener('click', function (event) {
    var actionEl = event.target.closest('[data-action]');
    if (actionEl) {
      var handler = actions[actionEl.getAttribute('data-action')];
      if (handler) {
        event.preventDefault();
        handler(actionEl);
        return;
      }
    }
    var leaveEl = event.target.closest('[data-leave]');
    if (leaveEl) {
      event.preventDefault();
      openLeaveDialog(
        leaveEl.getAttribute('data-leave'),
        leaveEl.getAttribute('href') || leaveEl.getAttribute('data-leave-href')
      );
    }
  });

  /* ------------------------------------------------------------- screens */

  function renderBattle(ctx) {
    var data = ctx.data;
    var html = '';
    html += title('Battle');

    if (data.incoming) {
      var incoming = data.incoming;
      html +=
        '<section class="card request-card" aria-labelledby="incoming-title">' +
        '<div class="row row--between">' +
        chip('Incoming request', 'opponent') +
        '<span class="meta">Expires in ' + esc(incoming.expires) + '</span>' +
        '</div>' +
        identity(incoming.from, 'challenger · opponent', { accent: 'opponent', large: true }) +
        '<h2 class="card__title" id="incoming-title">@' + esc(incoming.from) + ' challenged you</h2>' +
        '<p class="card__body">' + esc(incoming.exercise) + ' · ' + esc(incoming.mode) + ' · 60 seconds. The exercise is revealed in preparation.</p>' +
        '<div class="request-card__actions">' +
        btn({ label: 'Accept challenge', kind: 'primary', action: 'accept-request' }) +
        btn({ label: 'Decline', kind: 'secondary', action: 'decline-request' }) +
        '</div>' +
        '<p class="note">Accepting creates a live match. Nothing starts until you are both ready and present.</p>' +
        '</section>';
    } else if (data.search) {
      var search = data.search;
      html +=
        '<section class="card" aria-label="Ranked search">' +
        '<div class="row row--between">' +
        chip('Searching', 'warning') +
        '<span class="meta state-readout">' + search.elapsed + ' s / ' + search.limit + ' s</span>' +
        '</div>' +
        '<p class="card__body">Looking for a ranked opponent near your rating. Nobody is promised to be online.</p>' +
        '<div class="timer__bar" role="progressbar" aria-label="Search time used" aria-valuenow="' + search.elapsed + '" aria-valuemin="0" aria-valuemax="' + search.limit + '">' +
        '<span class="timer__fill" style="width:' + Math.round((search.elapsed / search.limit) * 100) + '%"></span>' +
        '</div>' +
        '<div class="request-card__actions">' +
        btn({ label: 'Stop search', kind: 'secondary', action: 'stop-search' }) +
        btn({ label: 'Challenge a friend', kind: 'primary', action: 'challenge-friend' }) +
        '</div>' +
        '<p class="note">Switching to a friend challenge cancels the queue seat. Simulated search; task 08 owns real matchmaking.</p>' +
        '</section>';
    } else if (data.searchStopped) {
      html += banner(
        'warning',
        'No opponent found in 60 seconds',
        'The queue stopped. Nothing was created and no rating changed.',
        btn({ label: 'Retry ranked search', kind: 'secondary', action: 'retry-search' }) +
          btn({ label: 'Challenge a friend', kind: 'primary', action: 'challenge-friend' })
      );
    }

    html +=
      '<div class="stack">' +
      '<button type="button" class="action-hero" data-action="challenge-friend">' +
      '<span class="action-hero__text">' +
      '<span class="action-hero__title">Challenge a friend</span>' +
      '<span class="action-hero__helper">Share a link. Nothing is sent until they open it.</span>' +
      '</span>' +
      '<span class="action-hero__mark" aria-hidden="true">' + icon('arrow') + '</span>' +
      '</button>' +
      '<button type="button" class="action-secondary" data-action="find-opponent">' +
      '<span class="action-secondary__mark" aria-hidden="true">' + icon('figure') + '</span>' +
      '<span class="action-hero__text">' +
      '<span class="action-secondary__title">Find an opponent</span>' +
      '<span class="action-secondary__helper">Ranked · changes rating only after a confirmed result</span>' +
      '</span>' +
      '</button>' +
      '<button type="button" class="btn btn--quiet" data-action="join-code">Join with code</button>' +
      '</div>';
    html +=
      '<p class="note">Live 60-second battles only: push-ups or squats, counted by your camera. No bots and no replaying an old score.</p>';
    return html;
  }

  function renderInbox(ctx) {
    var data = ctx.data;
    var html = screenHead(ctx, { backLabel: 'Back to Battle', kicker: 'Requests' }) + title('Requests');

    if (data.loading) {
      html +=
        '<div class="list" aria-hidden="true"><div class="skeleton"></div><div class="skeleton"></div><div class="skeleton"></div></div>' +
        '<p role="status">Loading requests…</p>';
      return html;
    }

    if (data.error) {
      html += banner(
        'danger',
        'Could not load requests',
        'The prototype cannot reach a server. Production retries the inbox poll and shows this state on failure.',
        btn({ label: 'Retry (simulated)', kind: 'secondary', action: 'retry-inbox' })
      );
      return html;
    }

    if (!data.items || !data.items.length) {
      html +=
        '<section class="card card--quiet">' +
        '<h2 class="card__title">No requests right now</h2>' +
        '<p class="card__body">A request appears here when someone challenges you. Requests expire after 24 hours.</p>' +
        btn({ label: 'Challenge a friend', kind: 'primary', action: 'challenge-friend' }) +
        '</section>';
      return html;
    }

    data.items.forEach(function (item) {
      var profile = F.profiles[item.from];
      html += '<section class="card request-card" aria-label="Request from @' + esc(profile.username) + '">';
      if (item.kind === 'pending') {
        html +=
          '<div class="row row--between">' + chip('Pending', 'positive') + '<span class="meta">Received ' + esc(item.received) + '</span></div>' +
          identity(item.from, 'challenger · opponent', { accent: 'opponent' }) +
          '<p class="card__body">' + esc(item.exercise) + ' · ' + esc(item.mode) + ' · 60 seconds · expires in ' + esc(item.expires) + '</p>' +
          '<div class="request-card__actions">' +
          btn({ label: 'Accept challenge', kind: 'primary', action: 'accept-request' }) +
          btn({ label: 'Decline', kind: 'secondary', action: 'decline-request' }) +
          '</div>' +
          '<p class="note">Accepting creates a live match. Both players must be ready and present before it starts.</p>';
      } else if (item.kind === 'offline') {
        html +=
          '<div class="row row--between">' + chip('Challenger offline', 'warning') + '<span class="meta">Received ' + esc(item.received) + '</span></div>' +
          identity(item.from, 'challenger · opponent', { accent: 'opponent' }) +
          '<p class="card__body">Live challenges need both players at the same time. Sending tells @' + esc(profile.username) + ' you are ready to battle now. It is not a replay, and there is no old score to beat.</p>' +
          '<div class="request-card__actions">' +
          btn({ label: 'Send live challenge', kind: 'primary', action: 'send-live-challenge' }) +
          '</div>' +
          '<p class="note">If they do not respond, the request expires in ' + esc(item.expires) + ' with no match created.</p>';
      } else if (item.kind === 'expired') {
        html +=
          '<div class="row row--between">' + chip('Expired') + '<span class="meta">' + esc(item.received) + '</span></div>' +
          identity(item.from, 'challenger · opponent', { accent: 'opponent' }) +
          '<p class="card__body">Requests expire 24 hours after they are sent. Nothing was created for this one and no rating changed.</p>' +
          btn({ label: 'Challenge @' + esc(profile.username) + ' again', kind: 'quiet', action: 'challenge-again' });
      } else if (item.kind === 'busy') {
        html +=
          '<div class="row row--between">' + chip('In a battle', 'warning') + '<span class="meta">Busy for ' + esc(item.busyFor) + '</span></div>' +
          identity(item.from, 'challenger · opponent', { accent: 'opponent' }) +
          '<p class="card__body">@' + esc(profile.username) + ' is finishing another battle. You can send a request now; accepting unlocks when they finish. A player can never have two accepted battles at once.</p>' +
          '<div class="request-card__actions">' +
          btn({ label: 'Send request', kind: 'primary', action: 'send-live-challenge' }) +
          btn({ label: 'Back to Battle', kind: 'secondary', href: '#/battle' }) +
          '</div>';
      }
      html += '</section>';
    });

    html += '<p class="note">Requests expire after 24 hours. One accepted battle at a time, and only when both players are present.</p>';
    return html;
  }

  function renderChallenge(ctx) {
    var data = ctx.data;
    if (!data.available) {
      return (
        closeHead() +
        banner(
          'warning',
          'This challenge link is unavailable',
          'It was revoked, expired, or the account was deleted. A challenge link identifies a person for a new live battle — it never stores or replays a match.',
          btn({ label: 'Back to Battle', kind: 'primary', href: '#/battle' })
        ) +
        '<p class="meta">Code ' + esc(F.link.code) + ' · preview URL ' + esc(F.link.host) + '</p>'
      );
    }
    return (
      closeHead() +
      '<section class="stack stack--loose">' +
      identity(data.from, 'challenger · opponent', { accent: 'opponent', large: true }) +
      title('@' + data.from + ' challenges you') +
      '<p class="lead">Push-ups or squats. 60 seconds, counted by your camera, with the result confirmed by the server.</p>' +
      '</section>' +
      '<section class="card" aria-labelledby="how-title">' +
      '<h2 class="card__title" id="how-title">How this works</h2>' +
      '<ol class="steps steps--player">' +
      '<li>Accept the challenge. The app keeps this link attached to your request.</li>' +
      '<li>Prepare: see the exercise, watch the demonstration and take one unscored practice rep.</li>' +
      '<li>You both confirm ready, then a 5-second countdown and a 60-second battle.</li>' +
      '</ol>' +
      '<p class="note">Opening this page is read-only. Nothing is created until you accept, and there is no old score to beat.</p>' +
      '</section>' +
      '<section class="card card--flat" aria-labelledby="privacy-title">' +
      '<h2 class="card__title" id="privacy-title">Your camera stays on your phone</h2>' +
      '<p class="card__body">Camera frames are processed on your device and never uploaded. Only rep counts are sent to the match score.</p>' +
      '</section>' +
      btn({ label: 'Accept challenge', kind: 'primary', block: true, size: 'lg', action: 'accept-request' }) +
      '<p class="meta">Expires in 23 h 40 min · code ' + esc(F.link.code) + ' · sign-in is required to accept.</p>' +
      '<div class="offline-strip">' + icon('info') + ' Preview variants: ' +
      '<a href="#/c/' + esc(F.link.token) + '/signin?fixture=landing-signed-out">signed out</a> · ' +
      '<a href="#/c/' + esc(F.link.token) + '/install?fixture=landing-not-installed">not installed</a>' +
      '</div>'
    );
  }

  function renderSignIn(ctx) {
    return (
      screenHead(ctx, { backLabel: 'Back to challenge', kicker: 'Sign in' }) +
      title('Sign in to accept') +
      identity(ctx.data.from, 'challenger · opponent', { accent: 'opponent', large: true }) +
      banner(
        'positive',
        'Your challenge is kept',
        'Sign in and you return to this exact challenge. No friend search, no typing a code.'
      ) +
      '<section class="card" aria-labelledby="signin-steps">' +
      '<h2 class="card__title" id="signin-steps">What happens next</h2>' +
      '<ol class="steps">' +
      '<li>Sign in with Google or email.</li>' +
      '<li>Accept @' + esc(ctx.data.from) + '\'s challenge.</li>' +
      '<li>Prepare and battle for 60 seconds.</li>' +
      '</ol>' +
      '</section>' +
      btn({ label: 'Continue with Google', kind: 'primary', block: true, size: 'lg', action: 'sim-signin' }) +
      btn({ label: 'Continue with email', kind: 'secondary', block: true, action: 'sim-signin' }) +
      '<p class="note">Simulated sign-in: task 05 owns the real Google/email redirect and restoring the pending challenge. No credentials are requested by this prototype.</p>' +
      '<p class="meta">Already signed in? <a href="#/c/' + esc(F.link.token) + '?fixture=landing-default">Open the challenge</a>.</p>'
    );
  }

  function renderInstall(ctx) {
    return (
      screenHead(ctx, { backLabel: 'Back to challenge', kicker: 'Not installed' }) +
      title('Install Training Arena') +
      identity(ctx.data.from, 'challenger · opponent', { accent: 'opponent', large: true }) +
      '<section class="card" aria-labelledby="install-steps">' +
      '<h2 class="card__title" id="install-steps">Three steps, then you battle</h2>' +
      '<ol class="steps steps--player">' +
      '<li>Install Training Arena from Google Play.</li>' +
      '<li>Reopen this challenge link.</li>' +
      '<li>Accept and prepare with @' + esc(ctx.data.from) + '.</li>' +
      '</ol>' +
      '</section>' +
      btn({ label: 'Get Training Arena on Google Play', kind: 'primary', block: true, size: 'lg', action: 'sim-install' }) +
      '<section class="card card--flat" aria-labelledby="code-title">' +
      '<h2 class="card__title" id="code-title">Short code</h2>' +
      '<p class="big-code num">' + esc(F.link.code) + '</p>' +
      '<p class="note">If the link does not reopen after installing, read this code to @' + esc(ctx.data.from) + ' or enter it under Join with code.</p>' +
      '</section>' +
      '<p class="note">Simulated install: production uses Android App Links and the Play Install Referrer (task 05). This prototype cannot install or verify anything.</p>' +
      '<p class="meta">Already installed? <a href="#/c/' + esc(F.link.token) + '?fixture=landing-default">Open the challenge</a>.</p>'
    );
  }

  function renderPrepare(ctx) {
    var practiceDone = !!ctx.ui.practice;
    return (
      '<div class="screen-head">' +
      '<a class="icon-btn" href="#/battle" data-leave="prepare" aria-label="Leave preparation">' + icon('close') + '</a>' +
      '<span class="screen-head__kicker">Preparation · 1 of 3</span>' +
      '</div>' +
      title('Preparation') +
      '<div class="grid-2">' +
      '<section class="card" aria-labelledby="exercise-title">' +
      '<p class="kicker">Exercise revealed</p>' +
      '<h2 class="exercise-reveal" id="exercise-title">' + esc(ctx.data.exercise) + '</h2>' +
      '<p class="note">One exercise, chosen by the server when the match was created. It is revealed here and does not change. There is no manual score entry.</p>' +
      '</section>' +
      '<section class="card" aria-labelledby="demo-title">' +
      '<p class="kicker" id="demo-title">3D demonstration</p>' +
      '<div class="media-frame media-frame--demo">' +
      '<div class="media-frame__viewport">' +
      '<span class="media-frame__tag chip">Placeholder</span>' +
      '<div class="media-frame__placeholder">' + icon('figure') +
      '<p><strong>3D demonstration placeholder.</strong><br>Task 02 delivers the reviewed push-up and squat animation; nothing is faked here.</p>' +
      '</div></div>' +
      '<div class="media-frame__foot">Neutral start pose, correct depth, return path — looped on the phone.</div>' +
      '</div>' +
      '</section>' +
      '</div>' +
      '<section class="card" aria-labelledby="camera-title">' +
      '<p class="kicker" id="camera-title">Camera preview (private)</p>' +
      '<div class="media-frame">' +
      '<div class="media-frame__viewport">' +
      '<span class="media-frame__tag chip">Camera placeholder</span>' +
      '<div class="camera-guides" aria-hidden="true">' +
      '<span class="camera-guides__corner camera-guides__corner--tl"></span>' +
      '<span class="camera-guides__corner camera-guides__corner--tr"></span>' +
      '<span class="camera-guides__corner camera-guides__corner--bl"></span>' +
      '<span class="camera-guides__corner camera-guides__corner--br"></span>' +
      '<span class="camera-guides__body"></span>' +
      '</div>' +
      '<div class="media-frame__placeholder media-frame__placeholder--center">' + icon('camera') +
      '<p><strong>Camera preview placeholder.</strong><br>Task 03 adds on-device pose tracking. No frames are recorded or uploaded here.</p>' +
      '</div>' +
      '</div>' +
      '<div class="media-frame__foot">' + icon('link') + ' Processed on this device · only rep counts leave the phone</div>' +
      '</div>' +
      '</section>' +
      '<section class="card" aria-labelledby="framing-title">' +
      '<h2 class="card__title" id="framing-title">Framing</h2>' +
      '<ul class="check-list">' +
      '<li>' + icon('check') + '<span>Whole body in frame, head to feet.</span></li>' +
      '<li>' + icon('check') + '<span>Phone on the floor or against a wall, three to four steps back.</span></li>' +
      '<li>' + icon('check') + '<span>Clear space around you for the full movement.</span></li>' +
      '</ul>' +
      '</section>' +
      '<section class="card" aria-labelledby="practice-title">' +
      '<h2 class="card__title" id="practice-title">Practice rep</h2>' +
      (practiceDone
        ? '<p>' + chip('Practice rep counted — 1 of 1', 'positive') + '</p>' +
          '<p class="note">Unscored. It never changes the battle score. Real counting is task 03; this button only demonstrates the state.</p>'
        : btn({ label: 'Take 1 practice rep', kind: 'secondary', block: true, action: 'practice-rep' }) +
          '<p class="note">Exactly one practice rep. It is never scored.</p>') +
      '</section>' +
      (practiceDone
        ? btn({ label: 'I\u2019m ready', kind: 'primary', block: true, size: 'lg', action: 'ready-up' })
        : btn({ label: 'I\u2019m ready', kind: 'primary', block: true, size: 'lg', action: 'ready-up', ariaDisabled: true })) +
      '<p class="note">Both players must be present and ready. The countdown cannot start unattended.</p>'
    );
  }

  function renderReady(ctx) {
    var opponentReady = !!ctx.data.opponentReady;
    return (
      '<div class="screen-head">' +
      '<a class="icon-btn" href="#/battle" data-leave="ready" aria-label="Cancel match">' + icon('close') + '</a>' +
      '<span class="screen-head__kicker">Ready check · 2 of 3</span>' +
      '</div>' +
      title('Ready check') +
      '<div class="grid-2">' +
      '<section class="card card--player" aria-labelledby="you-ready">' +
      '<p class="kicker" id="you-ready">You</p>' +
      identity('you', 'player', { large: true }) +
      '<p>' + chip('Ready', 'positive') + '</p>' +
      '</section>' +
      '<section class="card card--opponent" aria-labelledby="opp-ready">' +
      '<p class="kicker" id="opp-ready">Opponent</p>' +
      identity(ctx.data.opponent, 'opponent', { accent: 'opponent', large: true }) +
      '<p>' + (opponentReady ? chip('Ready', 'positive') : chip('Waiting for them')) + '</p>' +
      '</section>' +
      '</div>' +
      (opponentReady
        ? banner('positive', 'Both players ready', 'Simulated preview: the server clock starts the 5-second countdown in a moment.')
        : banner(
            'positive',
            'Nothing starts unattended',
            'The countdown begins only when both players are ready and connected. If one player leaves, the match expires in 10 minutes without a rating change.',
            btn({ label: 'Cancel match', kind: 'danger', action: 'cancel-match' })
          )) +
      (opponentReady
        ? btn({ label: 'Cancel match', kind: 'danger', action: 'cancel-match' })
        : '<p class="note">Waiting for @' + esc(ctx.data.opponent) + '. Simulated opponent response for review.</p>')
    );
  }

  function renderCountdown(ctx) {
    return (
      '<header class="topbar">' +
      chip('Countdown', 'positive') +
      btn({ label: 'Leave', kind: 'danger', leave: 'countdown' }) +
      '</header>' +
      hiddenTitle('Countdown for the ' + ctx.data.exercise + ' battle') +
      '<div class="timer">' +
      '<p class="kicker">Get into position</p>' +
      '<p class="timer__value num" id="countdown-value" role="timer" aria-label="Countdown seconds: 5">5</p>' +
      '<p class="timer__label">' + esc(ctx.data.exercise) + ' · 60 seconds · opponent @' + esc(ctx.data.opponent) + '</p>' +
      '</div>' +
      '<div class="grid-2">' +
      '<section class="card card--player">' + identity('you', 'player') + '<p>' + chip('Ready', 'positive') + '</p></section>' +
      '<section class="card card--opponent">' + identity(ctx.data.opponent, 'opponent', { accent: 'opponent' }) + '<p>' + chip('Ready', 'positive') + '</p></section>' +
      '</div>' +
      '<p class="note">Simulated preview countdown. Production starts on the server clock only when both ready checks are true.</p>'
    );
  }

  function renderLive(ctx) {
    var data = ctx.data;
    var html = '';
    html +=
      '<header class="topbar">' +
      chip('Live · ' + data.exercise, 'positive') +
      btn({ label: 'Leave', kind: 'danger', leave: 'live' }) +
      '</header>';
    html += hiddenTitle('Live battle — ' + data.exercise + ', 60 seconds');
    html +=
      '<div class="timer">' +
      '<p class="timer__value num" id="timer-value" role="timer" aria-label="Time remaining: 60 seconds">60</p>' +
      '<div class="timer__bar" role="progressbar" aria-label="Round progress" aria-valuemin="0" aria-valuemax="60" aria-valuenow="60">' +
      '<span class="timer__fill" id="timer-fill" style="width:100%"></span></div>' +
      '<p class="timer__label" id="timer-label">' + esc(data.exercise) + ' · 60 seconds</p>' +
      '</div>';
    html += '<div id="live-status">' + liveStatusBanner(data) + '</div>';
    html +=
      '<div class="grid-2">' +
      '<section class="score-panel score-panel--player" role="group" aria-label="Your score">' +
      identity('you', 'you · player') +
      '<p class="score-panel__value num" id="score-you" aria-label="Your score: 0 reps">0</p>' +
      '<p class="score-panel__unit">reps</p>' +
      '<p class="score-panel__state" id="state-you">Tracking: stable</p>' +
      '</section>' +
      '<section class="score-panel score-panel--opponent" role="group" aria-label="Opponent score">' +
      identity(data.opponent, 'opponent', { accent: 'opponent' }) +
      '<p class="score-panel__value num" id="score-opp" aria-label="Opponent score: 0 reps">0</p>' +
      '<p class="score-panel__unit">reps</p>' +
      '<p class="score-panel__state" id="state-opp">Live</p>' +
      '</section>' +
      '</div>';
    html +=
      '<p class="note">Scores are confirmed by the server. Camera frames never leave the device. A lost connection gets 10 seconds to recover before a forfeit; a shared service failure gives no result.</p>';
    return html;
  }

  function liveStatusBanner(data) {
    if (data.status === 'tracking-lost') {
      return banner(
        'warning',
        'Camera tracking lost — your counting is paused',
        'The shared clock keeps running. Re-scan when you are back in frame.',
        btn({ label: 'Simulated: re-scan now', kind: 'secondary', action: 'tracking-rescan' })
      );
    }
    if (data.status === 'opponent-reconnecting') {
      return banner(
        'warning',
        'Opponent reconnecting',
        'They have 8 seconds to recover before the match is forfeited. Their panel shows the last confirmed score.',
        btn({ label: 'Simulated: opponent reconnects', kind: 'secondary', action: 'opponent-recover' })
      );
    }
    if (data.status === 'opponent-offline') {
      return banner(
        'danger',
        'Opponent connection lost',
        'If the connection does not recover within 10 seconds, the server confirms a forfeit. Your own counting continues.',
        btn({ label: 'Simulated: confirm forfeit', kind: 'danger', action: 'opponent-forfeit' })
      );
    }
    if (data.status === 'outage') {
      return banner(
        'danger',
        'Battle service unreachable',
        'The score cannot be confirmed. If the outage continues, this battle ends with no result and no rating change.',
        btn({ label: 'Retry connection', kind: 'secondary', action: 'retry-connection' }) +
          btn({ label: 'End with no result', kind: 'danger', action: 'leave-to-result' })
      );
    }
    return banner(
      'positive',
      'Tracking and connection stable',
      'Both players are being counted. Scores appear as the server confirms reps.'
    );
  }

  function renderResult(ctx) {
    var data = ctx.data;
    var you = data.you;
    var opp = data.opp;
    var margin = Math.abs(you - opp);
    var headline;
    var headlineClass = '';
    if (data.result === 'no-result') {
      headline = 'No result';
    } else if (data.result === 'draw') {
      headline = 'Draw — ' + you + ' each';
    } else if (data.result === 'win') {
      headline = 'I beat @' + data.opponent + ' by ' + margin;
      headlineClass = ' result-headline--win';
    } else {
      headline = '@' + data.opponent + ' beat me by ' + margin;
      headlineClass = ' result-headline--loss';
    }
    var ranked = data.mode === 'ranked';
    return (
      '<div class="screen-head">' +
      '<a class="icon-btn" href="#/battle" aria-label="Back to Battle">' + icon('back') + '</a>' +
      '<span class="screen-head__kicker">Confirmed result</span>' +
      '</div>' +
      '<h1 class="result-headline' + headlineClass + '" id="screen-title" tabindex="-1">' + esc(headline) + '</h1>' +
      '<section class="card result-card">' +
      '<div class="result-scores">' +
      '<div class="score-panel score-panel--player">' +
      '<p class="kicker">You</p>' +
      '<p class="score-panel__value num" aria-label="Your score: ' + you + ' reps">' + you + '</p>' +
      '<p class="score-panel__unit">reps</p>' +
      '</div>' +
      '<span class="result-scores__dash" aria-hidden="true">–</span>' +
      '<div class="score-panel score-panel--opponent">' +
      '<p class="kicker">@' + esc(data.opponent) + '</p>' +
      '<p class="score-panel__value num" aria-label="' + esc(data.opponent) + '\'s score: ' + opp + ' reps">' + opp + '</p>' +
      '<p class="score-panel__unit">reps</p>' +
      '</div>' +
      '</div>' +
      '<div class="row">' +
      chip(data.exercise + ' · 60 seconds') +
      (ranked
        ? chip('Ranked · ' + data.ratingBefore + ' → ' + data.ratingAfter, 'positive')
        : chip('Casual · rating unchanged')) +
      '</div>' +
      (data.result === 'no-result'
        ? banner('warning', 'No rating change', esc(data.reason || 'The match ended without a confirmed score.'))
        : '<p class="note">Confirmed by the server. The receipt is immutable: names, scores and rating are a snapshot.</p>') +
      (data.mode === 'ranked'
        ? '<p class="note">Arena rating ' + data.ratingBefore + ' → <strong>' + data.ratingAfter + '</strong> after this ranked result.</p>'
        : '') +
      btn({ label: 'Share challenge', kind: 'primary', block: true, size: 'lg', action: 'share-challenge' }) +
      btn({ label: 'Back to Battle', kind: 'secondary', block: true, href: '#/battle' }) +
      '<p class="note">Sharing starts a new challenge for a new live battle. It never replays this match or compares old scores.</p>' +
      '<details class="result-details">' +
      '<summary>Receipt details</summary>' +
      '<dl>' +
      '<dt>Receipt</dt><dd>rcpt_9f2k4p</dd>' +
      '<dt>Exercise</dt><dd>' + esc(data.exercise) + ' · 60 seconds</dd>' +
      '<dt>Mode</dt><dd>' + esc(data.mode) + '</dd>' +
      '<dt>Confirmed</dt><dd>' + esc(data.finishedAt || 'Today') + '</dd>' +
      '<dt>Source</dt><dd>Server receipt (simulated for this preview)</dd>' +
      '</dl>' +
      '</details>' +
      '<button type="button" class="btn btn--quiet" data-action="report-user">Report @' + esc(data.opponent) + '</button>' +
      '</section>'
    );
  }

  function renderShare(ctx) {
    var data = ctx.data;
    var isResult = data.source === 'result';
    var format = ctx.ui.shareFormat || 'story';
    var sourceState = ctx.query.from ? F.byId[ctx.query.from] : null;
    var sourceResult =
      isResult && sourceState && sourceState.route === 'match/:matchId/result' ? sourceState.data : null;
    var fromFixture = sourceState && sourceResult ? sourceState.id : 'result-win';
    var backHref = isResult ? '#/match/m1/result?fixture=' + fromFixture : '#/battle';
    var res = sourceResult || data;
    var resultCard = isResult && res.result !== 'no-result' ? res : null;
    var headline = resultCard
      ? res.result === 'draw'
        ? 'Draw — ' + res.you + ' each'
        : res.result === 'win'
          ? 'I beat @' + res.opponent + ' by ' + Math.abs(res.you - res.opp)
          : '@' + res.opponent + ' beat me by ' + Math.abs(res.you - res.opp)
      : '@' + F.profiles.you.username + ' challenges you';
    var cardHTML = function (kind) {
      return (
        '<figure class="share-card share-card--' + kind + '" role="group" aria-label="' + (kind === 'story' ? 'Story' : 'Feed') + ' preview card">' +
        '<div class="stack stack--tight">' +
        '<p class="kicker">' + (resultCard ? 'Result · ' : 'New challenge · ') + esc(res.exercise) + '</p>' +
        '<p class="share-card__headline">' + esc(headline) + '</p>' +
        (resultCard
          ? '<div class="share-card__scores"><span class="share-card__score share-card__score--player num">' + res.you + '</span><span aria-hidden="true" class="result-scores__dash">–</span><span class="share-card__score share-card__score--opponent num">' + res.opp + '</span></div>'
          : '<p class="note">60 seconds · push-ups or squats · camera-counted live battle</p>') +
        '</div>' +
        '<div class="share-card__versus">' +
        '<span class="share-card__you">@' + esc(F.profiles.you.username) + '</span>' +
        '<span class="kicker">vs</span>' +
        '<span class="share-card__them">@' + esc(res.opponent) + '</span>' +
        '</div>' +
        '<div class="stack stack--tight">' +
        '<span class="share-card__cta">' + (resultCard ? 'Challenge @' + esc(res.opponent) : 'Accept the challenge') + '</span>' +
        '<div class="row row--between">' +
        '<div><p class="url">' + esc(F.link.url) + '</p><p class="meta">Code ' + esc(F.link.code) + '</p></div>' +
        '<span class="share-card__qr" aria-hidden="true">' + icon('qr') + 'QR placeholder</span>' +
        '</div>' +
        '</div>' +
        '</figure>'
      );
    };
    return (
      '<div class="screen-head">' +
      '<a class="icon-btn" href="' + backHref + '" aria-label="' + (isResult ? 'Back to result' : 'Back to Battle') + '">' + icon('back') + '</a>' +
      '<span class="screen-head__kicker">' + (isResult ? 'Share result and challenge' : 'New challenge') + '</span>' +
      '</div>' +
      title('Share challenge') +
      '<p class="lead">' + (isResult
        ? 'Preview the card before sharing. Sharing sends a new invite — it does not replay this match.'
        : 'Preview the card that opens in the share sheet. The link identifies you for a new live battle.') +
      '</p>' +
      (isResult && !resultCard
        ? banner(
            'warning',
            'No confirmed result to show',
            'This match ended without a confirmed score, so the card is a new challenge. It claims no win, loss or draw.'
          )
        : '') +
      '<div class="row" role="group" aria-label="Export format">' +
      '<button type="button" class="btn btn--secondary" data-action="share-format" data-format="story" aria-pressed="' + (format === 'story') + '">Story 9:16</button>' +
      '<button type="button" class="btn btn--secondary" data-action="share-format" data-format="feed" aria-pressed="' + (format === 'feed') + '">Feed 4:5</button>' +
      '</div>' +
      '<div class="share-preview-scroll">' + cardHTML(format) + '</div>' +
      btn({ label: 'Share challenge', kind: 'primary', block: true, size: 'lg', action: 'sim-share-sheet' }) +
      btn({ label: 'Copy challenge link', kind: 'secondary', block: true, action: 'copy-link' }) +
      btn({ label: 'Start a new challenge', kind: 'quiet', block: true, action: 'start-new-challenge' }) +
      '<section class="card card--flat">' +
      '<h2 class="card__title">Honest preview notes</h2>' +
      '<ul class="check-list">' +
      '<li>' + icon('info') + '<span>The preview URL uses <strong>' + esc(F.link.host) + '</strong> until the owner supplies the real domain (task 05).</span></li>' +
      '<li>' + icon('info') + '<span>Opening a share sheet is not counted as a referral, and no recipient profile exists until they accept.</span></li>' +
      '<li>' + icon('info') + '<span>The QR block is a placeholder; task 09 renders a real code that encodes the same challenge URL.</span></li>' +
      '</ul>' +
      '</section>'
    );
  }

  function renderProfile(ctx) {
    var profile = F.profiles.you;
    return (
      title('Profile') +
      '<section class="card card--player" aria-labelledby="profile-name">' +
      '<p class="kicker" id="profile-name">Signed-in player</p>' +
      identity('you', 'you · player', { large: true }) +
      '<p>' + chip('Arena rating ' + profile.rating, 'player') + '</p>' +
      '<div class="row">' +
      '<span class="chip">Ranked wins ' + profile.rankedWins + '</span>' +
      '<span class="chip">Ranked battles ' + profile.rankedBattles + '</span>' +
      '</div>' +
      '</section>' +
      btn({ label: 'Challenge a friend', kind: 'primary', block: true, size: 'lg', action: 'challenge-friend' }) +
      '<section class="card" aria-labelledby="link-title">' +
      '<h2 class="card__title" id="link-title">Your challenge link</h2>' +
      '<p class="url">' + esc(F.link.url) + '</p>' +
      '<p class="note">Readable code <strong>' + esc(F.link.code) + '</strong> · link rotation and username changes are owned by task 06.</p>' +
      btn({ label: 'Copy link', kind: 'secondary', action: 'copy-link' }) +
      '</section>' +
      '<a class="btn btn--secondary btn--block" href="#/settings">Settings</a>' +
      '<button type="button" class="btn btn--quiet btn--block" data-action="sign-out">Sign out</button>'
    );
  }

  function renderLeaderboard(ctx) {
    var rows = (ctx.data.rows || [])
      .map(function (row) {
        return (
          '<li class="list-row' + (row.you ? ' list-row--you' : '') + '">' +
          '<span class="list-row__rank num">' + row.rank + '</span>' +
          '<span class="identity' + (row.you ? ' identity--player' : '') + '">' +
          '<span class="identity__avatar" aria-hidden="true">' + esc(row.initials) + '</span>' +
          '<span class="identity__text">' +
          '<span class="identity__name">@' + esc(row.username) + '</span>' +
          '<span class="identity__role">' + (row.you ? 'you · ranked #' + row.rank : 'ranked #' + row.rank) + '</span>' +
          '</span></span>' +
          '<span class="grow"></span>' +
          '<span class="list-row__rating" aria-label="Arena rating ' + row.rating + '">' + row.rating + '</span>' +
          '</li>'
        );
      })
      .join('');
    return (
      title('Leaderboard') +
      banner('warning', 'Simulated preview', 'Task 06 reads the real top 100 and your position. These rows are invented for layout review.') +
      '<ol class="list">' + rows + '</ol>' +
      '<p class="note">Only server-confirmed ranked results change rating. Friend challenges are casual.</p>'
    );
  }

  function renderSettings(ctx) {
    return (
      screenHead(ctx, { backLabel: 'Back to Profile', kicker: 'Settings' }) +
      title('Settings') +
      '<section class="card" aria-labelledby="account-title">' +
      '<h2 class="card__title" id="account-title">Account</h2>' +
      '<div class="row row--between">' +
      '<div><p class="card__subtitle">Username</p><p class="meta">@' + esc(F.profiles.you.username) + '</p></div>' +
      btn({ label: 'Change', kind: 'secondary', action: 'change-username' }) +
      '</div>' +
      '<div class="switch-row">' +
      '<span class="grow"><strong>Notifications</strong><br><span class="note">Challenge requests and match updates.</span></span>' +
      '<input class="switch" type="checkbox" checked aria-label="Notifications enabled">' +
      '</div>' +
      '<p class="note">Simulated switches. Task 08 owns notification permission and delivery; inbox requests stay authoritative.</p>' +
      '</section>' +
      '<section class="card" aria-labelledby="privacy-settings">' +
      '<h2 class="card__title" id="privacy-settings">Privacy</h2>' +
      '<p class="card__body">Camera frames are processed on this device and never uploaded. Only rep counts reach the match score. Public profile content is limited to username, rating and an optional avatar.</p>' +
      '</section>' +
      '<section class="card" aria-labelledby="about-title">' +
      '<h2 class="card__title" id="about-title">About</h2>' +
      '<p class="card__body">Training Arena · prototype 0.1.0 · Android API 24+ · push-ups and squats only.</p>' +
      btn({ label: 'Delete account', kind: 'danger', action: 'delete-account' }) +
      '</section>'
    );
  }

  /* ----------------------------------------------------------------- mounts */

  var MOUNTS = {
    'prepare/:matchId': function () {},

    'match/:matchId/ready': function (ctx) {
      if (ctx.data.opponentReady) {
        once(1800, function () {
          go('match/m1/countdown?fixture=countdown');
        });
      } else {
        once(2600, function () {
          announce('Opponent is ready (simulated).');
          go('match/m1/ready?fixture=ready-both');
        });
      }
    },

    'match/:matchId/countdown': function (ctx) {
      var fast = ctx.query.fast !== '0';
      var step = fast ? 700 : 1000;
      var value = 5;
      var valueEl = document.getElementById('countdown-value');
      announce('5');
      every(step, function () {
        value -= 1;
        if (valueEl) {
          valueEl.textContent = String(Math.max(value, 0));
          valueEl.setAttribute('aria-label', 'Countdown seconds: ' + Math.max(value, 0));
        }
        if (value > 0) announce(String(value));
        if (value <= 0) {
          go('match/m1/live?fixture=live-normal');
        }
      });
    },

    'match/:matchId/live': function (ctx) {
      var data = ctx.data;
      var fast = ctx.query.fast !== '0';
      var roundSeconds = fast ? 12 : 60;
      var startedAt = Date.now();
      var finished = false;
      var announcedTen = false;
      var announcedThree = false;
      whileWait();

      var timerEl = document.getElementById('timer-value');
      var fillEl = document.getElementById('timer-fill');
      var youEl = document.getElementById('score-you');
      var oppEl = document.getElementById('score-opp');
      var youState = document.getElementById('state-you');
      var oppState = document.getElementById('state-opp');

      function freezePoint(status) {
        if (status === 'tracking-lost') return data.freezeYouAt || 0;
        return data.freezeOppAt || 0;
      }

      function frozenYou() {
        return !!ctx.ui.live && ctx.ui.live.youFrozen;
      }

      function frozenOpp() {
        return !!ctx.ui.live && ctx.ui.live.oppFrozen;
      }

      function currentT() {
        var elapsed = (Date.now() - startedAt) / 1000;
        return Math.min(60, (elapsed / roundSeconds) * 60);
      }

      function setScore(el, value, label) {
        if (!el) return;
        el.textContent = String(value);
        el.setAttribute('aria-label', label + ': ' + value + ' reps');
      }

      function tick() {
        var t = currentT();
        var base = scoreAt(data.timeline, t);
        var youScore = frozenYou() ? scoreAt(data.timeline, freezePoint('tracking-lost')).you : base.you;
        var oppScore = frozenOpp() ? scoreAt(data.timeline, freezePoint('x')).opp : base.opp;
        if (data.status === 'outage') {
          youScore = scoreAt(data.timeline, data.freezeAllAt || 0).you;
          oppScore = scoreAt(data.timeline, data.freezeAllAt || 0).opp;
        }
        setScore(youEl, youScore, 'Your score');
        setScore(oppEl, oppScore, 'Opponent score');
        var remaining = Math.max(0, Math.ceil(60 - t));
        if (timerEl) {
          timerEl.textContent = String(remaining);
          timerEl.setAttribute('aria-label', 'Time remaining: ' + remaining + ' seconds');
          timerEl.classList.toggle('timer__value--closing', remaining <= 10);
        }
        if (fillEl) fillEl.style.width = Math.round((remaining / 60) * 100) + '%';
        if (remaining <= 10 && !announcedTen) {
          announcedTen = true;
          announce('10 seconds left');
        }
        if (remaining <= 3 && !announcedThree) {
          announcedThree = true;
          announce('3 seconds left');
        }
        if (t >= 60 && !finished) {
          finished = true;
          finishRound();
        }
      }

      function finishRound() {
        if (data.status === 'opponent-offline') {
          announce('Round clock ended without a confirmed result.');
          var offlineStatus = document.getElementById('live-status');
          if (offlineStatus) {
            offlineStatus.innerHTML = banner(
              'danger',
              'Round clock ended, result not confirmed',
              'The opponent never recovered. The server confirms a forfeit in your favour; the prototype waits for your click instead of resolving it for you.',
              btn({ label: 'Simulated: confirm forfeit', kind: 'danger', action: 'opponent-forfeit' })
            );
          }
          return;
        }
        if (data.status === 'outage') {
          announce('Round clock ended with no confirmed score.');
          var outageStatus = document.getElementById('live-status');
          if (outageStatus) {
            outageStatus.innerHTML = banner(
              'danger',
              'Round clock ended with no confirmed score',
              'The service stayed unreachable. Continue to the no-result receipt; no rating changes.',
              btn({ label: 'Continue to no result', kind: 'danger', action: 'leave-to-result' })
            );
          }
          return;
        }
        if (data.status === 'tracking-lost') {
          go('match/m1/result?fixture=result-loss');
          return;
        }
        go('match/m1/result?fixture=result-win');
      }

      function whileWait() {
        ctx.ui.live = {
          youFrozen: data.status === 'tracking-lost' || data.status === 'outage',
          oppFrozen:
            data.status === 'opponent-reconnecting' ||
            data.status === 'opponent-offline' ||
            data.status === 'outage',
          unfreezeYou: function () {
            ctx.ui.live.youFrozen = false;
            if (youState) youState.textContent = 'Tracking: restored';
            var status = document.getElementById('live-status');
            if (status) {
              status.innerHTML = banner('positive', 'Tracking restored', 'Counting resumed. The shared clock kept running.');
            }
            announce('Tracking restored. Counting resumed.');
          },
          unfreezeOpp: function () {
            ctx.ui.live.oppFrozen = false;
            if (oppState) oppState.textContent = 'Live';
            var status = document.getElementById('live-status');
            if (status) {
              status.innerHTML = banner('positive', 'Opponent reconnected', 'They recovered in time and counting resumed for both players.');
            }
            announce('Opponent reconnected.');
          },
        };
        if (youState) youState.textContent = data.status === 'tracking-lost' ? 'Counting paused' : data.status === 'outage' ? 'Last confirmed by server' : 'Tracking: stable';
        if (oppState) oppState.textContent =
          data.status === 'opponent-reconnecting' ? 'Reconnecting…' : data.status === 'opponent-offline' ? 'Connection lost' : data.status === 'outage' ? 'Last confirmed by server' : 'Live';
      }

      if (data.status === 'opponent-reconnecting') {
        once(fast ? 1600 : 8000, function () {
          if (ctx.ui.live) ctx.ui.live.unfreezeOpp();
          if (oppState) oppState.textContent = 'Tracking: stable';
        });
      }

      if (data.status === 'opponent-offline') {
        once(fast ? 2000 : 10000, function () {
          announce('Ten seconds without a heartbeat. The server would confirm a forfeit.');
          if (oppState) oppState.textContent = 'Forfeit pending server confirmation';
        });
      }

      every(fast ? 120 : 500, tick);
      ctx.ui.live.finish = finishRound;
    },
  };

  /* ------------------------------------------------------------------- init */

  if (!location.hash) location.hash = '#/battle';
  window.addEventListener('hashchange', render);
  render();
})();
