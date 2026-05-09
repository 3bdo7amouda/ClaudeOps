# skill: analytics/errors
# triggers: sentry, error tracking, error monitoring, crash reporting, exceptions, apm, error boundary

## From: getsentry/sentry-sdk-setup (official Sentry skill)

## Sentry Setup — Node.js / Next.js
```typescript
// sentry.server.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.SENTRY_DSN!,
  environment: process.env.NODE_ENV,
  release: process.env.VERCEL_GIT_COMMIT_SHA,
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,
  profilesSampleRate: 0.1,
  integrations: [
    Sentry.prismaIntegration(),
    Sentry.httpIntegration({ tracing: true }),
  ],
})

// Capture with context
Sentry.captureException(error, {
  user: { id: userId, email: user.email },
  tags: { feature: 'checkout', plan: user.plan },
  extra: { orderId, itemCount },
})
```

## Error Boundary (React)
```tsx
import * as Sentry from '@sentry/react'

export const SentryErrorBoundary = Sentry.withErrorBoundary(
  ({ children }) => <>{children}</>,
  {
    fallback: ({ error, resetError }) => (
      <div role="alert" className="p-8 text-center">
        <h2 className="text-xl font-bold">Something went wrong</h2>
        <p className="text-gray-600 mt-2">{error.message}</p>
        <button onClick={resetError} className="mt-4 btn-primary">Try again</button>
      </div>
    ),
    onError: (error, componentStack) => {
      Sentry.captureException(error, { extra: { componentStack } })
    },
  }
)

// Wrap routes
<SentryErrorBoundary>
  <Router />
</SentryErrorBoundary>
```

## Express Error Handler
```typescript
// Must be last middleware, 4 args
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  Sentry.captureException(err, { user: req.user })

  const status = (err as any).statusCode ?? 500
  if (status >= 500) logger.error({ err, url: req.url }, 'Server error')

  res.status(status).json({
    error: (err as any).code ?? 'INTERNAL_ERROR',
    message: process.env.NODE_ENV === 'production' ? 'An error occurred' : err.message,
  })
})
```

## Custom Error Classes
```typescript
export class AppError extends Error {
  constructor(
    message: string,
    public statusCode = 500,
    public code = 'INTERNAL_ERROR',
    public isOperational = true
  ) {
    super(message)
    this.name = this.constructor.name
    Error.captureStackTrace(this, this.constructor)
  }
}

export class NotFoundError extends AppError {
  constructor(resource = 'Resource') {
    super(`${resource} not found`, 404, 'NOT_FOUND')
  }
}
export class ValidationError extends AppError {
  constructor(message: string, public fields?: Record<string, string>) {
    super(message, 422, 'VALIDATION_ERROR')
  }
}
export class ForbiddenError extends AppError {
  constructor() { super('Access denied', 403, 'FORBIDDEN') }
}
```

## Performance Monitoring
```typescript
// Trace custom operations
const transaction = Sentry.startTransaction({ name: 'process-order', op: 'queue.job' })
Sentry.getCurrentHub().configureScope(scope => scope.setSpan(transaction))

try {
  const span = transaction.startChild({ op: 'db.query', description: 'fetch order' })
  const order = await db.orders.findUnique({ where: { id: orderId } })
  span.finish()
  // ... more spans
} finally {
  transaction.finish()
}
```

## Alert Rules (Sentry)
```
Issue Alerts:
  - New issue → immediate notification
  - Issue regression (resolved then seen again) → immediate
  - High volume: >100 occurrences in 1h → alert

Performance Alerts:
  - p75 response time > 2s for 5min
  - Error rate > 1% for 5min
  - Apdex score < 0.8
```

## Rules
- Set `tracesSampleRate: 0.1` in production — not 1.0 (costs)
- Tag errors with `user.id`, `feature`, `plan` for filtering
- Use `isOperational` flag to distinguish bugs vs expected errors
- Don't capture 4xx errors (user errors) — only capture 5xx
- Source maps: upload in CI, never ship to browser
