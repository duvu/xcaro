package game

import "github.com/gin-gonic/gin"

// RegisterRoutes đăng ký các route cho game
func (h *Handler) RegisterRoutes(r *gin.RouterGroup) {
	games := r.Group("/games")
	{
		games.POST("", h.CreateGame)
		games.GET("/:id", h.GetGame)
		games.POST("/:id/join", h.JoinGame)
		games.POST("/:id/move", h.MakeMove)
		games.GET("/history", h.GetGameHistory)
		games.GET("/stats", h.GetGameStats)
		games.GET("/:id/replay", h.ReplayGame)
		games.GET("/leaderboard", h.GetLeaderboard)
		games.GET("/search", h.SearchGames)
		games.GET("/export", h.ExportGameHistory)
	}
}
