# Hướng Dẫn Tích Hợp WebSocket

## Thông Tin Chung

### Endpoint WebSocket

```text
ws://your-server/api/ws
```

Production nên dùng `wss://`.

### Xác Thực

WebSocket endpoint yêu cầu JWT hợp lệ. Token có thể gửi bằng một trong hai cách:

- Query parameter: `ws://your-server/api/ws?token=<jwt>`
- Header: `Authorization: Bearer <jwt>`

Người dùng chưa xác minh email vẫn có thể kết nối nhưng sẽ bị từ chối khi tạo phòng hoặc vào hàng đợi, với lỗi `email_not_verified`.

## Envelope Chung

Mọi message dùng JSON envelope:

```json
{
  "type": "event_name",
  "room_id": "optional-room-id",
  "payload": {}
}
```

`room_id` là metadata tùy chọn. Client intent hiện tại đặt dữ liệu chính trong `payload`.

## Client → Server Events

### Tạo phòng

```json
{ "type": "create_room", "payload": {} }
```

Server trả `game_state` với `room_id`, `room_code`/`code`, người tạo là Player X và `status: "waiting"`.

### Vào phòng bằng mã

```json
{ "type": "join_room_by_code", "payload": { "code": "ABC123" } }
```

Server gán người chơi vào Player O, bắt đầu trận khi cả hai ghế đủ, rồi broadcast `game_state` cho cả hai.

### Kết nối lại phòng

```json
{ "type": "rejoin_room", "payload": { "room_id": "ABC123" } }
```

Nếu client chưa biết `room_id`, có thể gửi mã phòng:

```json
{ "type": "rejoin_room", "payload": { "code": "ABC123" } }
```

Server chỉ cho phép user đã giữ ghế Player X/O rejoin trong thời gian grace.

### Đánh cờ

```json
{ "type": "make_move", "payload": { "x": 7, "y": 7 } }
```

Server là nguồn sự thật cho bàn cờ, lượt đi, kết quả và sẽ trả lỗi nếu nước đi không hợp lệ.

### Đầu hàng

```json
{ "type": "resign", "payload": {} }
```

Server broadcast `game_over` với `result: "resign"` và `winner` là user ID của đối thủ.

### Tìm đối thủ nhanh

```json
{ "type": "quick_match_request", "payload": {} }
```

Server trả:

- `quick_match_found` khi ghép cặp thành công
- `quick_match_timeout` nếu quá 60 giây không có đối thủ
- `error` với `already_queued` nếu user đã ở trong hàng đợi

Huỷ tìm đối thủ:

```json
{ "type": "quick_match_cancel", "payload": {} }
```

Server trả `quick_match_cancelled` nếu xoá khỏi hàng đợi thành công.

### Chat trong phòng

```json
{ "type": "chat_message", "payload": { "content": "Xin chào!" } }
```

Nội dung phải dài 1-500 ký tự.

## Server → Client Events

### `game_state`

Payload canonical:

```json
{
  "room_id": "ABC123",
  "room_code": "ABC123",
  "code": "ABC123",
  "board": [[0, 0, 0]],
  "turn": 1,
  "current_turn": "user-id-player-x",
  "started": true,
  "game_over": false,
  "winner": null,
  "result": null,
  "status": "active",
  "players": {
    "x": { "user_id": "user-x", "username": "alice" },
    "o": { "user_id": "user-o", "username": "bob" }
  },
  "player_x": { "user_id": "user-x", "username": "alice" },
  "player_o": { "user_id": "user-o", "username": "bob" },
  "winning_cells": []
}
```

`board` dùng `0` cho ô trống, `1` cho X, `2` cho O. Client phải coi payload này là trạng thái chuẩn và thay thế state local bằng dữ liệu server.

### `game_over`

Payload giống `game_state` nhưng `game_over: true`, `status: "finished"`, có `winner`, `result`, và có thể có `winning_cells`.

`result` hiện gồm:

- `win`
- `draw`
- `resign`
- `forfeit`

### `quick_match_found`

```json
{
  "room_id": "ABC123",
  "room_code": "ABC123",
  "color": "x",
  "game_state": { }
}
```

`game_state` chứa payload canonical như trên.

### `error`

```json
{
  "type": "error",
  "payload": {
    "code": "room_not_found",
    "message": "Room not found"
  }
}
```

Client nên xử lý theo `code`, không parse chuỗi `message`.

Các mã lỗi chính:

- `invalid_json`
- `invalid_payload`
- `unknown_event`
- `email_not_verified`
- `room_not_found`
- `room_full`
- `not_a_player`
- `no_active_game`
- `game_not_started`
- `game_already_over`
- `not_your_turn`
- `invalid_coordinates`
- `cell_occupied`
- `already_queued`
- `invalid_message`

## Reconnect Và Forfeit

- Client tự reconnect với backoff tăng dần, tối đa 30 giây.
- Sau khi reconnect, client gửi `rejoin_room` bằng `room_id` hoặc `code` cuối cùng.
- Server giữ ghế trong 30 giây nếu trận đã bắt đầu.
- Nếu user không quay lại trong grace period, server kết thúc trận bằng `result: "forfeit"` và broadcast `game_over`.
- Nếu phòng chưa bắt đầu, disconnect sẽ giải phóng ghế và phòng rỗng sẽ được cleanup sau 5 phút.

## Flutter Integration Notes

- `WebSocketService` giữ JWT token, mở kết nối, đồng bộ `room_id`/`room_code` từ `game_state`, và rejoin sau reconnect.
- `GameProvider` chỉ cập nhật board/lượt/người chơi từ `game_state` hoặc `game_over`.
- Màn tạo phòng dùng `create_room` và hiển thị `room_code` trong trạng thái `waiting`.
- Màn vào phòng dùng `join_room_by_code`.
- Màn quick match dùng `quick_match_request` và `quick_match_cancel`.
- Màn game không nên coi thao tác client là thành công cho tới khi server trả `game_state` mới.

## Bảo Mật Và Vận Hành

1. Luôn dùng WSS trong production.
2. Không log JWT token.
3. Server xác thực mọi intent và kiểm tra lượt đi/membership trước khi đổi state.
4. Dùng rate limiting cho WebSocket endpoint.
5. Active rooms đang lưu in-memory, nên restart server có thể làm mất trận đang diễn ra.
