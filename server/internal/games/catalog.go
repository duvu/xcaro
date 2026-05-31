package games

import (
	"strings"

	"github.com/gin-gonic/gin"
)

const GameTypeCaro = "caro"
const GameTypeChess = "chess"

type CatalogEntry struct {
	GameType        string `json:"game_type"`
	Name            string `json:"name"`
	Description     string `json:"description"`
	Status          string `json:"status"`
	MinPlayers      int    `json:"min_players"`
	MaxPlayers      int    `json:"max_players"`
	SupportsOnline  bool   `json:"supports_online"`
	SupportsOffline bool   `json:"supports_offline"`
	SupportsAI      bool   `json:"supports_ai"`
}

func DefaultCatalog() []CatalogEntry {
	return []CatalogEntry{
		{
			GameType:        GameTypeCaro,
			Name:            "Caro",
			Description:     "Caro 15x15 với chế độ online, offline và AI.",
			Status:          "active",
			MinPlayers:      1,
			MaxPlayers:      2,
			SupportsOnline:  true,
			SupportsOffline: true,
			SupportsAI:      true,
		},
		{
			GameType:        GameTypeChess,
			Name:            "Chess",
			Description:     "Cờ vua quốc tế với chế độ online, offline và AI.",
			Status:          "active",
			MinPlayers:      1,
			MaxPlayers:      2,
			SupportsOnline:  true,
			SupportsOffline: true,
			SupportsAI:      true,
		},
	}
}

func NormalizeGameType(gameType string) string {
	normalized := strings.TrimSpace(strings.ToLower(gameType))
	if normalized == "" {
		return GameTypeCaro
	}
	return normalized
}

func IsSupportedGameType(gameType string) bool {
	switch NormalizeGameType(gameType) {
	case GameTypeCaro, GameTypeChess:
		return true
	default:
		return false
	}
}

type Handler struct{}

func NewHandler() *Handler {
	return &Handler{}
}

func (h *Handler) GetCatalog(c *gin.Context) {
	c.JSON(200, gin.H{"games": DefaultCatalog()})
}
