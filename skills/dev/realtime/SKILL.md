# skill: dev/realtime
# triggers: realtime, websocket, sse, server-sent events, socket.io, live update, push, pubsub

## When to Use What
```
SSE (Server-Sent Events):
  → One-way server→client (notifications, live feeds, AI streaming)
  → Simpler, HTTP/2 compatible, auto-reconnect built-in
  → Max ~6 concurrent connections per domain (HTTP/1.1)

WebSocket:
  → Bidirectional (chat, collaborative editing, live cursors)
  → Requires connection management, reconnect logic

Long Polling:
  → Legacy fallback only — use SSE instead
```

## SSE — Server
```typescript
// Express SSE endpoint
app.get('/api/events', requireAuth, (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream')
  res.setHeader('Cache-Control', 'no-cache')
  res.setHeader('Connection', 'keep-alive')
  res.flushHeaders()

  const send = (event: string, data: unknown) => {
    res.write(`event: ${event}\n`)
    res.write(`data: ${JSON.stringify(data)}\n\n`)
  }

  // Subscribe to Redis pub/sub for this user
  const sub = redis.duplicate()
  sub.subscribe(`user:${req.user.id}`)
  sub.on('message', (channel, message) => {
    const { event, payload } = JSON.parse(message)
    send(event, payload)
  })

  // Heartbeat to keep connection alive
  const heartbeat = setInterval(() => res.write(': ping\n\n'), 25000)

  req.on('close', () => {
    clearInterval(heartbeat)
    sub.unsubscribe()
    sub.quit()
  })
})

// Publish from anywhere in your app
export async function pushToUser(userId: string, event: string, payload: unknown) {
  await redis.publish(`user:${userId}`, JSON.stringify({ event, payload }))
}
```

## SSE — Client
```typescript
const es = new EventSource('/api/events', { withCredentials: true })

es.addEventListener('notification', (e) => {
  const data = JSON.parse(e.data)
  showNotification(data)
})

es.addEventListener('error', () => {
  // Browser auto-reconnects after error — no manual logic needed
  console.log('SSE reconnecting...')
})

// Cleanup
return () => es.close()
```

## WebSocket (ws + Redis pub/sub)
```typescript
import { WebSocketServer, WebSocket } from 'ws'
import { createServer } from 'http'

const server = createServer(app)
const wss = new WebSocketServer({ server, path: '/ws' })

// Track connections per user
const connections = new Map<string, Set<WebSocket>>()

wss.on('connection', (ws, req) => {
  const userId = req.user.id
  if (!connections.has(userId)) connections.set(userId, new Set())
  connections.get(userId)!.add(ws)

  ws.on('message', async (raw) => {
    const { type, payload } = JSON.parse(raw.toString())
    await handleMessage(userId, type, payload)
  })

  ws.on('close', () => {
    connections.get(userId)?.delete(ws)
  })

  // Ping/pong to detect dead connections
  ws.isAlive = true
  ws.on('pong', () => { ws.isAlive = true })
})

// Heartbeat check every 30s
setInterval(() => {
  wss.clients.forEach((ws: any) => {
    if (!ws.isAlive) return ws.terminate()
    ws.isAlive = false
    ws.ping()
  })
}, 30000)

// Broadcast to user (all their connections)
export function sendToUser(userId: string, event: string, data: unknown) {
  const msg = JSON.stringify({ event, data })
  connections.get(userId)?.forEach(ws => {
    if (ws.readyState === WebSocket.OPEN) ws.send(msg)
  })
}
```

## AI Streaming (SSE)
```typescript
// Stream Claude response
app.post('/api/chat', requireAuth, async (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream')
  res.setHeader('Cache-Control', 'no-cache')
  res.flushHeaders()

  const stream = await anthropic.messages.stream({
    model: 'claude-sonnet-4-6',
    max_tokens: 1024,
    messages: req.body.messages,
  })

  for await (const chunk of stream) {
    if (chunk.type === 'content_block_delta' && chunk.delta.type === 'text_delta') {
      res.write(`data: ${JSON.stringify({ text: chunk.delta.text })}\n\n`)
    }
  }
  res.write('data: [DONE]\n\n')
  res.end()
})
```

## Rules
- Use SSE for notifications and AI streaming — simpler than WebSocket
- Redis pub/sub = scale WebSocket/SSE across multiple server instances
- Always implement heartbeat (ping/pong for WS, `: ping` comment for SSE)
- Set `Connection: keep-alive` + 25s heartbeat to defeat proxy timeouts
