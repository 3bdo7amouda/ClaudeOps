# skill: dev/backend
# triggers: backend, server, service, microservice, api server, node, python, fastapi, express

## Express (Node.js) — Production Structure
```
src/
├── app.js          # express setup, middleware
├── routes/         # route handlers
├── services/       # business logic
├── models/         # DB models
├── middleware/     # auth, validation, errors
└── utils/
```

```javascript
// app.js
import express from 'express'
import helmet from 'helmet'
import cors from 'cors'
import { errorHandler } from './middleware/errors.js'

const app = express()
app.use(helmet())
app.use(cors({ origin: process.env.ALLOWED_ORIGINS?.split(',') }))
app.use(express.json({ limit: '10kb' }))
app.use('/api/v1', router)
app.use(errorHandler)
export default app
```

## FastAPI (Python) — Structure
```python
from fastapi import FastAPI, Depends, HTTPException
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # startup: connect db, warm cache
    yield
    # shutdown: close connections

app = FastAPI(lifespan=lifespan)

@app.get("/health")
async def health(): return {"status": "ok"}

@app.get("/ready")
async def ready(db=Depends(get_db)):
    await db.execute("SELECT 1")
    return {"status": "ready"}
```

## Error Handler Pattern
```javascript
// middleware/errors.js
export function errorHandler(err, req, res, next) {
  const status = err.statusCode || 500
  const code = err.code || 'INTERNAL_ERROR'
  
  if (status >= 500) logger.error({ err, req: req.id })
  
  res.status(status).json({
    error: code,
    message: err.message || 'An error occurred',
    statusCode: status,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  })
}
```

## Structured Logging
```javascript
import pino from 'pino'
export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: { level: (label) => ({ level: label }) },
  timestamp: pino.stdTimeFunctions.isoTime,
})
// Usage: logger.info({ userId, action }, 'User action')
```

## Rules
- Validate all input at the boundary (Zod, Pydantic)
- Never trust client data
- Return consistent error shapes: `{ error, message, code }`
- Health endpoint at `/health`, ready at `/ready`
- Structured JSON logging (pino, structlog)
- Never log sensitive data (passwords, tokens, PII)
