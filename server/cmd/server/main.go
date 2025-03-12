package main

import (
	"context"
	"log"
	"os"
	"time"

	_ "github.com/duvu/xcaro/server/docs" // Import docs để swagger có thể đọc annotations
	"github.com/duvu/xcaro/server/internal/auth"
	"github.com/duvu/xcaro/server/internal/game"
	"github.com/duvu/xcaro/server/internal/models"
	"github.com/duvu/xcaro/server/internal/ws"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// @title XCaro Game API
// @version 1.0
// @description API cho game cờ caro online với tính năng chat và voice/video call.
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.url http://www.swagger.io/support
// @contact.email support@xcaro.com

// @license.name MIT
// @license.url https://opensource.org/licenses/MIT

// @host localhost:8080
// @BasePath /api
// @schemes http https

// @securityDefinitions.apikey ApiKeyAuth
// @in header
// @name Authorization

func init() {
	// Load các biến môi trường từ file .env
	if err := godotenv.Load(); err != nil {
		log.Printf("Không tìm thấy file .env: %v", err)
	}
}

func main() {
	// Kết nối MongoDB
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	mongoURI := os.Getenv("MONGODB_URI")
	if mongoURI == "" {
		log.Fatal("MONGODB_URI không được cấu hình")
	}

	client, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatal(err)
	}
	defer client.Disconnect(ctx)

	// Ping database để kiểm tra kết nối
	if err := client.Ping(ctx, nil); err != nil {
		log.Fatal(err)
	}

	// Khởi tạo database
	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "xcaro"
	}
	db := client.Database(dbName)

	// Khởi tạo các services và handlers
	authService := auth.NewService(db)
	authHandler := auth.NewHandler(authService)

	gameService := game.NewService(db)
	gameHandler := game.NewHandler(gameService)

	// Khởi tạo WebSocket hub
	hub := ws.NewHub()
	go hub.Run()
	wsHandler := ws.NewHandler(hub)

	// Khởi tạo router
	r := gin.Default()

	// Cấu hình CORS
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// API routes
	api := r.Group("/api")
	{
		// Swagger
		api.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

		// Health check
		api.GET("/health", func(c *gin.Context) {
			c.JSON(200, gin.H{
				"status": "ok",
			})
		})

		// Auth routes
		authGroup := api.Group("/auth")
		{
			authGroup.POST("/register", authHandler.Register)
			authGroup.POST("/login", authHandler.Login)
		}

		// Protected routes
		protected := api.Group("/")
		protected.Use(auth.AuthMiddleware())
		{
			// Profile routes
			profile := protected.Group("/profile")
			{
				profile.GET("", authHandler.GetProfile)
				profile.PUT("", authHandler.UpdateProfile)
				profile.PUT("/password", authHandler.ChangePassword)
				profile.PUT("/email", authHandler.UpdateEmail)
			}

			// Admin routes
			admin := protected.Group("/admin")
			admin.Use(auth.RequireRole(models.RoleAdmin))
			{
				users := admin.Group("/users")
				{
					users.GET("", authHandler.ListUsers)
					users.PUT("/:id/role", authHandler.UpdateRole)
					users.POST("/:id/ban", authHandler.BanUser)
					users.POST("/:id/unban", authHandler.UnbanUser)
				}
			}

			// Game routes
			games := protected.Group("/games")
			games.Use(auth.RequirePermission(models.PermCreateGame))
			{
				games.POST("", gameHandler.CreateGame)
				games.GET("/:id", gameHandler.GetGame)
				games.POST("/:id/join", gameHandler.JoinGame)
				games.POST("/:id/move", gameHandler.MakeMove)
			}

			// WebSocket endpoint
			api.GET("/ws", wsHandler.HandleWebSocket)
		}
	}

	// Lấy port từ biến môi trường hoặc dùng 8080 làm mặc định
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Khởi động server
	log.Printf("Server đang chạy tại http://localhost:%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Không thể khởi động server: %v", err)
	}
}
