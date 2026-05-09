# skill: dev/testing
# triggers: test, jest, vitest, pytest, unit, integration, e2e, coverage, mock

## Test Structure (Arrange-Act-Assert)
```javascript
describe('UserService', () => {
  it('creates a user with hashed password', async () => {
    // Arrange
    const input = { email: 'test@example.com', password: 'plain' }
    const mockRepo = { create: jest.fn().mockResolvedValue({ id: '1', ...input }) }

    // Act
    const result = await createUser(input, mockRepo)

    // Assert
    expect(mockRepo.create).toHaveBeenCalledWith(
      expect.objectContaining({ email: input.email })
    )
    expect(result.id).toBeDefined()
  })
})
```

## Pytest
```python
import pytest
from unittest.mock import AsyncMock, patch

@pytest.mark.asyncio
async def test_create_user(mock_db):
    mock_db.insert.return_value = {"id": "1", "email": "a@b.com"}
    result = await create_user({"email": "a@b.com"}, db=mock_db)
    assert result["id"] == "1"
    mock_db.insert.assert_called_once()
```

## Coverage Targets
- Unit: 80%+ on business logic
- Integration: all API routes
- E2E: critical user paths only (login, checkout, etc.)

## What to Test
- Business logic: exhaustively
- Edge cases: empty, null, max values
- Error paths: invalid input, service failures
- Do NOT test: framework internals, trivial getters

## Iron Law
```
RED-GREEN-REFACTOR:
1. Write ONE failing test first — watch it fail with the right failure
2. Write MINIMAL code to make it pass
3. Refactor — keep green
4. NO PRODUCTION CODE without a failing test first

If you didn't watch the test fail, you don't know if it tests the right thing.
Violating the letter of this rule is violating the spirit of it.
```

## FORBIDDEN
```
FORBIDDEN: Mocking the database in integration tests.
FORBIDDEN: Marking a test as skipped because it's flaky — fix the race condition.
FORBIDDEN: Claiming tests pass without running them.
FORBIDDEN: 100% happy-path coverage with zero error path tests.
```

## Red Flags — STOP
- "I'll add tests after I know it works" → Write the failing test first.
- "This is too simple to need a test" → Simple things break too.
- "The integration test covers this" → Unit test the logic, integration test the contract.
- "Let me just run it manually to check" → Manual ≠ a test. Write the assertion.

**All of these mean: write the test first, then the code.**

## Verification Before Done
```bash
# NEVER claim tests pass without running this:
npm test -- --coverage 2>&1 | tail -20
# or
pytest --tb=short -q 2>&1 | tail -20

# Check exit code — 0 = pass, nonzero = fail
echo "Exit: $?"
```

## Snapshot Testing
```javascript
// Only for stable UI components — avoid for business logic
it('renders button correctly', () => {
  const { container } = render(<Button label="Click" />)
  expect(container.firstChild).toMatchSnapshot()
})
// Update snapshots intentionally: jest --updateSnapshot
```

## Gotchas

1. **Mocked DB tests ≠ production works.** Integration tests must hit real infrastructure. Use `testcontainers` or a test DB in CI. Mocks lie about schema, constraints, and transaction behavior.

2. **Test the behavior, not the implementation.** Testing private methods or internal call counts breaks on every refactor. Test what the function does to the world: return value, DB state, event emitted.

3. **Flaky tests are production bugs.** A test that fails 1-in-20 runs has a race condition. Fix it — don't retry, don't skip.

4. **Coverage % is a vanity metric.** `expect(result).toBeDefined()` contributes 100% line coverage and zero confidence. Cover the business rule, not the line.

5. **Test data factories over hardcoded fixtures.** `createUser({ role: 'admin' })` is self-documenting. `fixtures/user.json` rots.

## Related Skills
- **workflow/debugging**: When a test reveals unexpected behavior, switch to systematic debugging
- **workflow/verification**: Run the full suite as the final verification step before claiming done
- **dev/database**: Integration tests need real Postgres — see connection pool and migration patterns

## Integration Test Pattern (Supertest)
```javascript
import request from 'supertest'
import app from '../src/app'

describe('POST /api/v1/users', () => {
  it('returns 201 with valid input', async () => {
    const res = await request(app)
      .post('/api/v1/users')
      .send({ email: 'test@example.com', password: 'secure123' })
    expect(res.status).toBe(201)
    expect(res.body.data.id).toBeDefined()
  })
})
```
