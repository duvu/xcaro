## ADDED Requirements

### Requirement: Platform runtime SHALL identify every session by game type
The system SHALL identify every new room, matchmaking request, game session, and realtime gameplay envelope with a `game_type`, defaulting to `caro` when a legacy Caro client omits it.

#### Scenario: Legacy Caro room create remains valid
- **WHEN** an existing Caro client creates a room without a `game_type`
- **THEN** the platform SHALL treat the request as `game_type = caro` and preserve current room behavior

#### Scenario: New mini-game session declares its type
- **WHEN** a new mini-game client creates or joins a room
- **THEN** the platform SHALL route the session through the declared `game_type`

### Requirement: Shared runtime SHALL own transport and lifecycle while engines own rules
The platform SHALL keep shared runtime concerns in platform-owned room/session code and delegate game-specific rules to per-game engines.

#### Scenario: Shared transport remains generic
- **WHEN** the runtime handles connect, reconnect, matchmaking, resign, chat, or room cleanup
- **THEN** those responsibilities SHALL remain platform-owned and SHALL NOT require Caro-specific rule code in order to function

#### Scenario: Game-specific engine validates moves
- **WHEN** a player submits a move for a specific `game_type`
- **THEN** the platform SHALL delegate move validation, state transition, and result detection to that game’s engine

### Requirement: Platform SHALL preserve current Caro realtime compatibility during migration
The system SHALL preserve current Caro-compatible WebSocket behavior while introducing game-aware abstractions.

#### Scenario: Caro state serializer remains compatible
- **WHEN** a Caro client receives `game_state` or `game_over`
- **THEN** the payload SHALL remain compatible with the current Caro client expectations until the Caro adapter migration is complete

#### Scenario: Additive game-aware fields do not break old clients
- **WHEN** the platform introduces `game_type` or generic session metadata to realtime messages
- **THEN** those additions SHALL NOT require an existing Caro client to change before it can still play Caro online
