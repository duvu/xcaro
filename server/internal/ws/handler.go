package ws

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Cho phép tất cả origin trong môi trường dev
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

// HandleWebSocket xử lý kết nối WebSocket mới
func (h *Handler) HandleWebSocket(c *gin.Context) {
	// Lấy thông tin user từ JWT token (đã được xử lý bởi middleware auth)
	userID := c.GetString("user_id")
	if userID == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	username := c.GetString("username")
	if username == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	// Nâng cấp kết nối HTTP lên WebSocket
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("Lỗi upgrade websocket: %v", err)
		return
	}

	// Tạo client mới
	client := NewClient(h.hub, conn, userID, username)

	// Đăng ký client với hub
	h.hub.register <- client

	// Bắt đầu goroutines để xử lý tin nhắn
	go client.WritePump()
	go client.ReadPump()
}
