package ws

const (
	EventGameState = "game_state"
	EventGameStart = "game_start"
	EventGameEnd   = "game_end"
	EventGameMove  = "game_move"
	EventGameOver  = "game_over"

	EventJoinRoom   = "join_room"
	EventLeaveRoom  = "leave_room"
	EventMakeMove   = "make_move"
	EventResign     = "resign"

	EventRoomUpdate  = "room_update"
	EventPlayerJoin  = "player_join"
	EventPlayerLeave = "player_leave"
	EventChatMessage = "chat_message"

	EventStreamStart  = "stream_start"
	EventStreamStop   = "stream_stop"
	EventStreamStatus = "stream_status"

	EventQuickMatchRequest   = "quick_match_request"
	EventQuickMatchFound     = "quick_match_found"
	EventQuickMatchCancelled = "quick_match_cancelled"
	EventQuickMatchTimeout   = "quick_match_timeout"

	EventError = "error"
	EventPing  = "ping"
	EventPong  = "pong"

	MessageTypeMove         = "move"
	MessageTypeChat         = "chat"
	MessageTypeOffer        = "offer"
	MessageTypeAnswer       = "answer"
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
