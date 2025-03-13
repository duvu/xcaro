package game

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

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

	// Set giá trị mặc định cho phân trang
	if req.Page <= 0 {
		req.Page = 1
	}
	if req.Limit <= 0 {
		req.Limit = 10
	}

	games, err := h.service.ListGames(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, games)
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

	// Set giá trị mặc định cho phân trang
	if req.Page <= 0 {
		req.Page = 1
	}
	if req.Limit <= 0 {
		req.Limit = 10
	}

	games, err := h.service.GetGameHistory(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, games)
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

	stats, err := h.service.GetGameStats(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, stats)
}

// ReplayGame godoc
// @Summary Xem lại game đến một nước đi cụ thể
// @Description Xem lại game đến một nước đi cụ thể
// @Tags games
// @Accept json
// @Produce json
// @Param game_id path string true "Game ID"
// @Param step query int false "Số nước đi muốn xem"
// @Success 200 {object} models.Game
// @Failure 400 {object} models.ErrorResponse
// @Failure 404 {object} models.ErrorResponse
// @Router /api/games/{game_id}/replay [get]
func (h *Handler) ReplayGame(c *gin.Context) {
	gameID := c.Param("game_id")
	step, _ := strconv.Atoi(c.DefaultQuery("step", "0"))

	req := &models.ReplayGameRequest{
		GameID: gameID,
		Step:   step,
	}

	game, err := h.service.ReplayGame(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, game)
}

// GetLeaderboard godoc
// @Summary Lấy bảng xếp hạng người chơi
// @Description Lấy bảng xếp hạng người chơi theo tỷ lệ thắng
// @Tags games
// @Accept json
// @Produce json
// @Success 200 {array} models.LeaderboardEntry
// @Failure 400 {object} models.ErrorResponse
// @Router /api/games/leaderboard [get]
func (h *Handler) GetLeaderboard(c *gin.Context) {
	entries, err := h.service.GetLeaderboard(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, entries)
}

// SearchGames godoc
// @Summary Tìm kiếm game theo các tiêu chí
// @Description Tìm kiếm game theo khoảng thời gian và trạng thái
// @Tags games
// @Accept json
// @Produce json
// @Param start_date query string true "Ngày bắt đầu (RFC3339)"
// @Param end_date query string true "Ngày kết thúc (RFC3339)"
// @Param status query string false "Trạng thái game"
// @Param page query int false "Số trang"
// @Param limit query int false "Số game mỗi trang"
// @Success 200 {array} models.Game
// @Failure 400 {object} models.ErrorResponse
// @Router /api/games/search [get]
func (h *Handler) SearchGames(c *gin.Context) {
	startDate, err := time.Parse(time.RFC3339, c.Query("start_date"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Ngày bắt đầu không hợp lệ"})
		return
	}

	endDate, err := time.Parse(time.RFC3339, c.Query("end_date"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Ngày kết thúc không hợp lệ"})
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

	req := &models.SearchGamesRequest{
		StartDate: startDate,
		EndDate:   endDate,
		Status:    c.Query("status"),
		Page:      page,
		Limit:     limit,
	}

	games, err := h.service.SearchGames(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: err.Error()})
		return
	}

	c.JSON(http.StatusOK, games)
}

// ExportGameHistory godoc
// @Summary Xuất lịch sử game
// @Description Xuất lịch sử game của người dùng theo định dạng JSON hoặc CSV
// @Tags games
// @Accept json
// @Produce json
// @Param user_id query string true "User ID"
// @Param start_date query string true "Ngày bắt đầu (RFC3339)"
// @Param end_date query string true "Ngày kết thúc (RFC3339)"
// @Param format query string true "Định dạng xuất (json/csv)"
// @Success 200 {string} string
// @Failure 400 {object} models.ErrorResponse
// @Router /api/games/export [get]
func (h *Handler) ExportGameHistory(c *gin.Context) {
	startDate, err := time.Parse(time.RFC3339, c.Query("start_date"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Ngày bắt đầu không hợp lệ"})
		return
	}

	endDate, err := time.Parse(time.RFC3339, c.Query("end_date"))
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Ngày kết thúc không hợp lệ"})
		return
	}

	format := c.Query("format")
	if format != "json" && format != "csv" {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Định dạng không được hỗ trợ"})
		return
	}

	req := &models.ExportHistoryRequest{
		UserID:    c.Query("user_id"),
		StartDate: startDate,
		EndDate:   endDate,
		Format:    format,
	}

	data, err := h.service.ExportGameHistory(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: err.Error()})
		return
	}

	// Set content type và filename
	contentType := "application/json"
	filename := "game_history.json"
	if format == "csv" {
		contentType = "text/csv"
		filename = "game_history.csv"
	}

	c.Header("Content-Type", contentType)
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))
	c.Data(http.StatusOK, contentType, data)
}
