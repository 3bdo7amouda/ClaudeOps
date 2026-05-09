# skill: dev/queues
# triggers: queue, job, background, worker, bullmq, celery, sqs, redis queue, async job, cron job

## BullMQ (Node.js — recommended)
```typescript
import { Queue, Worker, QueueEvents } from 'bullmq'
import { redis } from './redis'

// Define queues
export const emailQueue   = new Queue('email',   { connection: redis })
export const reportQueue  = new Queue('reports',  { connection: redis })
export const webhookQueue = new Queue('webhooks', { connection: redis })

// Enqueue jobs
await emailQueue.add('send-welcome', { userId, email }, {
  attempts: 3,
  backoff: { type: 'exponential', delay: 2000 },
  removeOnComplete: 100,
  removeOnFail: 500,
})

// Schedule recurring job
await reportQueue.add('weekly-digest', {}, {
  repeat: { cron: '0 9 * * 1' },   // every Monday 9am
})
```

## Worker — Production Pattern
```typescript
const emailWorker = new Worker('email', async (job) => {
  const { userId, email } = job.data

  switch (job.name) {
    case 'send-welcome':
      await resend.emails.send({ to: email, subject: 'Welcome!', html: welcomeHtml })
      break
    case 'send-password-reset':
      await resend.emails.send({ to: email, subject: 'Reset your password', html: resetHtml })
      break
  }

  return { sent: true, at: new Date().toISOString() }
}, {
  connection: redis,
  concurrency: 5,
  limiter: { max: 100, duration: 60_000 },  // 100 jobs/min rate limit
})

emailWorker.on('failed', (job, err) => {
  logger.error({ jobId: job?.id, name: job?.name, err }, 'Job failed')
  // alert if attempts exhausted
  if (job?.attemptsMade >= (job?.opts.attempts ?? 3)) {
    alerts.send(`Job ${job?.name} exhausted retries`)
  }
})
```

## Job Patterns
```typescript
// Debounce — deduplicate rapid events
await queue.add('sync-user', { userId }, {
  jobId: `sync-user:${userId}`,   // same ID = replaces existing
  delay: 5000,
})

// Priority queue
await queue.add('process-payment', data, { priority: 1 })   // 1 = highest
await queue.add('send-newsletter', data, { priority: 10 })

// Batch processing
const jobs = users.map(u => ({ name: 'email', data: { userId: u.id } }))
await emailQueue.addBulk(jobs)
```

## Celery (Python)
```python
from celery import Celery
app = Celery('tasks', broker='redis://localhost:6379/0', backend='redis://localhost:6379/1')
app.conf.update(
    task_serializer='json',
    result_expires=3600,
    task_acks_late=True,           # re-queue on worker crash
    worker_prefetch_multiplier=1,  # fair dispatch
)

@app.task(bind=True, max_retries=3, default_retry_delay=60)
def send_email(self, user_id: str, template: str):
    try:
        user = User.objects.get(id=user_id)
        send_transactional_email(user.email, template)
    except Exception as exc:
        raise self.retry(exc=exc, countdown=2 ** self.request.retries)

# Schedule periodic tasks
from celery.schedules import crontab
app.conf.beat_schedule = {
    'weekly-digest': {
        'task': 'tasks.send_weekly_digest',
        'schedule': crontab(hour=9, minute=0, day_of_week=1),
    },
}
```

## AWS SQS Pattern
```typescript
import { SQSClient, SendMessageCommand, ReceiveMessageCommand, DeleteMessageCommand } from '@aws-sdk/client-sqs'
const sqs = new SQSClient({ region: 'us-east-1' })
const QUEUE_URL = process.env.SQS_QUEUE_URL!

// Send
await sqs.send(new SendMessageCommand({
  QueueUrl: QUEUE_URL,
  MessageBody: JSON.stringify({ type: 'email', payload: { userId } }),
  MessageGroupId: userId,       // FIFO queue ordering
  MessageDeduplicationId: `email-${userId}-${Date.now()}`,
}))

// Poll
const { Messages } = await sqs.send(new ReceiveMessageCommand({
  QueueUrl: QUEUE_URL, MaxNumberOfMessages: 10, WaitTimeSeconds: 20,
}))
for (const msg of Messages ?? []) {
  await processJob(JSON.parse(msg.Body!))
  await sqs.send(new DeleteMessageCommand({ QueueUrl: QUEUE_URL, ReceiptHandle: msg.ReceiptHandle! }))
}
```

## Queue Monitoring Dashboard
```bash
# BullMQ Board (web UI)
npm install @bull-board/express @bull-board/api
# Add route: app.use('/admin/queues', bullBoardRouter)

# CLI check
redis-cli LLEN bull:email:wait
redis-cli LLEN bull:email:active
redis-cli LLEN bull:email:failed
```

## Rules
- Always set `attempts` + `backoff` — never fire-and-forget
- Use `jobId` for deduplication on idempotent operations
- Separate queues by priority domain (email, webhooks, reports)
- Monitor queue depth — alert if `waiting > 1000` for >5min
- Dead-letter pattern: move failed jobs to DLQ after max attempts
