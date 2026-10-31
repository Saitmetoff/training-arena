/*
 * Training Arena prototype — deterministic fixture data.
 *
 * Every value here is invented for design review. Nothing in this file comes
 * from a backend, camera or real person. The fixture switch in the prototype
 * UI writes ?fixture=<id> into the hash so a reviewer can jump straight to a
 * state (see prototype/README.md and design/arena/SCREEN_MAP.md).
 */

window.ARENA_FIXTURES = (function () {
  'use strict';

  var LINK_HOST = 'example.invalid';

  var profiles = {
    you: {
      id: 'u-you',
      username: 'azizbek',
      initials: 'AZ',
      rating: 1042,
      rankedWins: 7,
      rankedBattles: 11,
    },
    zuhra: {
      id: 'u-zuhra',
      username: 'zuhra',
      initials: 'ZU',
      rating: 1060,
      rankedWins: 9,
      rankedBattles: 14,
    },
    noor: {
      id: 'u-noor',
      username: 'noor',
      initials: 'NO',
      rating: 1017,
      rankedWins: 4,
      rankedBattles: 9,
    },
    bek: {
      id: 'u-bek',
      username: 'bek',
      initials: 'BE',
      rating: 988,
      rankedWins: 3,
      rankedBattles: 10,
    },
  };

  var link = {
    token: '9f2k4p7q',
    code: '9F2K4P',
    host: LINK_HOST,
    url: 'https://' + LINK_HOST + '/c/9f2k4p7q',
  };

  /* 60-second keyframes used by the live screen; interpolated by the prototype. */
  var timeline = {
    win: [
      { t: 0, you: 0, opp: 0 },
      { t: 5, you: 2, opp: 2 },
      { t: 10, you: 5, opp: 4 },
      { t: 15, you: 8, opp: 7 },
      { t: 20, you: 10, opp: 9 },
      { t: 25, you: 13, opp: 11 },
      { t: 30, you: 15, opp: 14 },
      { t: 35, you: 18, opp: 16 },
      { t: 40, you: 20, opp: 18 },
      { t: 45, you: 22, opp: 20 },
      { t: 50, you: 24, opp: 21 },
      { t: 55, you: 25, opp: 22 },
      { t: 60, you: 26, opp: 23 },
    ],
    loss: [
      { t: 0, you: 0, opp: 0 },
      { t: 5, you: 1, opp: 3 },
      { t: 10, you: 3, opp: 5 },
      { t: 15, you: 4, opp: 8 },
      { t: 20, you: 6, opp: 10 },
      { t: 25, you: 7, opp: 12 },
      { t: 30, you: 9, opp: 14 },
      { t: 35, you: 10, opp: 16 },
      { t: 40, you: 12, opp: 18 },
      { t: 45, you: 13, opp: 20 },
      { t: 50, you: 15, opp: 22 },
      { t: 55, you: 17, opp: 23 },
      { t: 60, you: 19, opp: 24 },
    ],
  };

  var states = [
    /* ---------------------------------------------------------- battle home */
    {
      id: 'battle-incoming',
      route: 'battle',
      label: 'Incoming request',
      data: {
        incoming: { from: 'zuhra', exercise: 'Push-ups', mode: 'Casual', expires: '23 h 40 min' },
      },
    },
    {
      id: 'battle-clear',
      route: 'battle',
      label: 'No incoming request',
      data: { incoming: null },
    },
    {
      id: 'battle-searching',
      route: 'battle',
      label: 'Ranked search running',
      data: { incoming: null, search: { elapsed: 18, limit: 60 } },
    },
    {
      id: 'battle-search-timeout',
      route: 'battle',
      label: 'Ranked search stopped, nobody found',
      data: { incoming: null, searchStopped: true },
    },

    /* --------------------------------------------------------------- inbox */
    {
      id: 'inbox-pending',
      route: 'inbox',
      label: 'Pending request',
      data: {
        items: [
          {
            id: 'r-1',
            kind: 'pending',
            from: 'zuhra',
            exercise: 'Push-ups',
            mode: 'Casual',
            expires: '23 h 40 min',
            received: '2 min ago',
          },
        ],
      },
    },
    {
      id: 'inbox-offline',
      route: 'inbox',
      label: 'Challenger offline',
      data: {
        items: [
          {
            id: 'r-2',
            kind: 'offline',
            from: 'bek',
            exercise: 'Squats',
            mode: 'Casual',
            expires: '21 h 05 min',
            received: '45 min ago',
          },
        ],
      },
    },
    {
      id: 'inbox-expired',
      route: 'inbox',
      label: 'Expired request',
      data: {
        items: [
          {
            id: 'r-3',
            kind: 'expired',
            from: 'noor',
            exercise: 'Push-ups',
            mode: 'Casual',
            expires: 'Expired 2 h ago',
            received: 'Yesterday',
          },
        ],
      },
    },
    {
      id: 'inbox-busy',
      route: 'inbox',
      label: 'Busy player',
      data: {
        items: [
          {
            id: 'r-4',
            kind: 'busy',
            from: 'noor',
            exercise: 'Squats',
            mode: 'Casual',
            expires: '23 h 12 min',
            received: '3 min ago',
            busyFor: 'about 90 seconds',
          },
        ],
      },
    },
    {
      id: 'inbox-empty',
      route: 'inbox',
      label: 'No requests',
      data: { items: [] },
    },
    {
      id: 'inbox-loading',
      route: 'inbox',
      label: 'Loading requests',
      data: { loading: true },
    },
    {
      id: 'inbox-error',
      route: 'inbox',
      label: 'Requests failed to load',
      data: { error: true },
    },

    /* ------------------------------------------------------ challenge link */
    {
      id: 'landing-default',
      route: 'c/:token',
      label: 'Installed and signed in',
      data: { viewer: 'signed-in', available: true, from: 'zuhra' },
    },
    {
      id: 'landing-signed-out',
      route: 'c/:token/signin',
      label: 'Installed, signed out',
      data: { viewer: 'signed-out', available: true, from: 'zuhra' },
    },
    {
      id: 'landing-not-installed',
      route: 'c/:token/install',
      label: 'App not installed',
      data: { viewer: 'not-installed', available: true, from: 'zuhra' },
    },
    {
      id: 'landing-unavailable',
      route: 'c/:token',
      label: 'Link revoked or unavailable',
      data: { viewer: 'signed-in', available: false, from: 'zuhra' },
    },

    /* -------------------------------------------------------- preparation */
    {
      id: 'prep-revealed',
      route: 'prepare/:matchId',
      label: 'Push-ups revealed',
      data: { exercise: 'Push-ups', opponent: 'zuhra' },
    },
    {
      id: 'prep-squats',
      route: 'prepare/:matchId',
      label: 'Squats revealed',
      data: { exercise: 'Squats', opponent: 'zuhra' },
    },

    /* --------------------------------------------------------- ready gate */
    {
      id: 'ready-waiting',
      route: 'match/:matchId/ready',
      label: 'Waiting for opponent',
      data: { opponent: 'zuhra', opponentReady: false },
    },
    {
      id: 'ready-both',
      route: 'match/:matchId/ready',
      label: 'Both ready',
      data: { opponent: 'zuhra', opponentReady: true },
    },

    /* ----------------------------------------------------------- countdown */
    {
      id: 'countdown',
      route: 'match/:matchId/countdown',
      label: 'Countdown',
      data: { opponent: 'zuhra', exercise: 'Push-ups' },
    },

    /* ---------------------------------------------------------------- live */
    {
      id: 'live-normal',
      route: 'match/:matchId/live',
      label: 'Live, tracking stable',
      data: { opponent: 'zuhra', exercise: 'Push-ups', status: 'ok', timeline: timeline.win },
    },
    {
      id: 'live-tracking-lost',
      route: 'match/:matchId/live',
      label: 'Your camera tracking lost',
      data: {
        opponent: 'zuhra',
        exercise: 'Push-ups',
        status: 'tracking-lost',
        timeline: timeline.loss,
        freezeYouAt: 15,
      },
    },
    {
      id: 'live-opponent-reconnecting',
      route: 'match/:matchId/live',
      label: 'Opponent reconnecting',
      data: {
        opponent: 'zuhra',
        exercise: 'Push-ups',
        status: 'opponent-reconnecting',
        timeline: timeline.win,
        freezeOppAt: 20,
        recoverIn: 8,
      },
    },
    {
      id: 'live-opponent-offline',
      route: 'match/:matchId/live',
      label: 'Opponent connection lost',
      data: {
        opponent: 'zuhra',
        exercise: 'Push-ups',
        status: 'opponent-offline',
        timeline: timeline.win,
        freezeOppAt: 20,
        forfeitIn: 10,
      },
    },
    {
      id: 'live-outage',
      route: 'match/:matchId/live',
      label: 'Battle service outage',
      data: {
        opponent: 'zuhra',
        exercise: 'Push-ups',
        status: 'outage',
        timeline: timeline.win,
        freezeAllAt: 12,
      },
    },

    /* -------------------------------------------------------------- result */
    {
      id: 'result-win',
      route: 'match/:matchId/result',
      label: 'Win, casual',
      data: {
        result: 'win',
        exercise: 'Push-ups',
        you: 26,
        opp: 23,
        mode: 'casual',
        opponent: 'zuhra',
        finishedAt: 'Today, 14:32',
      },
    },
    {
      id: 'result-loss',
      route: 'match/:matchId/result',
      label: 'Loss, casual',
      data: {
        result: 'loss',
        exercise: 'Push-ups',
        you: 19,
        opp: 24,
        mode: 'casual',
        opponent: 'zuhra',
        finishedAt: 'Today, 14:32',
      },
    },
    {
      id: 'result-draw',
      route: 'match/:matchId/result',
      label: 'Draw, casual',
      data: {
        result: 'draw',
        exercise: 'Squats',
        you: 24,
        opp: 24,
        mode: 'casual',
        opponent: 'zuhra',
        finishedAt: 'Today, 14:41',
      },
    },
    {
      id: 'result-no-result',
      route: 'match/:matchId/result',
      label: 'No result, service outage',
      data: {
        result: 'no-result',
        exercise: 'Push-ups',
        you: 14,
        opp: 12,
        mode: 'casual',
        opponent: 'zuhra',
        finishedAt: 'Today, 14:37',
        reason: 'The battle service stopped responding before a confirmed score.',
      },
    },
    {
      id: 'result-ranked-win',
      route: 'match/:matchId/result',
      label: 'Win, ranked (rating changed)',
      data: {
        result: 'win',
        exercise: 'Push-ups',
        you: 31,
        opp: 28,
        mode: 'ranked',
        opponent: 'zuhra',
        ratingBefore: 1042,
        ratingAfter: 1058,
        finishedAt: 'Today, 15:02',
      },
    },

    /* --------------------------------------------------------------- share */
    {
      id: 'share-new',
      route: 'share/:source',
      label: 'New challenge invite',
      data: { source: 'new', opponent: 'zuhra', exercise: 'Push-ups', mode: 'Casual' },
    },
    {
      id: 'share-result',
      route: 'share/:source',
      label: 'Share after a result',
      data: {
        source: 'result',
        opponent: 'zuhra',
        exercise: 'Push-ups',
        mode: 'Casual',
        result: 'win',
        you: 26,
        opp: 23,
      },
    },

    /* ------------------------------------------------------------- account */
    {
      id: 'profile',
      route: 'profile',
      label: 'Profile',
      data: {},
    },
    {
      id: 'leaderboard',
      route: 'leaderboard',
      label: 'Leaderboard',
      data: {
        rows: [
          { rank: 1, username: 'dilnoza', initials: 'DI', rating: 1187 },
          { rank: 2, username: 'sardor', initials: 'SA', rating: 1154 },
          { rank: 3, username: 'zuhra', initials: 'ZU', rating: 1060 },
          { rank: 4, username: 'kamila', initials: 'KA', rating: 1049 },
          { rank: 5, username: 'azizbek', initials: 'AZ', rating: 1042, you: true },
        ],
      },
    },
    {
      id: 'settings',
      route: 'settings',
      label: 'Settings',
      data: {},
    },
  ];

  var byId = {};
  states.forEach(function (state) {
    byId[state.id] = state;
  });

  function defaultFor(route) {
    for (var i = 0; i < states.length; i += 1) {
      if (states[i].route === route) return states[i];
    }
    return states[0];
  }

  function find(route, id) {
    var state = id ? byId[id] : null;
    if (state && state.route === route) return state;
    return defaultFor(route);
  }

  return {
    link: link,
    profiles: profiles,
    states: states,
    byId: byId,
    defaultFor: defaultFor,
    find: find,
  };
})();
