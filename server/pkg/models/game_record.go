package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type GameRecordMove struct {
	X      int `json:"x" bson:"x"`
	Y      int `json:"y" bson:"y"`
	Player int `json:"player" bson:"player"`
}

type GameRecordPlayer struct {
	UserID string `json:"user_id" bson:"user_id"`
	Seat   string `json:"seat" bson:"seat"`
}

type RatingChange struct {
	UserID string `json:"user_id" bson:"user_id"`
	Delta  int    `json:"delta" bson:"delta"`
}

type GameRecord struct {
	ID            primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	GameType      string             `json:"game_type" bson:"game_type"`
	RoomID        string             `json:"room_id,omitempty" bson:"room_id,omitempty"`
	PlayerX       string             `json:"player_x" bson:"player_x"`
	PlayerO       string             `json:"player_o" bson:"player_o"`
	Players       []GameRecordPlayer `json:"players,omitempty" bson:"players,omitempty"`
	Winner        string             `json:"winner" bson:"winner"`
	Result        string             `json:"result" bson:"result"`
	Moves         []GameRecordMove   `json:"moves" bson:"moves"`
	Duration      int64              `json:"duration" bson:"duration"`
	EloDeltaX     int                `json:"elo_delta_x" bson:"elo_delta_x"`
	EloDeltaO     int                `json:"elo_delta_o" bson:"elo_delta_o"`
	RatingChanges []RatingChange     `json:"rating_changes,omitempty" bson:"rating_changes,omitempty"`
	CreatedAt     time.Time          `json:"created_at" bson:"created_at"`
}

type GameRecordStats struct {
	Wins   int64 `json:"wins"`
	Losses int64 `json:"losses"`
	Draws  int64 `json:"draws"`
}
