# PlayVerse Game Server

Server game cờ caro được viết bằng Go, sử dụng Gin framework, MongoDB và WebSocket/WebRTC cho realtime communication.

## Cấu trúc dự án

```
server/
├── cmd/                # Điểm khởi chạy ứng dụng
│   └── server/
│       └── main.go    # File chính để khởi động server
├── internal/          # Package nội bộ
│   ├── auth/         # Xử lý xác thực người dùng
│   ├── game/         # Logic game cờ caro
│   └── ws/           # Xử lý WebSocket và realtime communication
├── pkg/              # Package có thể được sử dụng bởi các ứng dụng khác
│   └── models/       # Định nghĩa các model
├── Dockerfile        # File cấu hình để build Docker image
└── .env             # File cấu hình môi trường
```

## Tính năng

1. **Xác thực người dùng**
   - Đăng ký: `POST /api/auth/register`
     ```json
     {
       "username": "string",
       "password": "string"
     }
     ```
   - Đăng nhập: `POST /api/auth/login`
     ```json
     {
       "username": "string",
       "password": "string"
     }
     ```
   - Response:
     ```json
     {
       "token": "jwt_token",
       "user": {
         "id": "user_id",
         "username": "string"
       }
     }
     ```

2. **Quản lý game**
   - Tạo game mới: `POST /api/games`
     ```json
     {
       "player1_id": "string"
     }
     ```
   - Xem thông tin game: `GET /api/games/:id`
   - Tham gia game: `POST /api/games/:id/join`
     ```json
     {
       "player2_id": "string"
     }
     ```
   - Đánh một nước: `POST /api/games/:id/move`
     ```json
     {
       "player_id": "string",
       "row": number,
       "col": number
     }
     ```

3. **Realtime Communication**
   - WebSocket endpoint: `GET /api/ws`
   - Kết nối: `ws://server:8080/api/ws?token=<jwt_token>` cho Flutter/native client, hoặc Bearer JWT qua header khi client hỗ trợ header WebSocket.
   - Tính năng:
     - Tạo phòng online và tham gia bằng mã 6 ký tự
     - Quick match giữa hai người chơi khác nhau
     - Đồng bộ bàn cờ/lượt đi/kết quả bằng server-authoritative `game_state`
     - Chat text trong game
     - Reconnect grace 30 giây trước khi xử thua do mất kết nối
     - Ping/Pong tự động (60s timeout)

## WebSocket Protocol

### Message Types

1. **Create Room**
```json
{
  "type": "create_room",
  "payload": {}
}
```

2. **Join Room By Code**
```json
{
  "type": "join_room_by_code",
  "payload": {
    "code": "ABC123"
  }
}
```

3. **Move Message**
```json
{
  "type": "make_move",
  "payload": {
    "x": 7,
    "y": 7
  }
}
```

4. **Quick Match / Cancel**
```json
{
  "type": "quick_match_request",
  "payload": {}
}
```

5. **Chat Message**
```json
{
  "type": "chat_message",
  "payload": {
    "content": "Xin chào"
  }
}
```

Server emits `game_state`, `game_over`, `quick_match_found`,
`quick_match_cancelled`, `quick_match_timeout`, `chat_message`, `error`, and
`pong`. See `../docs/WEBSOCKET_INTEGRATION.md` for the canonical payload shape
and machine-readable error codes.

### WebRTC Configuration

```javascript
const configuration = {
  iceServers: [
    { urls: 'stun:stun.l.google.com:19302' }
    // Thêm TURN server cho production
  ]
};
```

## Cách triển khai

### 1. Triển khai với Docker

```bash
# Clone dự án
git clone <repository_url>
cd playverse

# Build và chạy với Docker Compose
docker-compose up --build
```

Server sẽ chạy tại `http://localhost:8080`

### 2. Triển khai thủ công

1. Cài đặt MongoDB và tạo database:
   ```bash
   # Tạo user và database
   mongosh
   use playverse
   db.createUser({
     user: "admin",
     pwd: "secret",
     roles: ["readWrite"]
   })
   ```

2. Cấu hình môi trường:
   ```bash
   # Copy file .env.example thành .env và cập nhật các giá trị
   cp .env.example .env
   ```

3. Chạy server:
   ```bash
   cd server
   go run cmd/server/main.go
   ```

## Môi trường

File `.env` cần có các biến môi trường sau:

```env
# Server Configuration
PORT=8080
GIN_MODE=release      # release hoặc debug

# MongoDB Configuration
MONGODB_URI=mongodb://admin:secret@localhost:27017/playverse?authSource=admin
DB_NAME=playverse

# JWT Configuration
JWT_SECRET=your-secret-key
JWT_EXPIRATION=24h    # Thời gian hết hạn của token
```

## Bảo mật

- Sử dụng JWT để xác thực người dùng
- Mật khẩu được mã hóa với bcrypt
- Tất cả các API game đều yêu cầu xác thực
- WebSocket connection được bảo vệ bằng JWT
- WebSocket query-token values are redacted from Gin access logs
- CORS/rate limiting should be reviewed for production origins and traffic

## Xử lý lỗi và Logging

- Server sử dụng Gin logger để ghi log HTTP requests
- WebSocket errors được log với context đầy đủ
- MongoDB connection được giám sát thông qua health check endpoint
- WebRTC signaling errors được xử lý và log
- Tự động đóng kết nối không hoạt động sau 60 giây
- Ping/Pong để kiểm tra kết nối WebSocket còn sống
- Graceful shutdown cho cleanup resources

## Performance

- WebSocket connection pooling cho mỗi game
- Giới hạn kích thước message (512KB)
- Sử dụng goroutines cho xử lý song song
- Tối ưu hóa MongoDB queries với indexes
- WebRTC P2P cho voice/video để giảm tải server
- Connection pooling cho MongoDB
- Caching cho game state (coming soon)

## Monitoring

- Health check endpoint: `GET /api/health`
- MongoDB connection status
- WebSocket connections count
- Active games count
- System metrics (coming soon)

## Hạn chế hiện tại

1. Chưa có TURN server cho WebRTC fallback
2. Chưa lưu lịch sử chat
3. Chưa có retry mechanism cho WebSocket disconnection
4. Chưa có rate limiting cho chat và game moves
5. Chưa có system metrics monitoring
6. Chưa có auto-scaling configuration

## Kế hoạch phát triển

1. Thêm TURN server cho WebRTC
2. Lưu trữ lịch sử chat trong MongoDB
3. Thêm tính năng replay game
4. Thêm bảng xếp hạng người chơi
5. Thêm tính năng spectator mode
6. Thêm system metrics và monitoring
7. Cấu hình auto-scaling
8. Tối ưu hóa performance

## Testing

```bash
# Unit tests
go test ./...

# Integration tests (cần MongoDB)
go test -tags=integration ./...

# Load testing (cần k6)
k6 run tests/load/ws_test.js
```

## Đóng góp

1. Fork dự án
2. Tạo branch mới (`git checkout -b feature/amazing-feature`)
3. Commit thay đổi (`git commit -m 'Add some amazing feature'`)
4. Push lên branch (`git push origin feature/amazing-feature`)
5. Tạo Pull Request

## Tính năng chưa làm

### Ưu tiên cao (Security & Stability)
- [ ] Rate limiting cho API endpoints
- [ ] Rate limiting cho WebSocket (chat và game moves)
- [ ] Retry mechanism cho WebSocket disconnection
- [ ] Unit tests và integration tests
- [ ] API documentation (Swagger/OpenAPI)
- [ ] Cơ chế refresh token
- [ ] Xác thực 2 lớp (2FA)

### Ưu tiên trung bình (Core Features)
- [ ] Lưu lịch sử chat vào MongoDB
- [ ] Bảng xếp hạng người chơi
- [ ] Quản lý profile người dùng
- [ ] Quên/reset mật khẩu
- [ ] Xác thực email
- [ ] Roles và permissions
- [ ] Tính năng undo/redo nước đi
- [ ] Emoji/sticker trong chat

### Ưu tiên thấp (Nice to have)
- [ ] TURN server cho WebRTC fallback
- [ ] Voice/Video call
- [ ] Spectator mode (xem người khác chơi)
- [ ] Replay game
- [ ] System metrics và monitoring
- [ ] Logging service (ELK stack)
- [ ] Alert system
- [ ] Auto-scaling configuration
- [ ] CI/CD pipeline
- [ ] Backup strategy
- [ ] Disaster recovery plan
- [ ] Caching cho game state

## License

MIT License - xem file [LICENSE](LICENSE) để biết thêm chi tiết. 
