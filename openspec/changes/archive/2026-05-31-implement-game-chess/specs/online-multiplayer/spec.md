## ADDED Requirements

### Requirement: Polymorphic make_move payload
The `make_move` WebSocket event payload MUST be extended to support chess moves (`from`, `to`, `promotion`) alongside existing Caro moves (`x`, `y`). The server SHALL route move handling based on `room.GameType`.

#### Scenario: Caro make_move unchanged
- **WHEN** a Caro room receives `make_move` with `{x: 7, y: 7}`
- **THEN** behavior is identical to before this change — `from/to/promotion` fields are ignored

#### Scenario: Chess make_move with from/to
- **WHEN** a chess room receives `make_move` with `{from: "e2", to: "e4"}`
- **THEN** server dispatches to chess engine; `x/y` fields are ignored

#### Scenario: Missing required chess move fields
- **WHEN** a chess room receives `make_move` without `from` or `to`
- **THEN** server returns `error` with code `invalid_payload` to the sender
