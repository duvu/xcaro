package apierrors

import (
	"context"
	"log/slog"
	"net/http"
	"time"

	"github.com/duvu/playverse/server/internal/middleware"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// ErrorReport is stored in the "error_reports" collection.
type ErrorReport struct {
	ID         primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Platform   string             `bson:"platform"      json:"platform"`
	Version    string             `bson:"version"       json:"version"`
	ErrorType  string             `bson:"error_type"    json:"error_type"`
	Message    string             `bson:"message"       json:"message"`
	StackTrace string             `bson:"stack_trace,omitempty" json:"stack_trace,omitempty"`
	CreatedAt  time.Time          `bson:"created_at"    json:"created_at"`
}

type submitRequest struct {
	Platform   string `json:"platform"    binding:"required"`
	Version    string `json:"version"     binding:"required"`
	ErrorType  string `json:"error_type"  binding:"required"`
	Message    string `json:"message"     binding:"required"`
	StackTrace string `json:"stack_trace"`
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

	// Truncate stack trace to 4096 chars to avoid huge documents.
	if len(req.StackTrace) > 4096 {
		req.StackTrace = req.StackTrace[:4096]
	}

	report := ErrorReport{
		ID:         primitive.NewObjectID(),
		Platform:   req.Platform,
		Version:    req.Version,
		ErrorType:  req.ErrorType,
		Message:    req.Message,
		StackTrace: req.StackTrace,
		CreatedAt:  time.Now(),
	}

	if _, err := h.db.Collection("error_reports").InsertOne(context.Background(), report); err != nil {
		slog.ErrorContext(c.Request.Context(), "error_report insert failed", "error", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to store error report"})
		return
	}

	slog.InfoContext(c.Request.Context(), "error_report stored", "platform", req.Platform, "version", req.Version, "error_type", req.ErrorType)
	c.JSON(http.StatusCreated, gin.H{"message": "error report received"})
}

// RegisterRoutes mounts the error reporting routes (public, no auth required).
func RegisterRoutes(r *gin.RouterGroup, db *mongo.Database) {
	h := NewHandler(db)
	r.POST("/errors", middleware.RateLimiter(10, time.Hour, middleware.IPKey), h.Submit)
}
