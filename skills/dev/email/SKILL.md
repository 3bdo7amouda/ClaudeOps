# skill: dev/email
# triggers: email, transactional email, resend, sendgrid, ses, smtp, deliverability, spf, dkim, dmarc

## From: resend/email-best-practices (official Resend skill)

## Send — Node.js (Resend)
```typescript
import { Resend } from 'resend'
const resend = new Resend(process.env.RESEND_API_KEY!)

// Always check { data, error } — SDK does NOT throw
const { data, error } = await resend.emails.send({
  from: 'Acme <noreply@acme.com>',
  to: [user.email],
  subject: 'Welcome to Acme',
  react: <WelcomeEmail name={user.name} />,    // or html: '...'
}, { idempotencyKey: `welcome-${user.id}` })

if (error) logger.error({ error }, 'Email send failed')
```

## Transactional Email Catalog
```
Auth:
  ✓ Email verification (on signup)
  ✓ Password reset (expires 1h)
  ✓ Magic link login
  ✓ 2FA/OTP code (expires 10min)
  ✓ New device login alert
  ✓ Password changed notification

Billing:
  ✓ Subscription started / receipt
  ✓ Payment failed (with retry date)
  ✓ Subscription cancellation confirmation
  ✓ Trial ending (3 days before)
  ✓ Invoice PDF

Product:
  ✓ Welcome / getting started
  ✓ Feature onboarding nudges
  ✓ Usage limit warnings
```

## React Email Templates
```typescript
// emails/welcome.tsx
import { Html, Head, Body, Container, Text, Button, Hr } from '@react-email/components'

interface WelcomeEmailProps { name: string; loginUrl: string }

export function WelcomeEmail({ name, loginUrl }: WelcomeEmailProps) {
  return (
    <Html>
      <Head />
      <Body style={{ fontFamily: 'sans-serif', background: '#f9fafb' }}>
        <Container style={{ maxWidth: '600px', margin: '0 auto', padding: '24px' }}>
          <Text style={{ fontSize: '24px', fontWeight: 'bold' }}>Welcome, {name}!</Text>
          <Text>You're all set. Click below to get started.</Text>
          <Button href={loginUrl} style={{ background: '#3b82f6', color: '#fff', padding: '12px 24px', borderRadius: '6px' }}>
            Get Started
          </Button>
          <Hr />
          <Text style={{ fontSize: '12px', color: '#6b7280' }}>
            If you didn't sign up, ignore this email.
          </Text>
        </Container>
      </Body>
    </Html>
  )
}
```

## DNS Authentication (required — Gmail/Yahoo reject without)
```
SPF:   v=spf1 include:amazonses.com ~all
DKIM:  TXT record from your provider (Resend/SES dashboard)
DMARC: v=DMARC1; p=none; rua=mailto:dmarc@yourdomain.com
       → after 2 weeks: p=quarantine; pct=25
       → after 1 month: p=reject

Verify: https://www.mail-tester.com (aim for 10/10)
```

## Webhook — Handle Delivery Events
```typescript
app.post('/webhooks/email', express.raw({ type: 'application/json' }), async (req, res) => {
  // Verify signature (Resend uses Svix)
  const wh = new Webhook(process.env.RESEND_WEBHOOK_SECRET!)
  const event = wh.verify(req.body, {
    'svix-id': req.headers['svix-id'] as string,
    'svix-timestamp': req.headers['svix-timestamp'] as string,
    'svix-signature': req.headers['svix-signature'] as string,
  })

  switch (event.type) {
    case 'email.bounced':
      await db.suppressions.create({ data: { email: event.data.to[0], reason: 'hard_bounce' } })
      break
    case 'email.complained':
      await db.suppressions.create({ data: { email: event.data.to[0], reason: 'complaint' } })
      break
  }
  res.sendStatus(200)
})

// Check before every send
async function canSendTo(email: string): Promise<boolean> {
  return !await db.suppressions.findFirst({ where: { email: email.toLowerCase() } })
}
```

## Idempotency Pattern
```typescript
// Deterministic key = safe to retry
const key = `password-reset-${userId}-${resetRequestId}`
await resend.emails.send({ ... }, { idempotencyKey: key })
// Same key on retry → original response, no duplicate
```

## Rules
- Set up SPF + DKIM + DMARC before sending first email
- Always use idempotency keys for transactional emails
- Maintain suppression list — respect bounces and complaints immediately
- Transactional email ≠ opt-in required (legally); marketing email = explicit opt-in required
- OTP/password reset tokens: expire in 10-60 minutes, single-use, hashed in DB
- Send immediately for transactional — use queue for bulk/marketing
