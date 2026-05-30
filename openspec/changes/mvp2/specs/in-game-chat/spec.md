## ADDED Requirements

### Requirement: Send Chat Message
The system SHALL allow a player in an active online game to send a text message to their opponent over the existing WebSocket connection.

#### Scenario: Send valid message
- **WHEN** a player sends a WS message `{ "type": "chat_message", "payload": { "content": "<text>" } }`
- **THEN** server validates content is non-empty and ≤ 500 characters, then broadcasts `{ "type": "chat_message", "payload": { "sender_id": "<userID>", "content": "<text>", "timestamp": "<ISO8601>" } }` to all clients in the room

#### Scenario: Message too long
- **WHEN** a player sends a chat message with content exceeding 500 characters
- **THEN** server returns a WS `error` message to the sender; message is not broadcast

#### Scenario: Empty message
- **WHEN** a player sends a chat message with empty or whitespace-only content
- **THEN** server returns a WS `error` message; message is not broadcast

#### Scenario: Chat outside active game
- **WHEN** a player sends a chat message when no game is active in their room
- **THEN** server returns a WS `error` message

---

### Requirement: Display Chat Messages
The client SHALL display incoming chat messages in an overlay panel on the game screen.

#### Scenario: New message received
- **WHEN** a `chat_message` WS event is received
- **THEN** the message appears in the chat panel with sender name and timestamp; panel scrolls to the latest message

#### Scenario: Chat panel toggle
- **WHEN** user taps the chat icon button on the game screen
- **THEN** chat panel slides in/out without interrupting the game board
