/*
 * Runtime configuration for the public pages and the challenge landing.
 *
 * Deploy this file (or replace it during hosting) with the real values. Only
 * public client values belong here: never a service-role key, dispatcher
 * secret or FCM service account.
 *
 * - apiBase: Supabase project URL. Used for the anonymous read-only
 *   `GET /functions/v1/arena?token=...` resolve and for the external
 *   account-deletion page (email code + delete_account). Leave empty to serve
 *   the pages without any network call.
 * - supabaseAnonKey: the project anon (publishable) key. Public by design; it
 *   grants nothing on its own (RLS + revoked grants, docs/API.md §7).
 * - linkHost: host that serves `/c/<token>`; `example.invalid` until the owner
 *   supplies the real domain.
 * - playStoreUrl: supported Play install/update route.
 * - publicUrl: public site URL for the back link and the in-app links.
 * - legalEntity / legalAddress: the developer/legal entity and postal address
 *   as they must appear in the privacy policy (owner input).
 * - privacyEmail / supportEmail: monitored contact addresses (owner input).
 * - effectiveDate: the date the published policy takes effect (owner input).
 * - childrenPolicy: the owner's minimum-age / children statement.
 * - retention fields: the owner's retention periods; left empty until decided.
 *   The public pages show a draft banner and `scripts/check.mjs --release`
 *   fails while any value still contains `[[`.
 */
window.ARENA_WEB_CONFIG = {
  apiBase: '',
  supabaseAnonKey: '',
  linkHost: 'example.invalid',
  playStoreUrl:
    'https://play.google.com/store/apps/details?id=app.trainingarena.mobile',
  publicUrl: 'https://example.invalid',
  legalEntity: '',
  legalAddress: '',
  privacyEmail: '',
  supportEmail: '',
  supportResponseTime: '',
  effectiveDate: '',
  childrenPolicy: '',
  emailProvider: '',
  retentionMatchHistory: '',
  retentionAnalytics: '',
  retentionModeration: '',
  retentionBackups: '',
};
