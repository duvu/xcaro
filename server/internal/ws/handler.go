package ws

import (
	"net/http"
	"time"

	"github.com/duvu/xcaro/server/pkg/models"
	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Cho phép tất cả origins trong môi trường development
	},
}

type Handler struct {
	hub *Hub
}

func NewHandler(hub *Hub) *Handler {
	return &Handler{
		hub: hub,
	}
}

// Connect godoc
// @Summary Kết nối WebSocket
// @Description Thiết lập kết nối WebSocket cho client
// @Tags websocket
// @Security ApiKeyAuth
// @Produce json
// @Success 101 {object} string "Switching Protocols"
// @Failure 400,401 {object} map[string]string "error"
// @Router /ws [get]
func (h *Handler) Connect(c *gin.Context) {
	// Nâng cấp HTTP connection lên WebSocket
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể thiết lập kết nối WebSocket"})
		return
	}

	// Lấy thông tin user từ context
	userID := c.GetString("user_id")
	username := c.GetString("username")

	// Tạo client mới
	client := NewClient(h.hub, conn, userID, username)

	// Đăng ký client với hub
	h.hub.Register(client)

	// Bắt đầu goroutines để đọc và ghi
	go client.WritePump()
	go client.ReadPump()
}

// JoinRoom godoc
// @Summary Tham gia phòng
// @Description Tham gia vào một phòng chat hoặc game
// @Tags websocket
// @Security ApiKeyAuth
// @Accept json
// @Produce json
// @Param request body models.JoinRoomRequest true "Thông tin tham gia phòng"
// @Success 200 {object} map[string]string "message"
// @Failure 400,401 {object} map[string]string "error"
// @Router /ws/rooms/join [post]
func (h *Handler) JoinRoom(c *gin.Context) {
	var req models.JoinRoomRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Lấy thông tin user từ context
	userID := c.GetString("user_id")

	// Tìm client trong hub
	var client *Client
	for c := range h.hub.clients {
		if c.UserID == userID {
			client = c
			break
		}
	}

	if client == nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "không tìm thấy kết nối WebSocket"})
		return
	}

	// Tham gia phòng
	client.JoinRoom(req.RoomID)

	c.JSON(http.StatusOK, gin.H{"message": "đã tham gia phòng thành công"})
}

// LeaveRoom godoc
// @Summary Rời phòng
// @Description Rời khỏi phòng chat hoặc game
// @Tags websocket
// @Security ApiKeyAuth
// @Accept json
// @Produce json
// @Param request body models.LeaveRoomRequest true "Thông tin rời phòng"
// @Success 200 {object} map[string]string "message"
// @Failure 400,401 {object} map[string]string "error"
// @Router /ws/rooms/leave [post]
func (h *Handler) LeaveRoom(c *gin.Context) {
	var req models.LeaveRoomRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Lấy thông tin user từ context
	userID := c.GetString("user_id")

	// Tìm client trong hub
	var client *Client
	for c := range h.hub.clients {
		if c.UserID == userID {
			client = c
			break
		}
	}

	if client == nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "không tìm thấy kết nối WebSocket"})
		return
	}

	// Rời phòng
	client.LeaveRoom()

	c.JSON(http.StatusOK, gin.H{"message": "đã rời phòng thành công"})
}

// SendMessage godoc
// @Summary Gửi tin nhắn
// @Description Gửi tin nhắn đến phòng chat hoặc game
// @Tags websocket
// @Security ApiKeyAuth
// @Accept json
// @Produce json
// @Param request body models.SendMessageRequest true "Nội dung tin nhắn"
// @Success 200 {object} map[string]string "message"
// @Failure 400,401 {object} map[string]string "error"
// @Router /ws/messages [post]
func (h *Handler) SendMessage(c *gin.Context) {
	var req models.SendMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Lấy thông tin user từ context
	userID := c.GetString("user_id")
	username := c.GetString("username")

	// Tìm client trong hub
	var client *Client
	for c := range h.hub.clients {
		if c.UserID == userID {
			client = c
			break
		}
	}

	if client == nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "không tìm thấy kết nối WebSocket"})
		return
	}

	// Tạo tin nhắn mới
	message := &models.ChatMessage{
		UserID:    userID,
		Username:  username,
		Content:   req.Content,
		Type:      req.Type,
		Timestamp: time.Now(),
	}

	// Gửi tin nhắn đến phòng
	h.hub.Broadcast(&WSMessage{
		Type:    EventChatMessage,
		RoomID:  req.RoomID,
		Payload: message,
	})

	c.JSON(http.StatusOK, gin.H{"message": "đã gửi tin nhắn thành công"})
}
