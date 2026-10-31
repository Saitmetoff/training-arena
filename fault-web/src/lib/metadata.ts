import type {Metadata} from 'next';

// Approved headline/description. Preview remains noindex/nofollow until launch.
export const SITE_TITLE = 'Fault — Give your next set a reason.';
export const SITE_DESCRIPTION =
  'Fault is being built for solo push-up practice. Enter your own rep count and keep a record on your phone. Android first.';
export const SOCIAL_IMAGE = '/social-preview.png';
const SOCIAL_IMAGE_ALT =
  'Fault development preview: Give your next set a reason. Solo push-ups, your count, your record. Android first.';

export function createSiteMetadata(siteUrl: string): Metadata {
  return {
    metadataBase: new URL(siteUrl),
    title: SITE_TITLE,
    description: SITE_DESCRIPTION,
    alternates: {canonical: '/'},
    robots: {index: false, follow: false},
    icons: {icon: '/icon.svg'},
    openGraph: {
      type: 'website',
      url: '/',
      siteName: 'Fault',
      title: SITE_TITLE,
      description: SITE_DESCRIPTION,
      images: [{url: SOCIAL_IMAGE, width: 1200, height: 630, alt: SOCIAL_IMAGE_ALT}],
    },
    twitter: {
      card: 'summary_large_image',
      title: SITE_TITLE,
      description: SITE_DESCRIPTION,
      images: [SOCIAL_IMAGE],
    },
  };
}
