package reports

import (
	"context"
	"log/slog"
	"net/http"
	"time"

	"github.com/duvu/xcaro/server/internal/middleware"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// Report is stored in the "reports" collection.
type Report struct {
	ID             primitive.ObjectID `bson:"_id,omitempty"  json:"id"`
	ReporterID     string             `bson:"reporter_id"    json:"reporter_id"`
	ReportedUserID string             `bson:"reported_user_id" json:"reported_user_id"`
	GameID         string             `bson:"game_id,omitempty" json:"game_id,omitempty"`
	Reason         string             `bson:"reason"         json:"reason"`
	CreatedAt      time.Time          `bson:"created_at"     json:"created_at"`
}

type submitRequest struct {
	ReportedUserID string `json:"reported_user_id" binding:"required"`
	GameID         string `json:"game_id"`
	Reason         string `json:"reason"           binding:"required,max=500"`
}

type Handler struct {
	db *mongo.Database
}

func NewHandler(db *mongo.Database) *Handler {
	return &Handler{db: db}
}

func (h *Handler) Submit(c *gin.Context) {
	var req submitRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	reporterID := c.GetString("user_id")

	report := Report{
		ID:             primitive.NewObjectID(),
		ReporterID:     reporterID,
		ReportedUserID: req.ReportedUserID,
		GameID:         req.GameID,
		Reason:         req.Reason,
		CreatedAt:      time.Now(),
	}

	if _, err := h.db.Collection("reports").InsertOne(context.Background(), report); err != nil {
		slog.ErrorContext(c.Request.Context(), "report insert failed", "reporter_id", reporterID, "error", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to submit report"})
		return
	}

	slog.InfoContext(c.Request.Context(), "report submitted", "reporter_id", reporterID, "reported_user_id", req.ReportedUserID)
	c.JSON(http.StatusCreated, gin.H{"message": "report submitted"})
}

// RegisterRoutes mounts the reports routes under the provided router group.
// The group should already be authenticated.
func RegisterRoutes(r *gin.RouterGroup, db *mongo.Database) {
	h := NewHandler(db)
	r.POST("/reports", middleware.RateLimiter(3, time.Hour, middleware.UserKey), h.Submit)
}
