package models

import (
	"encoding/json"
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type GameStatus string

const (
	GameStatusWaiting  GameStatus = "waiting"  // Đang chờ người chơi thứ 2
	GameStatusPlaying  GameStatus = "playing"  // Đang chơi
	GameStatusFinished GameStatus = "finished" // Đã kết thúc
)

type Game struct {
	ID        primitive.ObjectID   `json:"id" bson:"_id,omitempty"`
	Player1ID primitive.ObjectID   `json:"player1_id" bson:"player1_id"`
	Player2ID primitive.ObjectID   `json:"player2_id,omitempty" bson:"player2_id,omitempty"`
	Board     [][]string          `json:"board" bson:"board"`         // Mảng 2 chiều lưu nước đi ("X", "O", hoặc "")
	Moves     []Move              `json:"moves" bson:"moves"`         // Lịch sử các nước đi
	Status    GameStatus          `json:"status" bson:"status"`       // Trạng thái game
	Winner    *primitive.ObjectID `json:"winner" bson:"winner"`       // ID người thắng (nếu có)
	NextTurn  primitive.ObjectID   `json:"next_turn" bson:"next_turn"` // ID người chơi tiếp theo
	CreatedAt time.Time           `json:"created_at" bson:"created_at"`
	UpdatedAt time.Time           `json:"updated_at" bson:"updated_at"`
}

type Move struct {
	PlayerID primitive.ObjectID `json:"player_id" bson:"player_id"`
	Row      int              `json:"row" bson:"row"`
	Col      int              `json:"col" bson:"col"`
	Symbol   string           `json:"symbol" bson:"symbol"` // "X" hoặc "O"
	Time     time.Time        `json:"time" bson:"time"`
}

type CreateGameRequest struct {
	Player1ID primitive.ObjectID `json:"player1_id" binding:"required"`
}

type JoinGameRequest struct {
	GameID    primitive.ObjectID `json:"game_id" binding:"required"`
	Player2ID primitive.ObjectID `json:"player2_id" binding:"required"`
}

type MakeMoveRequest struct {
	GameID   primitive.ObjectID `json:"game_id" binding:"required"`
	PlayerID primitive.ObjectID `json:"player_id" binding:"required"`
	Row      int              `json:"row" binding:"required"`
	Col      int              `json:"col" binding:"required"`
}

// GameStats thống kê về số trận thắng/thua/hòa của người dùng
type GameStats struct {
	UserID    string `json:"user_id" bson:"user_id"`
	Wins      int    `json:"wins" bson:"wins"`
	Losses    int    `json:"losses" bson:"losses"`
	Draws     int    `json:"draws" bson:"draws"`
	TotalGames int   `json:"total_games" bson:"total_games"`
	WinRate   float64 `json:"win_rate" bson:"win_rate"`
	CreatedAt time.Time `json:"created_at" bson:"created_at"`
	UpdatedAt time.Time `json:"updated_at" bson:"updated_at"`
}

// ListGamesRequest request cho việc lấy danh sách game
type ListGamesRequest struct {
	Status string `json:"status" form:"status"` // waiting/playing/finished
	Page   int    `json:"page" form:"page"`     // Số trang
	Limit  int    `json:"limit" form:"limit"`   // Số lượng game mỗi trang
}

// GetGameHistoryRequest request cho việc lấy lịch sử game
type GetGameHistoryRequest struct {
	UserID string `json:"user_id" form:"user_id" binding:"required"`
	Status string `json:"status" form:"status"` // waiting/playing/finished
	Page   int    `json:"page" form:"page"`     // Số trang
	Limit  int    `json:"limit" form:"limit"`   // Số lượng game mỗi trang
}

// GetGameStatsRequest request cho việc lấy thống kê game
type GetGameStatsRequest struct {
	UserID string `json:"user_id" form:"user_id" binding:"required"`
}

// String chuyển đổi game thành JSON string
func (g *Game) String() string {
	bytes, err := json.Marshal(g)
	if err != nil {
		return "{}"
	}
	return string(bytes)
} 