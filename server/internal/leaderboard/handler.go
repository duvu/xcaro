package leaderboard

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/duvu/xcaro/server/internal/cache"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Handler struct {
	db *mongo.Database
}

func NewHandler(db *mongo.Database) *Handler {
	return &Handler{db: db}
}

type LeaderboardEntry struct {
	Rank        int    `json:"rank"`
	Username    string `json:"username"`
	Avatar      string `json:"avatar"`
	EloRating   int    `json:"elo_rating"`
	GamesPlayed int    `json:"games_played"`
}

func (h *Handler) GetLeaderboard(c *gin.Context) {
	ctx := context.Background()
	cacheKey := "leaderboard:top50"

	if cache.RedisClient != nil {
		if cached, err := cache.Get(ctx, cacheKey); err == nil {
			var entries []LeaderboardEntry
			if json.Unmarshal([]byte(cached), &entries) == nil {
				c.Header("X-Cache", "HIT")
				c.JSON(http.StatusOK, gin.H{"leaderboard": entries})
				return
			}
		}
	}

	opts := options.Find().SetSort(bson.D{{Key: "elo_rating", Value: -1}}).SetLimit(50)
	cursor, err := h.db.Collection("users").Find(ctx, bson.M{}, opts)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	defer cursor.Close(ctx)

	var entries []LeaderboardEntry
	rank := 1
	for cursor.Next(ctx) {
		var user bson.M
		cursor.Decode(&user)
		entry := LeaderboardEntry{
			Rank:      rank,
			Username:  getStr(user, "username"),
			Avatar:    getStr(user, "avatar"),
			EloRating: getInt(user, "elo_rating"),
		}
		if entry.EloRating == 0 {
			entry.EloRating = 1200
		}
		entries = append(entries, entry)
		rank++
	}

	if cache.RedisClient != nil {
		if data, err := json.Marshal(entries); err == nil {
			cache.Set(ctx, cacheKey, string(data), 5*time.Minute)
		}
	}

	c.Header("X-Cache", "MISS")
	c.JSON(200, gin.H{"leaderboard": entries})
}

func (h *Handler) GetUserProfile(c *gin.Context) {
	ctx := context.Background()
	idStr := c.Param("id")
	objectID, err := primitive.ObjectIDFromHex(idStr)
	if err != nil {
		c.JSON(400, gin.H{"error": "invalid user id"})
		return
	}

	var user bson.M
	if err := h.db.Collection("users").FindOne(ctx, bson.M{"_id": objectID}).Decode(&user); err != nil {
		c.JSON(404, gin.H{"error": "user not found"})
		return
	}

	wins, _ := h.db.Collection("game_records").CountDocuments(ctx, bson.M{"winner": idStr})
	totalPlayed, _ := h.db.Collection("game_records").CountDocuments(ctx, bson.M{
		"$or": []bson.M{{"player_x": idStr}, {"player_o": idStr}},
	})
	draws, _ := h.db.Collection("game_records").CountDocuments(ctx, bson.M{
		"result": "draw",
		"$or":    []bson.M{{"player_x": idStr}, {"player_o": idStr}},
	})
	losses := totalPlayed - wins - draws

	elo := getInt(user, "elo_rating")
	if elo == 0 {
		elo = 1200
	}
	rank, _ := h.db.Collection("users").CountDocuments(ctx, bson.M{"elo_rating": bson.M{"$gt": elo}})

	c.JSON(200, gin.H{
		"username":     getStr(user, "username"),
		"avatar":       getStr(user, "avatar"),
		"elo_rating":   elo,
		"rank":         rank + 1,
		"wins":         wins,
		"losses":       losses,
		"draws":        draws,
	})
}

func (h *Handler) UpdateAvatar(c *gin.Context) {
	ctx := context.Background()
	userID := c.GetString("user_id")
	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		c.JSON(400, gin.H{"error": "invalid user id"})
		return
	}

	var body struct {
		Avatar string `json:"avatar" binding:"required,url"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	_, err = h.db.Collection("users").UpdateOne(ctx, bson.M{"_id": objectID}, bson.M{
		"$set": bson.M{"avatar": body.Avatar},
	})
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	c.JSON(200, gin.H{"message": "avatar updated"})
}

func getStr(m bson.M, key string) string {
	if v, ok := m[key]; ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

func getInt(m bson.M, key string) int {
	if v, ok := m[key]; ok {
		switch n := v.(type) {
		case int:
			return n
		case int32:
			return int(n)
		case int64:
			return int(n)
		}
	}
	return 0
}
