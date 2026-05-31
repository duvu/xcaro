package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/duvu/playverse/server/internal/cache"
	"github.com/gin-gonic/gin"
)

func TestRateLimiter_FailOpen(t *testing.T) {
	cache.RedisClient = nil

	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.GET("/test", RateLimiter(2, time.Minute, IPKey), func(c *gin.Context) {
		c.JSON(200, gin.H{"ok": true})
	})

	for i := 0; i < 5; i++ {
		req := httptest.NewRequest("GET", "/test", nil)
		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)
		if w.Code != http.StatusOK {
			t.Errorf("expected 200 with nil Redis, got %d", w.Code)
		}
	}
}
