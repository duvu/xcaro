package ws

// Event types
const (
	// Game events
	EventGameState = "game_state" // Cập nhật trạng thái game
	EventGameStart = "game_start" // Game bắt đầu
	EventGameEnd   = "game_end"   // Game kết thúc
	EventGameMove  = "game_move"  // Nước đi mới

	// Room events
	EventRoomUpdate  = "room_update"  // Cập nhật thông tin phòng
	EventPlayerJoin  = "player_join"  // Người chơi tham gia
	EventPlayerLeave = "player_leave" // Người chơi rời đi
	EventChatMessage = "chat_message" // Tin nhắn chat

	// Stream events
	EventStreamStart  = "stream_start"  // Stream bắt đầu
	EventStreamStop   = "stream_stop"   // Stream kết thúc
	EventStreamStatus = "stream_status" // Cập nhật trạng thái stream

	// System events
	EventError = "error" // Thông báo lỗi
	EventPing  = "ping"  // Kiểm tra kết nối
	EventPong  = "pong"  // Phản hồi kiểm tra kết nối

	MessageTypeMove = "move"
	MessageTypeChat = "chat"
	MessageTypeOffer = "offer"
	MessageTypeAnswer = "answer"
	MessageTypeIceCandidate = "ice-candidate"
)

// WSMessage định nghĩa cấu trúc message WebSocket
type WSMessage struct {
	Type    string      `json:"type"`              // Loại event
	RoomID  string      `json:"room_id,omitempty"` // ID phòng (nếu có)
	Payload interface{} `json:"payload"`           // Dữ liệu của event
}

// GameStatePayload payload cho event game state
type GameStatePayload struct {
	Board       [][]string `json:"board"`        // Trạng thái bàn cờ
	CurrentTurn string     `json:"current_turn"` // Lượt đi hiện tại
	Winner      string     `json:"winner"`       // Người thắng (nếu có)
	Status      string     `json:"status"`       // Trạng thái game
	Players     []Player   `json:"players"`      // Thông tin người chơi
}

// ChatMessagePayload payload cho event chat
type ChatMessagePayload struct {
	UserID    string `json:"user_id"`   // ID người gửi
	Username  string `json:"username"`  // Tên người gửi
	Content   string `json:"content"`   // Nội dung tin nhắn
	Type      string `json:"type"`      // Loại tin nhắn (text/emoji/gift)
	Timestamp int64  `json:"timestamp"` // Thời gian gửi
}

// StreamStatusPayload payload cho event stream status
type StreamStatusPayload struct {
	IsLive      bool   `json:"is_live"`      // Stream đang live?
	ViewerCount int    `json:"viewer_count"` // Số người xem
	StreamURL   string `json:"stream_url"`   // URL của stream
	Quality     string `json:"quality"`      // Chất lượng stream
}

// ErrorPayload payload cho event error
type ErrorPayload struct {
	Code    string `json:"code"`    // Mã lỗi
	Message string `json:"message"` // Thông báo lỗi
}

type Message struct {
	Type    string      `json:"type"`
	Payload interface{} `json:"payload"`
}

type ChatMessage struct {
	UserID    string `json:"user_id"`
	Username  string `json:"username"`
	Content   string `json:"content"`
	Timestamp int64  `json:"timestamp"`
}

type WebRTCMessage struct {
	UserID string      `json:"user_id"`
	Data   interface{} `json:"data"`
}
