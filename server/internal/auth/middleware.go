package auth

import (
	"net/http"
	"strings"

	"github.com/duvu/playverse/server/internal/models"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		tokenString := ""

		if authHeader != "" {
			// Kiểm tra format "Bearer <token>"
			parts := strings.Split(authHeader, " ")
			if len(parts) != 2 || parts[0] != "Bearer" {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "format token không hợp lệ"})
				return
			}
			tokenString = parts[1]
		} else if strings.EqualFold(c.GetHeader("Upgrade"), "websocket") {
			tokenString = c.Query("token")
			if tokenString == "" {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "không tìm thấy token"})
				return
			}
		} else {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "không tìm thấy token"})
			return
		}

		// Xác thực token
		claims, err := ValidateToken(tokenString)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			return
		}

		// Lưu thông tin user vào context
		c.Set("user_id", claims.UserID)
		if objectID, err := primitive.ObjectIDFromHex(claims.UserID); err == nil {
			c.Set("userID", objectID)
		}
		c.Next()
	}
}

// RequirePermission tạo middleware kiểm tra quyền
func RequirePermission(permission models.Permission) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Lấy user từ context
		user, exists := c.Get("user")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "không tìm thấy thông tin người dùng"})
			c.Abort()
			return
		}

		// Kiểm tra quyền
		u, ok := user.(*models.User)
		if !ok {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "lỗi định dạng thông tin người dùng"})
			c.Abort()
			return
		}

		if !u.HasPermission(permission) {
			c.JSON(http.StatusForbidden, gin.H{"error": "bạn không có quyền thực hiện hành động này"})
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequireRole tạo middleware kiểm tra role
func RequireRole(role models.Role) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Lấy user từ context
		user, exists := c.Get("user")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "không tìm thấy thông tin người dùng"})
			c.Abort()
			return
		}

		// Kiểm tra role
		u, ok := user.(*models.User)
		if !ok {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "lỗi định dạng thông tin người dùng"})
			c.Abort()
			return
		}

		if u.Role != role {
			c.JSON(http.StatusForbidden, gin.H{"error": "bạn không có quyền thực hiện hành động này"})
			c.Abort()
			return
		}

		c.Next()
	}
}
