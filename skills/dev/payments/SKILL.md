# skill: dev/payments
# triggers: stripe, payments, billing, subscription, webhook, checkout, invoice, pricing

## From: stripe/stripe-best-practices (official Stripe skill)

## Stripe Setup
```typescript
import Stripe from 'stripe'
export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2025-04-30',
  typescript: true,
})
```

## Checkout Session (recommended entry point)
```typescript
const session = await stripe.checkout.sessions.create({
  mode: 'subscription',
  customer_email: user.email,
  client_reference_id: user.id,          // link to your user
  line_items: [{ price: priceId, quantity: 1 }],
  success_url: `${APP_URL}/dashboard?session_id={CHECKOUT_SESSION_ID}`,
  cancel_url:  `${APP_URL}/pricing`,
  subscription_data: {
    metadata: { userId: user.id },
    trial_period_days: 14,
  },
})
res.redirect(303, session.url!)
```

## Webhook Handler — Production Pattern
```typescript
// CRITICAL: use raw body, not parsed JSON
app.post('/webhooks/stripe', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature']!
  let event: Stripe.Event

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET!)
  } catch {
    return res.status(400).send('Webhook Error')
  }

  // Idempotency: skip already-processed events
  const exists = await db.stripeEvents.findUnique({ where: { id: event.id } })
  if (exists) return res.json({ received: true })
  await db.stripeEvents.create({ data: { id: event.id } })

  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutComplete(event.data.object as Stripe.CheckoutSession)
      break
    case 'customer.subscription.updated':
    case 'customer.subscription.deleted':
      await syncSubscription(event.data.object as Stripe.Subscription)
      break
    case 'invoice.payment_failed':
      await handlePaymentFailed(event.data.object as Stripe.Invoice)
      break
  }

  res.json({ received: true })
})
```

## Subscription Sync Pattern
```typescript
async function syncSubscription(sub: Stripe.Subscription) {
  const userId = sub.metadata.userId
  await db.subscriptions.upsert({
    where: { stripeSubscriptionId: sub.id },
    create: {
      stripeSubscriptionId: sub.id,
      userId,
      status: sub.status,
      priceId: sub.items.data[0].price.id,
      currentPeriodEnd: new Date(sub.current_period_end * 1000),
      cancelAtPeriodEnd: sub.cancel_at_period_end,
    },
    update: {
      status: sub.status,
      currentPeriodEnd: new Date(sub.current_period_end * 1000),
      cancelAtPeriodEnd: sub.cancel_at_period_end,
    },
  })
}

// Feature gate check
export async function hasActiveSubscription(userId: string): Promise<boolean> {
  const sub = await db.subscriptions.findFirst({
    where: { userId, status: { in: ['active', 'trialing'] } },
  })
  return !!sub
}
```

## Customer Portal (self-serve billing)
```typescript
const session = await stripe.billingPortal.sessions.create({
  customer: user.stripeCustomerId,
  return_url: `${APP_URL}/dashboard`,
})
res.redirect(303, session.url)
```

## One-time Payment
```typescript
const paymentIntent = await stripe.paymentIntents.create({
  amount: 2900,          // in cents
  currency: 'usd',
  customer: customerId,
  metadata: { orderId },
  automatic_payment_methods: { enabled: true },
})
// return { clientSecret: paymentIntent.client_secret } to frontend
```

## Test Cards
```
Success:      4242 4242 4242 4242
Auth required: 4000 0025 0000 3155
Decline:      4000 0000 0000 9995
```

## Rules
- Always verify webhooks with signing secret — never trust raw events
- Store stripeCustomerId on user; never re-create customers
- Idempotency keys on every create: `{ idempotencyKey: \`order-${orderId}\` }`
- Webhook events can arrive out of order — use `current_period_end` not event order
- Test webhooks locally: `stripe listen --forward-to localhost:3000/webhooks/stripe`
