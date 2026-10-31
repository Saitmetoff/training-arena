// Analytics event contract. Data only: no SDK, no transport, no browser key.

export const EVENT_NAMES = [
  'landing_view',
  'demo_play',
  'waitlist_submit',
  'waitlist_confirmed',
  'share_click',
] as const;

export type EventName = (typeof EVENT_NAMES)[number];
export type EventOwner = 'browser' | 'server';

export type EventDefinition = {
  name: EventName;
  owner: EventOwner;
  transition: string;
  properties: readonly string[];
};

export const EVENT_DEFINITIONS: readonly EventDefinition[] = [
  {
    name: 'landing_view',
    owner: 'browser',
    transition: 'anonymous->landing_viewed',
    properties: ['visitorId', 'content_id', 'creative_id', 'utm_source', 'utm_medium', 'utm_campaign', 'utm_content'],
  },
  {
    name: 'demo_play',
    owner: 'browser',
    transition: 'media_ready->playback_started',
    properties: ['visitorId', 'content_id', 'creative_id'],
  },
  {
    name: 'waitlist_submit',
    owner: 'server',
    transition: 'absent->pending (unique canonical address creation only)',
    properties: ['attribution', 'content_id', 'creative_id', 'internal_test', 'site', 'environment'],
  },
  {
    name: 'waitlist_confirmed',
    owner: 'server',
    transition: 'pending->subscribed (one event per consumed confirmation token; first_confirmation distinguishes rejoin)',
    properties: ['attribution', 'content_id', 'creative_id', 'internal_test', 'first_confirmation', 'site', 'environment'],
  },
  {
    name: 'share_click',
    owner: 'browser',
    transition: 'share_available->share_clicked',
    properties: ['visitorId', 'content_id', 'creative_id'],
  },
];

export const CONFIRMATION_FUNNEL = ['landing_view', 'waitlist_submit', 'waitlist_confirmed'] as const;
export const CONVERSION_WINDOW_DAYS = 30;
