## ADDED Requirements

### Requirement: Auth Endpoint Rate Limiting
The system SHALL limit login and registration requests per IP to prevent brute-force attacks.

#### Scenario: Login rate limit exceeded
- **WHEN** more than 5 login requests arrive from the same IP within 60 seconds
- **THEN** server returns 429 Too Many Requests with a `Retry-After` header indicating when the limit resets

#### Scenario: Register rate limit exceeded
- **WHEN** more than 5 registration requests arrive from the same IP within 60 seconds
- **THEN** server returns 429 with `Retry-After` header

#### Scenario: Normal usage not affected
- **WHEN** fewer than 5 requests per minute are made from an IP
- **THEN** all requests are processed normally with no rate-limit headers

---

### Requirement: Game API Rate Limiting
The system SHALL limit game-related API requests per authenticated user.

#### Scenario: Game API rate limit exceeded
- **WHEN** more than 60 game API requests arrive from the same authenticated user within 60 seconds
- **THEN** server returns 429 Too Many Requests with `Retry-After` header

---

### Requirement: WebSocket Upgrade Rate Limiting
The system SHALL limit WebSocket upgrade attempts per IP to prevent connection exhaustion.

#### Scenario: WS upgrade rate limit exceeded
- **WHEN** more than 10 WebSocket upgrade requests arrive from the same IP within 60 seconds
- **THEN** server returns 429 and does not upgrade the connection

---

### Requirement: Rate Limit Fail-Open
The system SHALL continue serving requests normally if Redis (rate limit store) is unavailable.

#### Scenario: Redis unavailable
- **WHEN** the Redis connection is lost and a rate-limited endpoint is called
- **THEN** server allows the request (fail-open), logs a warning, and does NOT return 429
