import type { CSSProperties } from 'react';
import { Body, Button, Container, Head, Html, Link, Preview, Text } from 'react-email';

export const subject = 'A Fault development update';
export const preview = 'Solo push-up practice, in development';

type CampaignDraftProps = {
  siteUrl: string;
  unsubscribeUrl: string;
};

const body: CSSProperties = {
  backgroundColor: '#17191A',
  color: '#F6F7F2',
  fontFamily: 'Helvetica, Arial, sans-serif',
  margin: 0,
  padding: '24px 0',
};

const container: CSSProperties = {
  backgroundColor: '#17191A',
  maxWidth: '560px',
  margin: '0 auto',
  padding: '32px 24px',
};

const brand: CSSProperties = {
  margin: '0 0 24px',
  fontSize: '18px',
  fontWeight: 900,
  letterSpacing: '0.08em',
  color: '#F6F7F2',
};

const text: CSSProperties = {
  margin: '0 0 16px',
  fontSize: '16px',
  lineHeight: '1.5',
  color: '#B6BDB9',
};

const button: CSSProperties = {
  backgroundColor: '#D6FF3F',
  color: '#17191A',
  borderRadius: '14px',
  fontSize: '16px',
  fontWeight: 700,
  textDecoration: 'none',
  padding: '14px 24px',
  display: 'inline-block',
  margin: '8px 0 24px',
};

const footer: CSSProperties = {
  margin: '24px 0 0',
  fontSize: '14px',
  lineHeight: '1.5',
  color: '#9BA59E',
};

const link: CSSProperties = {
  color: '#D6FF3F',
  textDecoration: 'underline',
};

export default function CampaignDraft({ siteUrl, unsubscribeUrl }: CampaignDraftProps) {
  return (
    <Html lang="en">
      <Head />
      <Body style={body}>
        <Preview>{preview}</Preview>
        <Container style={container}>
          <Text style={brand}>FAULT</Text>
          <Text style={text}>Fault is being built for solo push-up practice: enter your own rep count, save the set on your phone, and compare it with your previous sets. Android first.</Text>
          <Text style={text}>We&rsquo;ll share launch details when access is ready.</Text>
          <Button href={siteUrl} style={button}>Visit Fault</Button>
          <Text style={footer}>
            <Link href={unsubscribeUrl} style={link}>Unsubscribe</Link>
          </Text>
        </Container>
      </Body>
    </Html>
  );
}
