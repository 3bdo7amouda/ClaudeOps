# skill: dev/webhooks
# triggers: webhook, webhooks, incoming webhook, outgoing webhook, signature verification, svix, ngrok, retry

## Receiving Webhooks (Signature Verification)
```typescript
// Generic HMAC-SHA256 webhook handler
import crypto from 'crypto'

export function verifyWebhookSignature(
  payload: Buffer,
  signature: string,
  secret: string
): boolean {
  const expected = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex')
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(`sha256=${expected}`)
  )
}

// Express handler — MUST use raw body, not parsed JSON
app.post('/webhooks/github',
  express.raw({ type: 'application/json' }),
  (req, res) => {
    const sig = req.headers['x-hub-signature-256'] as string
    if (!verifyWebhookSignature(req.body, sig, process.env.GITHUB_WEBHOOK_SECRET!)) {
      return res.status(401).send('Invalid signature')
    }
    const event = JSON.parse(req.body.toString())
    // Process async — respond 200 immediately
    processEvent(event).catch(console.error)
    res.status(200).send('OK')
  }
)
```

## Stripe Webhook (provider-specific)
```typescript
import Stripe from 'stripe'
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!)

app.post('/webhooks/stripe',
  express.raw({ type: 'application/json' }),
  async (req, res) => {
    const sig = req.headers['stripe-signature'] as string
    let event: Stripe.Event
    try {
      event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET!)
    } catch {
      return res.status(400).send('Webhook Error')
    }

    switch (event.type) {
      case 'checkout.session.completed':
        await handleCheckoutComplete(event.data.object as Stripe.CheckoutSession)
        break
      case 'customer.subscription.deleted':
        await handleSubscriptionCanceled(event.data.object as Stripe.Subscription)
        break
    }
    res.json({ received: true })
  }
)
```

## Idempotency (prevent double-processing)
```typescript
// Store processed event IDs to handle retries
async function processWebhookEvent(eventId: string, handler: () => Promise<void>) {
  const exists = await db.webhookEvents.findUnique({ where: { externalId: eventId } })
  if (exists) return  // already processed — skip

  await db.webhookEvents.create({ data: { externalId: eventId, processedAt: new Date() } })
  await handler()
}
```

## Sending Outgoing Webhooks (with retries)
```typescript
interface WebhookDelivery {
  url: string
  secret: string
  payload: object
}

async function deliverWebhook({ url, secret, payload }: WebhookDelivery, attempt = 1): Promise<void> {
  const body = JSON.stringify(payload)
  const sig = crypto.createHmac('sha256', secret).update(body).digest('hex')

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Signature': `sha256=${sig}`,
      'X-Attempt': String(attempt),
    },
    body,
    signal: AbortSignal.timeout(10000),
  })

  if (!res.ok) {
    if (attempt < 5) {
      await new Promise(r => setTimeout(r, Math.min(2 ** attempt * 1000, 60000)))
      return deliverWebhook({ url, secret, payload }, attempt + 1)
    }
    throw new Error(`Webhook delivery failed after ${attempt} attempts: ${res.status}`)
  }
}
```

## Managed Webhook Service (Svix)
```typescript
import { Svix } from 'svix'
const svix = new Svix(process.env.SVIX_API_KEY!)

// Send
await svix.message.create('app_id', {
  eventType: 'user.created',
  payload: { userId: '123', email: 'a@b.com' },
})

// Verify incoming (in your endpoint)
const webhook = new Webhook(process.env.SVIX_SECRET!)
const evt = webhook.verify(rawBody, headers)  // throws on invalid
```

## Local Testing
```bash
# Stripe CLI
stripe listen --forward-to localhost:3000/webhooks/stripe

# ngrok
ngrok http 3000
# → Paste https URL into provider dashboard
```

## Rules
- Always verify signatures — never skip in production
- Respond 200 within 5s — process async via queue
- Store every received event with payload for replay/debug
- Idempotency key on every handler — webhooks always retry
- Log: eventId, type, processingTime, success/fail
