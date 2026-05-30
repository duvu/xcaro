# Mute Chat Spec

## Overview

Allow a player to mute incoming chat messages for the duration of a game session without leaving the room.

## Requirements

### Client — Mute State

- `GameProvider` (or `ChatProvider`) MUST expose a `bool isChatMuted` field, defaulting to `false`.
- A `toggleChatMute()` method MUST toggle the value and call `notifyListeners()`.
- The mute state MUST reset to `false` when a new game session starts (room joined or game started).
- The mute state MUST NOT be persisted to disk.

### Client — GameScreen Integration

- `GameScreen` MUST show a mute icon button in the game app bar or chat panel header:
  - `Icons.volume_up` when unmuted; `Icons.volume_off` when muted.
  - Tapping calls `toggleChatMute()`.
- When `isChatMuted == true`:
  - `ChatBox` MUST render an overlay or banner: "Chat đã tắt tiếng. Nhấn để bật lại." with a tap gesture calling `toggleChatMute()`.
  - Incoming `chat_message` WS events MUST still be received and stored in the message list (so history is intact when unmuted), but the panel MUST NOT auto-scroll or show a new message indicator.
- When `isChatMuted == false`, behavior is unchanged from Phase 1.

### Server

- No server changes. Mute is client-side only; the server continues broadcasting `chat_message` events to all room clients.

## Acceptance Criteria

- Tapping the mute button toggles the icon and state immediately.
- While muted, the chat panel shows the mute overlay; no auto-scroll occurs for new messages.
- Unmuting reveals all messages received during the muted period in correct order.
- Mute state resets when a new game starts.
- No new analyzer issues.
