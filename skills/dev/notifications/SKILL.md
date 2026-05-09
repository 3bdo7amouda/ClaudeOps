# skill: dev/notifications
# triggers: push notification, fcm, apns, in-app notification, notification bell, expo push, web push, notification center

## Push Notifications via Expo (React Native)
```typescript
import Expo, { ExpoPushMessage } from 'expo-server-sdk'
const expo = new Expo()

export async function sendPushNotification(
  token: string,
  { title, body, data }: { title: string; body: string; data?: object }
) {
  if (!Expo.isExpoPushToken(token)) throw new Error('Invalid push token')

  const chunks = expo.chunkPushNotifications([{
    to: token,
    title,
    body,
    data: data ?? {},
    sound: 'default',
  }])

  for (const chunk of chunks) {
    const tickets = await expo.sendPushNotificationsAsync(chunk)
    // Check for errors
    for (const ticket of tickets) {
      if (ticket.status === 'error') {
        console.error('Push error:', ticket.message)
        if (ticket.details?.error === 'DeviceNotRegistered') {
          await removeToken(token)  // clean up invalid tokens
        }
      }
    }
  }
}
```

## FCM (Firebase Cloud Messaging) — Android/Web
```typescript
import admin from 'firebase-admin'

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) })

export async function sendFCM(token: string, notification: admin.messaging.Notification, data?: Record<string, string>) {
  await admin.messaging().send({
    token,
    notification,
    data,
    android: { priority: 'high' },
    webpush: { headers: { Urgency: 'high' } },
  })
}
```

## In-App Notification System
```typescript
// Schema
model Notification {
  id        String   @id @default(cuid())
  userId    String
  type      String   // 'comment', 'mention', 'system'
  title     String
  body      String
  data      Json?
  read      Boolean  @default(false)
  readAt    DateTime?
  createdAt DateTime @default(now())

  @@index([userId, read, createdAt])
}

// API
// GET  /notifications?unread=true&limit=20
// POST /notifications/:id/read
// POST /notifications/read-all
```

```typescript
// Notification service
export async function createNotification(userId: string, type: string, payload: object) {
  const notif = await db.notifications.create({
    data: { userId, type, ...payload }
  })

  // Push if user has token
  const tokens = await db.pushTokens.findMany({ where: { userId } })
  await Promise.allSettled(tokens.map(t => sendPushNotification(t.token, payload)))

  // Real-time via SSE/WebSocket
  pubsub.publish(`user:${userId}:notifications`, notif)

  return notif
}
```

## Notification Center Component
```typescript
export function NotificationBell() {
  const { data: notifs } = useQuery({ queryKey: ['notifications'], queryFn: fetchNotifications })
  const unreadCount = notifs?.filter(n => !n.read).length ?? 0

  return (
    <div>
      <button>
        🔔 {unreadCount > 0 && <span>{unreadCount > 99 ? '99+' : unreadCount}</span>}
      </button>
      {/* dropdown list */}
    </div>
  )
}
```

## Notification Types — Schema
```typescript
type NotificationPayload =
  | { type: 'comment'; postId: string; commenterId: string }
  | { type: 'mention'; postId: string; mentionedBy: string }
  | { type: 'system'; message: string }
  | { type: 'payment'; invoiceId: string; status: 'paid' | 'failed' }

// Single factory — always route through here for consistency
export const notify = {
  comment: (userId: string, data: ...) => createNotification(userId, 'comment', data),
  mention: (userId: string, data: ...) => createNotification(userId, 'mention', data),
  payment: (userId: string, data: ...) => createNotification(userId, 'payment', data),
}
```

## Web Push (browser)
```typescript
import webpush from 'web-push'
webpush.setVapidDetails('mailto:ops@app.com', process.env.VAPID_PUBLIC!, process.env.VAPID_PRIVATE!)

export async function sendWebPush(subscription: PushSubscription, payload: object) {
  await webpush.sendNotification(subscription, JSON.stringify(payload))
}
```

## Rules
- Always handle `DeviceNotRegistered` — remove stale tokens
- Batch notifications: max 1/hour non-critical, immediate only for direct actions
- Respect user preferences — store per-type opt-out in DB
- All notifications idempotent — duplicate sends must be safe
- Keep notification content short: title ≤50 chars, body ≤150 chars
