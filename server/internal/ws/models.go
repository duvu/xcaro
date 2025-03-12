package ws

// Player định nghĩa thông tin người chơi trong game
type Player struct {
	UserID   string `json:"user_id"`   // ID người chơi
	Username string `json:"username"`  // Tên người chơi
	Symbol   string `json:"symbol"`    // Ký hiệu (X hoặc O)
	IsReady  bool   `json:"is_ready"`  // Sẵn sàng chơi
	IsOnline bool   `json:"is_online"` // Đang online
	Score    int    `json:"score"`     // Điểm số
}
