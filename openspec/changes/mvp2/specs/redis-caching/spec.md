## ADDED Requirements

### Requirement: Leaderboard Redis Cache
The system SHALL cache leaderboard query results in Redis to reduce MongoDB load.

#### Scenario: Cache hit on leaderboard
- **WHEN** `GET /api/leaderboard` is called and a fresh cache entry exists (TTL ≤ 5 min)
- **THEN** server returns the cached JSON without querying MongoDB; response includes `X-Cache: HIT` header

#### Scenario: Cache miss on leaderboard
- **WHEN** `GET /api/leaderboard` is called and no valid cache entry exists
- **THEN** server queries MongoDB, stores result in Redis with 5-min TTL, returns data with `X-Cache: MISS` header

---

### Requirement: Player Stats Redis Cache
The system SHALL cache individual player stats responses in Redis.

#### Scenario: Stats cache hit
- **WHEN** `GET /api/games/stats?userId=` is called and a fresh cache entry exists (TTL ≤ 2 min)
- **THEN** server returns cached stats

#### Scenario: Stats cache invalidated after game
- **WHEN** a game involving the player ends
- **THEN** server deletes that player's stats cache key so the next fetch is fresh

---

### Requirement: Graceful Degradation
The system SHALL continue to function normally if Redis is unavailable.

#### Scenario: Redis down - cache bypass
- **WHEN** Redis is unavailable
- **THEN** server queries MongoDB directly for all requests, logs an error, does NOT return 500 to clients
