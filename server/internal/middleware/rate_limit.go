package middleware

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/duvu/playverse/server/internal/cache"
	"github.com/gin-gonic/gin"
)

func RateLimiter(limit int, window time.Duration, keyFunc func(*gin.Context) string) gin.HandlerFunc {
	return func(c *gin.Context) {
		key := fmt.Sprintf("rl:%s", keyFunc(c))
		ctx := context.Background()

		if cache.RedisClient == nil {
			c.Next()
			return
		}

		current, err := cache.RedisClient.Incr(ctx, key).Result()
		if err != nil {
			c.Next()
			return
		}

		if current == 1 {
			cache.RedisClient.Expire(ctx, key, window)
		}

		if current > int64(limit) {
			c.Header("Retry-After", fmt.Sprintf("%d", int(window.Seconds())))
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error": "rate limit exceeded",
			})
			return
		}

		c.Next()
	}
}

func IPKey(c *gin.Context) string {
	return c.ClientIP()
}

func UserKey(c *gin.Context) string {
	userID := c.GetString("user_id")
	if userID == "" {
		return c.ClientIP()
	}
	return userID
}

func UserRateLimiter(limit int, window time.Duration) gin.HandlerFunc {
	return RateLimiter(limit, window, UserKey)
}
