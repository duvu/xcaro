package game

import (
	"net/http"

	"github.com/duvu/xcaro/server/internal/ws"
	"github.com/duvu/xcaro/server/pkg/models"
	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Cho phép tất cả origins trong môi trường development
	},
}

type Handler struct {
	service *Service
	hub     *ws.Hub
}

func NewHandler(service *Service, hub *ws.Hub) *Handler {
	return &Handler{
		service: service,
		hub:     hub,
	}
}

// CreateGame godoc
// @Summary Tạo game mới
// @Description Tạo một game cờ caro mới
// @Tags game
// @Security ApiKeyAuth
// @Accept json
// @Produce json
// @Param request body models.CreateGameRequest true "Thông tin tạo game"
// @Success 201 {object} models.Game
// @Failure 400,401 {object} map[string]string "error"
// @Router /games [post]
func (h *Handler) CreateGame(c *gin.Context) {
	var req models.CreateGameRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	game, err := h.service.CreateGame(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, game)
}

// JoinGame godoc
// @Summary Tham gia game
// @Description Tham gia vào một game đang chờ người chơi
// @Tags game
// @Security ApiKeyAuth
// @Accept json
// @Produce json
// @Param id path string true "Game ID"
// @Param request body models.JoinGameRequest true "Thông tin tham gia game"
// @Success 200 {object} models.Game
// @Failure 400,401,404 {object} map[string]string "error"
// @Router /games/{id}/join [post]
func (h *Handler) JoinGame(c *gin.Context) {
	var req models.JoinGameRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	game, err := h.service.JoinGame(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, game)
}

// MakeMove godoc
// @Summary Đánh một nước
// @Description Đánh một nước trong game
// @Tags game
// @Security ApiKeyAuth
// @Accept json
// @Produce json
// @Param id path string true "Game ID"
// @Param request body models.MakeMoveRequest true "Thông tin nước đi"
// @Success 200 {object} models.Game
// @Failure 400,401,404 {object} map[string]string "error"
// @Router /games/{id}/move [post]
func (h *Handler) MakeMove(c *gin.Context) {
	var req models.MakeMoveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	game, err := h.service.MakeMove(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, game)
}

// GetGame godoc
// @Summary Lấy thông tin game
// @Description Lấy thông tin chi tiết của một game
// @Tags game
// @Security ApiKeyAuth
// @Produce json
// @Param id path string true "Game ID"
// @Success 200 {object} models.Game
// @Failure 400,401,404 {object} map[string]string "error"
// @Router /games/{id} [get]
func (h *Handler) GetGame(c *gin.Context) {
	gameID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "game ID không hợp lệ"})
		return
	}

	game, err := h.service.GetGame(c.Request.Context(), gameID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, game)
}

// WebSocketGame godoc
// @Summary Kết nối WebSocket cho game
// @Description Thiết lập kết nối WebSocket để nhận cập nhật real-time của game
// @Tags game
// @Security ApiKeyAuth
// @Produce json
// @Param id path string true "Game ID"
// @Success 101 {object} string "Switching Protocols"
// @Failure 400,401,404 {object} map[string]string "error"
// @Router /games/{id}/ws [get]
func (h *Handler) WebSocketGame(c *gin.Context) {
	gameID, err := primitive.ObjectIDFromHex(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "game ID không hợp lệ"})
		return
	}

	// Kiểm tra game tồn tại
	_, err = h.service.GetGame(c.Request.Context(), gameID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

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
	client := ws.NewClient(h.hub, conn, userID, username)
	client.CurrentRoom = gameID.Hex()

	// Đăng ký client với hub
	h.hub.Register(client)

	// Gửi thông tin game ban đầu
	initialGame, _ := h.service.GetGame(c.Request.Context(), gameID)
	client.Send(&ws.WSMessage{
		Type:    ws.EventGameState,
		RoomID:  gameID.Hex(),
		Payload: initialGame,
	})

	// Bắt đầu goroutines để đọc và ghi
	go client.WritePump()
	go client.ReadPump()
}

// ListGames godoc
// @Summary Lấy danh sách game
// @Description Lấy danh sách các game với các bộ lọc
// @Tags game
// @Security ApiKeyAuth
// @Produce json
// @Param status query string false "Trạng thái game (waiting, in_progress, finished)"
// @Param page query int false "Số trang" default(1)
// @Param limit query int false "Số lượng game mỗi trang" default(10)
// @Success 200 {object} []models.Game
// @Failure 400,401 {object} map[string]string "error"
// @Router /games [get]
func (h *Handler) ListGames(c *gin.Context) {
	var req models.ListGamesRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Implement
}

// GetGameHistory godoc
// @Summary Lấy lịch sử game
// @Description Lấy lịch sử các game của người dùng
// @Tags game
// @Security ApiKeyAuth
// @Produce json
// @Param user_id query string true "ID người dùng"
// @Param status query string false "Trạng thái game (waiting, in_progress, finished)"
// @Param page query int false "Số trang" default(1)
// @Param limit query int false "Số lượng game mỗi trang" default(10)
// @Success 200 {object} []models.Game
// @Failure 400,401 {object} map[string]string "error"
// @Router /games/history [get]
func (h *Handler) GetGameHistory(c *gin.Context) {
	var req models.GetGameHistoryRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Implement
}

// GetGameStats godoc
// @Summary Lấy thống kê game
// @Description Lấy thống kê các game của người dùng
// @Tags game
// @Security ApiKeyAuth
// @Produce json
// @Param user_id query string true "ID người dùng"
// @Success 200 {object} models.GameStats
// @Failure 400,401 {object} map[string]string "error"
// @Router /games/stats [get]
func (h *Handler) GetGameStats(c *gin.Context) {
	var req models.GetGameStatsRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Implement
} 