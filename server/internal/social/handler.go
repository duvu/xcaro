package social

import (
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/mongo"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func RegisterRoutes(group *gin.RouterGroup, db *mongo.Database) *Service {
	service := NewService(db)
	handler := NewHandler(service)

	dashboard := group.Group("/dashboard")
	{
		dashboard.GET("/summary", handler.GetDashboardSummary)
		dashboard.GET("/history", handler.GetHistory)
	}

	social := group.Group("/social")
	{
		social.GET("/players", handler.SearchPlayers)
		social.GET("/friends", handler.ListFriends)
		social.DELETE("/friends/:user_id", handler.RemoveFriend)
		social.GET("/friend-requests", handler.ListRequests)
		social.POST("/friend-requests", handler.SendRequest)
		social.POST("/friend-requests/:id/accept", handler.AcceptRequest)
		social.POST("/friend-requests/:id/reject", handler.RejectRequest)
		social.POST("/friend-requests/:id/cancel", handler.CancelRequest)
	}

	return service
}

func (h *Handler) GetDashboardSummary(c *gin.Context) {
	summary, err := h.service.DashboardSummary(c.Request.Context(), c.GetString("user_id"), c.Query("game_type"))
	respond(c, summary, err)
}

func (h *Handler) GetHistory(c *gin.Context) {
	filters := HistoryFilters{Page: intQuery(c, "page", 1), Limit: intQuery(c, "limit", 20), GameType: c.Query("game_type"), Result: c.Query("result"), Opponent: c.Query("opponent")}
	if from := c.Query("from"); from != "" {
		parsed, err := time.Parse(time.RFC3339, from)
		if err != nil {
			respond(c, nil, apiError(http.StatusBadRequest, "invalid_from", "ngày bắt đầu không hợp lệ"))
			return
		}
		filters.From = &parsed
	}
	if to := c.Query("to"); to != "" {
		parsed, err := time.Parse(time.RFC3339, to)
		if err != nil {
			respond(c, nil, apiError(http.StatusBadRequest, "invalid_to", "ngày kết thúc không hợp lệ"))
			return
		}
		filters.To = &parsed
	}
	history, err := h.service.History(c.Request.Context(), c.GetString("user_id"), filters)
	respond(c, history, err)
}

func (h *Handler) SearchPlayers(c *gin.Context) {
	players, err := h.service.SearchPlayers(c.Request.Context(), c.GetString("user_id"), c.Query("q"), intQuery(c, "page", 1), intQuery(c, "limit", 20))
	respond(c, gin.H{"players": players}, err)
}

func (h *Handler) ListFriends(c *gin.Context) {
	friends, err := h.service.ListFriends(c.Request.Context(), c.GetString("user_id"))
	respond(c, gin.H{"friends": friends}, err)
}

func (h *Handler) RemoveFriend(c *gin.Context) {
	err := h.service.RemoveFriend(c.Request.Context(), c.GetString("user_id"), c.Param("user_id"))
	respond(c, gin.H{"message": "đã xóa bạn bè"}, err)
}

func (h *Handler) ListRequests(c *gin.Context) {
	box := c.DefaultQuery("box", "incoming")
	if box != "incoming" && box != "outgoing" {
		respond(c, nil, apiError(http.StatusBadRequest, "invalid_box", "box phải là incoming hoặc outgoing"))
		return
	}
	requests, err := h.service.ListRequests(c.Request.Context(), c.GetString("user_id"), box)
	respond(c, gin.H{"requests": requests}, err)
}

func (h *Handler) SendRequest(c *gin.Context) {
	var req struct {
		RecipientID string `json:"recipient_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		respond(c, nil, apiError(http.StatusBadRequest, "invalid_payload", "recipient_id là bắt buộc"))
		return
	}
	request, err := h.service.SendFriendRequest(c.Request.Context(), c.GetString("user_id"), req.RecipientID)
	respondStatus(c, http.StatusCreated, request, err)
}

func (h *Handler) AcceptRequest(c *gin.Context) {
	friendship, err := h.service.AcceptRequest(c.Request.Context(), c.GetString("user_id"), c.Param("id"))
	respond(c, friendship, err)
}

func (h *Handler) RejectRequest(c *gin.Context) {
	err := h.service.RejectRequest(c.Request.Context(), c.GetString("user_id"), c.Param("id"))
	respond(c, gin.H{"message": "đã từ chối lời mời"}, err)
}

func (h *Handler) CancelRequest(c *gin.Context) {
	err := h.service.CancelRequest(c.Request.Context(), c.GetString("user_id"), c.Param("id"))
	respond(c, gin.H{"message": "đã hủy lời mời"}, err)
}

func intQuery(c *gin.Context, key string, fallback int64) int64 {
	value, err := strconv.ParseInt(c.DefaultQuery(key, strconv.FormatInt(fallback, 10)), 10, 64)
	if err != nil {
		return fallback
	}
	return value
}

func respond(c *gin.Context, payload interface{}, err error) {
	respondStatus(c, http.StatusOK, payload, err)
}

func respondStatus(c *gin.Context, status int, payload interface{}, err error) {
	if err != nil {
		var apiErr *APIError
		if errors.As(err, &apiErr) {
			c.JSON(apiErr.Status, gin.H{"code": apiErr.Code, "error": apiErr.Message})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"code": "internal_error", "error": "không thể xử lý yêu cầu"})
		return
	}
	c.JSON(status, payload)
}
