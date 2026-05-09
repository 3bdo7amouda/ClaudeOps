# skill: dev/api
# triggers: api, rest, endpoint, route, openapi, swagger, http, request, response

## REST Conventions
```
GET    /resources          → list (200 + pagination)
GET    /resources/:id      → get one (200 or 404)
POST   /resources          → create (201 + Location header)
PUT    /resources/:id      → replace (200 or 404)
PATCH  /resources/:id      → update (200 or 404)
DELETE /resources/:id      → delete (204 or 404)
```

## Response Shapes
```json
// Success list
{ "data": [], "meta": { "page": 1, "limit": 20, "total": 100, "cursor": "xyz" } }

// Success single
{ "data": { "id": "...", "email": "..." } }

// Error
{ "error": "NOT_FOUND", "message": "Resource not found", "statusCode": 404 }

// Validation error
{ "error": "VALIDATION_ERROR", "message": "Invalid input", "statusCode": 422,
  "fields": [{ "field": "email", "message": "Invalid email format" }] }
```

## OpenAPI Schema Pattern
```yaml
openapi: 3.1.0
paths:
  /users/{id}:
    get:
      parameters:
        - name: id
          in: path
          required: true
          schema: { type: string, format: uuid }
      responses:
        '200':
          content:
            application/json:
              schema: { $ref: '#/components/schemas/User' }
        '404':
          $ref: '#/components/responses/NotFound'
```

## Auth Headers
```
Authorization: Bearer <jwt>
X-API-Key: <key>          # for service-to-service
```

## Rate Limiting (Express)
```javascript
import rateLimit from 'express-rate-limit'
app.use('/api/', rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }))
```

## Cursor Pagination
```sql
-- Cursor-based (performant at scale)
SELECT * FROM items
WHERE id > $cursor
ORDER BY id ASC
LIMIT $limit + 1  -- fetch one extra to detect hasMore
```

```javascript
const items = await db.query({ cursor, limit: limit + 1 })
const hasMore = items.length > limit
return {
  data: items.slice(0, limit),
  meta: { hasMore, cursor: hasMore ? items[limit - 1].id : null }
}
```

## API Versioning
```
/api/v1/users   — stable
/api/v2/users   — new version (breaking changes)
/api/v1/users   — deprecation header: Sunset: Sat, 1 Jan 2026 00:00:00 GMT
```
