import type { CSSProperties } from 'react';
import { Body, Button, Container, Head, Heading, Html, Link, Preview, Text } from 'react-email';

export const subject = 'Confirm your Fault email';
export const preview = 'One more step for Fault launch updates';

type ConfirmationProps = {
  confirmationUrl: string;
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

const heading: CSSProperties = {
  margin: '0 0 16px',
  fontSize: '28px',
  lineHeight: '1.15',
  fontWeight: 800,
  color: '#F6F7F2',
};

const text: CSSProperties = {
  margin: '0 0 16px',
  fontSize: '16px',
  lineHeight: '1.5',
  color: '#B6BDB9',
};

const muted: CSSProperties = {
  margin: '0 0 16px',
  fontSize: '14px',
  lineHeight: '1.5',
  color: '#9BA59E',
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

export default function Confirmation({ confirmationUrl, unsubscribeUrl }: ConfirmationProps) {
  return (
    <Html lang="en">
      <Head />
      <Body style={body}>
        <Preview>{preview}</Preview>
        <Container style={container}>
          <Text style={brand}>FAULT</Text>
          <Heading style={heading}>Confirm your email</Heading>
          <Text style={text}>You asked for Fault development and launch updates. Confirm below to join the list.</Text>
          <Button href={confirmationUrl} style={button}>Confirm my email</Button>
          <Text style={text}>This link expires in 24 hours.</Text>
          <Text style={text}>Joining the list does not give you app access.</Text>
          <Text style={muted}>If you didn&rsquo;t request this, ignore this email.</Text>
          <Text style={footer}>
            Stop these emails: <Link href={unsubscribeUrl} style={link}>unsubscribe</Link>
          </Text>
        </Container>
      </Body>
    </Html>
  );
}
