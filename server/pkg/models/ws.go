package models

import "time"

// WSMessage định nghĩa cấu trúc message WebSocket
type WSMessage struct {
	Type    string      `json:"type"`              // Loại event
	RoomID  string      `json:"room_id,omitempty"` // ID phòng (nếu có)
	Payload interface{} `json:"payload"`           // Dữ liệu của event
}

// ChatMessage định nghĩa cấu trúc tin nhắn chat
type ChatMessage struct {
	UserID    string    `json:"user_id"`   // ID người gửi
	Username  string    `json:"username"`  // Tên người gửi
	Content   string    `json:"content"`   // Nội dung tin nhắn
	Type      string    `json:"type"`      // Loại tin nhắn (text/emoji/gift)
	Timestamp time.Time `json:"timestamp"` // Thời gian gửi
}

// JoinRoomRequest request cho việc tham gia phòng
type JoinRoomRequest struct {
	RoomID string `json:"room_id" binding:"required"` // ID phòng
}

// LeaveRoomRequest request cho việc rời phòng
type LeaveRoomRequest struct {
	RoomID string `json:"room_id" binding:"required"` // ID phòng
}

// SendMessageRequest request cho việc gửi tin nhắn
type SendMessageRequest struct {
	RoomID  string      `json:"room_id" binding:"required"` // ID phòng
	Content string      `json:"content" binding:"required"` // Nội dung tin nhắn
	Type    string      `json:"type"`                      // Loại tin nhắn (text/emoji/gift)
} 