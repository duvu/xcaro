# Spec: Operational Metrics

## Purpose

Expose a lightweight real-time snapshot of server health indicators so operators can assess service state without querying MongoDB.

## Data Model

```go
// internal/metrics/metrics.go
type Metrics struct {
    ActiveRooms      int64
    ConnectedClients int64
    CompletedGames   int64
    FailedLogins     int64
}
```

All fields are updated with `sync/atomic` operations.

## REST API

### Get Metrics

`GET /api/metrics`

Auth: required (admin role).

Response `200`:
```json
{
  "active_rooms": 4,
  "connected_clients": 12,
  "completed_games": 309,
  "failed_logins": 7,
  "timestamp": "2026-05-30T10:00:00Z"
}
```

Response `403`: non-admin request.

## Server Requirements

- **MET-S-1**: Create `internal/metrics/` package with a package-level `var Global Metrics`. Methods: `IncrActiveRooms()`, `DecrActiveRooms()`, `IncrConnectedClients()`, `DecrConnectedClients()`, `IncrCompletedGames()`, `IncrFailedLogins()`. Use `atomic.AddInt64`.
- **MET-S-2**: `Hub.Register` calls `metrics.Global.IncrConnectedClients()`. `Hub.Run` `unregister` case calls `metrics.Global.DecrConnectedClients()`.
- **MET-S-3**: `HandleCreateRoom` calls `metrics.Global.IncrActiveRooms()`. Room cleanup (win/resign/disconnect/expiry) calls `metrics.Global.DecrActiveRooms()`.
- **MET-S-4**: `saveGameRecord` (called on game end in `room.go`) calls `metrics.Global.IncrCompletedGames()`.
- **MET-S-5**: Auth `Login` handler calls `metrics.Global.IncrFailedLogins()` on 401 response.
- **MET-S-6**: Register `GET /api/metrics` in `main.go` under the `admin` middleware group (existing `auth.RequireRole(models.RoleAdmin)`).
- **MET-S-7**: Handler returns JSON snapshot with current atomic values and an RFC3339 `timestamp`.

## Client Requirements

- **MET-C-1**: `HomeScreen` shows a `Chip` widget in the top-right area of the body (below the stats row): green dot + `"Đã kết nối"` when `WebSocketService.isConnected == true`, orange dot + `"Đang kết nối lại..."` when reconnecting.
- **MET-C-2**: `WebSocketService` exposes a `bool get isConnected` and a `ValueNotifier<bool>` or `Stream<bool>` that `HomeScreen` can listen to. If already exposed via `GameProvider`, reuse that.

## Acceptance Criteria

- `GET /api/metrics` with an admin token returns a JSON object with all four counters and a timestamp.
- `GET /api/metrics` with a regular user token returns 403.
- Connecting a WS client increments `connected_clients`; disconnecting decrements it.
- Creating a room increments `active_rooms`; the room being cleaned up decrements it.
- The `HomeScreen` WS status chip turns orange when WS is reconnecting and green when connected.
