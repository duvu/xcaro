package ws

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/duvu/xcaro/server/internal/cache"
	"github.com/duvu/xcaro/server/internal/elo"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

const boardSize = 15

type Room struct {
	ID               string
	Code             string
	PlayerX          *Client
	PlayerO          *Client
	Board            [boardSize][boardSize]int
	Turn             int
	Started          bool
	GameOver         bool
	Winner           string
	Result           string
	StartedAt        time.Time
	CreatedAt        time.Time
	LastActivity     time.Time
	Moves            []RoomMove
	mu               sync.Mutex
	disconnectTimers map[string]*time.Timer
	db               *mongo.Database
}

type RoomMove struct {
	X      int
	Y      int
	Player int
}

func NewRoom(id, code string, db *mongo.Database) *Room {
	return &Room{
		ID:               id,
		Code:             code,
		Turn:             1,
		CreatedAt:        time.Now(),
		LastActivity:     time.Now(),
		disconnectTimers: make(map[string]*time.Timer),
		db:               db,
	}
}

func (r *Room) MakeMove(userID string, x, y int) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.GameOver {
		return errors.New("game đã kết thúc")
	}
	if !r.Started {
		return errors.New("game chưa bắt đầu")
	}

	var player int
	if r.PlayerX != nil && r.PlayerX.UserID == userID {
		player = 1
	} else if r.PlayerO != nil && r.PlayerO.UserID == userID {
		player = 2
	} else {
		return errors.New("bạn không phải người chơi trong phòng này")
	}

	if r.Turn != player {
		return errors.New("chưa đến lượt của bạn")
	}

	if x < 0 || x >= boardSize || y < 0 || y >= boardSize {
		return errors.New("vị trí không hợp lệ")
	}
	if r.Board[x][y] != 0 {
		return errors.New("ô đã được đánh")
	}

	r.Board[x][y] = player
	r.Moves = append(r.Moves, RoomMove{X: x, Y: y, Player: player})
	r.LastActivity = time.Now()

	if r.CheckWin(player) {
		r.GameOver = true
		r.Winner = userID
		r.Result = "win"
		if r.db != nil {
			go r.saveGameRecord()
		}
		return nil
	}

	if r.IsDraw() {
		r.GameOver = true
		r.Winner = ""
		r.Result = "draw"
		if r.db != nil {
			go r.saveGameRecord()
		}
		return nil
	}

	if r.Turn == 1 {
		r.Turn = 2
	} else {
		r.Turn = 1
	}

	return nil
}

func (r *Room) CheckWin(player int) bool {
	dirs := [][2]int{{0, 1}, {1, 0}, {1, 1}, {1, -1}}
	for _, d := range dirs {
		dx, dy := d[0], d[1]
		for x := 0; x < boardSize; x++ {
			for y := 0; y < boardSize; y++ {
				if r.Board[x][y] != player {
					continue
				}
				count := 1
				for k := 1; k < 5; k++ {
					nx, ny := x+k*dx, y+k*dy
					if nx < 0 || nx >= boardSize || ny < 0 || ny >= boardSize {
						break
					}
					if r.Board[nx][ny] != player {
						break
					}
					count++
				}
				if count >= 5 {
					return true
				}
			}
		}
	}
	return false
}

func (r *Room) IsDraw() bool {
	for x := 0; x < boardSize; x++ {
		for y := 0; y < boardSize; y++ {
			if r.Board[x][y] == 0 {
				return false
			}
		}
	}
	return true
}

func (r *Room) ToGameState() map[string]interface{} {
	boardCopy := make([][]int, boardSize)
	for i := range boardCopy {
		row := make([]int, boardSize)
		copy(row, r.Board[i][:])
		boardCopy[i] = row
	}

	players := map[string]interface{}{}
	if r.PlayerX != nil {
		players["x"] = map[string]string{"user_id": r.PlayerX.UserID, "username": r.PlayerX.Username}
	}
	if r.PlayerO != nil {
		players["o"] = map[string]string{"user_id": r.PlayerO.UserID, "username": r.PlayerO.Username}
	}

	return map[string]interface{}{
		"room_id":   r.ID,
		"code":      r.Code,
		"board":     boardCopy,
		"turn":      r.Turn,
		"started":   r.Started,
		"game_over": r.GameOver,
		"winner":    r.Winner,
		"result":    r.Result,
		"players":   players,
	}
}

func (r *Room) GetOpponent(userID string) *Client {
	if r.PlayerX != nil && r.PlayerX.UserID == userID {
		return r.PlayerO
	}
	if r.PlayerO != nil && r.PlayerO.UserID == userID {
		return r.PlayerX
	}
	return nil
}

func (r *Room) PlayerCount() int {
	count := 0
	if r.PlayerX != nil {
		count++
	}
	if r.PlayerO != nil {
		count++
	}
	return count
}

func (r *Room) saveGameRecord() {
	if r.db == nil {
		return
	}
	playerXID := ""
	if r.PlayerX != nil {
		playerXID = r.PlayerX.UserID
	}
	playerOID := ""
	if r.PlayerO != nil {
		playerOID = r.PlayerO.UserID
	}

	duration := int64(0)
	if !r.StartedAt.IsZero() {
		duration = int64(time.Since(r.StartedAt).Seconds())
	}

	moves := make([]interface{}, 0, len(r.Moves))
	for _, m := range r.Moves {
		moves = append(moves, map[string]interface{}{
			"x": m.X, "y": m.Y, "player": m.Player,
		})
	}

	eloDeltaX := 0
	eloDeltaO := 0

	if r.Result != "resign" && r.Result != "forfeit" && playerXID != "" && playerOID != "" {
		eloDeltaX, eloDeltaO = r.updateEloRatings(playerXID, playerOID)
	}

	doc := map[string]interface{}{
		"player_x":    playerXID,
		"player_o":    playerOID,
		"winner":      r.Winner,
		"result":      r.Result,
		"moves":       moves,
		"duration":    duration,
		"elo_delta_x": eloDeltaX,
		"elo_delta_o": eloDeltaO,
		"created_at":  time.Now(),
	}
	_, _ = r.db.Collection("game_records").InsertOne(context.Background(), doc)
}

func (r *Room) updateEloRatings(playerXID, playerOID string) (deltaX, deltaO int) {
	ctx := context.Background()

	xObjID, err := primitive.ObjectIDFromHex(playerXID)
	if err != nil {
		return
	}
	oObjID, err := primitive.ObjectIDFromHex(playerOID)
	if err != nil {
		return
	}

	var userX, userO struct {
		EloRating int `bson:"elo_rating"`
	}
	if err := r.db.Collection("users").FindOne(ctx, bson.M{"_id": xObjID}).Decode(&userX); err != nil {
		return
	}
	if err := r.db.Collection("users").FindOne(ctx, bson.M{"_id": oObjID}).Decode(&userO); err != nil {
		return
	}

	ratingX := userX.EloRating
	ratingO := userO.EloRating
	if ratingX == 0 {
		ratingX = 1200
	}
	if ratingO == 0 {
		ratingO = 1200
	}

	var result float64
	if r.Winner == playerXID {
		result = 1.0
	} else if r.Winner == playerOID {
		result = 0.0
	} else {
		result = 0.5
	}

	newX, newO := elo.Calculate(ratingX, ratingO, result)
	deltaX = newX - ratingX
	deltaO = newO - ratingO

	r.db.Collection("users").UpdateOne(ctx, bson.M{"_id": xObjID}, bson.M{"$set": bson.M{"elo_rating": newX}})
	r.db.Collection("users").UpdateOne(ctx, bson.M{"_id": oObjID}, bson.M{"$set": bson.M{"elo_rating": newO}})

	cache.Del(ctx, "leaderboard:top50")
	cache.Del(ctx, "stats:"+playerXID)
	cache.Del(ctx, "stats:"+playerOID)

	return
}
