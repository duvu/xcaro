package social

import "time"

const (
	RequestStatusPending   = "pending"
	RequestStatusAccepted  = "accepted"
	RequestStatusRejected  = "rejected"
	RequestStatusCancelled = "cancelled"
)

type APIError struct {
	Status  int
	Code    string
	Message string
}

func (e *APIError) Error() string { return e.Message }

type PlayerSummary struct {
	ID              string `json:"id"`
	Username        string `json:"username"`
	Avatar          string `json:"avatar,omitempty"`
	Bio             string `json:"bio,omitempty"`
	EloRating       int    `json:"elo_rating"`
	Rank            int64  `json:"rank"`
	FriendStatus    string `json:"friend_status"`
	FriendRequestID string `json:"friend_request_id,omitempty"`
}

type FriendRequestDTO struct {
	ID          string        `json:"id"`
	Status      string        `json:"status"`
	RequesterID string        `json:"requester_id"`
	RecipientID string        `json:"recipient_id"`
	Requester   PlayerSummary `json:"requester"`
	Recipient   PlayerSummary `json:"recipient"`
	CreatedAt   time.Time     `json:"created_at"`
	UpdatedAt   time.Time     `json:"updated_at"`
}

type FriendshipDTO struct {
	Friend    PlayerSummary `json:"friend"`
	CreatedAt time.Time     `json:"created_at"`
}

type GameRecordDTO struct {
	ID        string    `json:"id"`
	GameType  string    `json:"game_type"`
	RoomID    string    `json:"room_id"`
	Result    string    `json:"result"`
	Winner    string    `json:"winner,omitempty"`
	Opponent  string    `json:"opponent,omitempty"`
	Outcome   string    `json:"outcome"`
	CreatedAt time.Time `json:"created_at"`
}

type GameStatsDTO struct {
	GameType  string `json:"game_type"`
	Wins      int    `json:"wins"`
	Losses    int    `json:"losses"`
	Draws     int    `json:"draws"`
	EloRating int    `json:"elo_rating"`
	Rank      int64  `json:"rank"`
}

type DashboardSummary struct {
	Profile              PlayerSummary   `json:"profile"`
	Stats                GameStatsDTO    `json:"stats"`
	RecentGames          []GameRecordDTO `json:"recent_games"`
	FriendCount          int64           `json:"friend_count"`
	IncomingRequestCount int64           `json:"incoming_request_count"`
	OutgoingRequestCount int64           `json:"outgoing_request_count"`
}

type HistoryResponse struct {
	Games   []GameRecordDTO `json:"games"`
	Page    int64           `json:"page"`
	Limit   int64           `json:"limit"`
	HasMore bool            `json:"has_more"`
}
