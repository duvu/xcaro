package models

import (
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