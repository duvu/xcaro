package ws

import (
	"context"
	"sync"
	"time"

	"github.com/duvu/playverse/server/internal/cache"
	"github.com/duvu/playverse/server/internal/elo"
	platformgames "github.com/duvu/playverse/server/internal/games"
	"github.com/duvu/playverse/server/internal/games/caro"
	chessgame "github.com/duvu/playverse/server/internal/games/chess"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Room struct {
	ID               string
	Code             string
	GameType         string
	PlayerX          *Client
	PlayerO          *Client
	Board            [caro.BoardSize][caro.BoardSize]int
	FEN              string
	WinningCells     [][]int
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
	X         int
	Y         int
	Player    int
	From      string
	To        string
	Promotion string
}

type RoomError struct {
	Code    string
	Message string
}

type gameRecordSnapshot struct {
	GameType  string
	RoomID    string
	FEN       string
	PlayerXID string
	PlayerOID string
	Winner    string
	Result    string
	Moves     []RoomMove
	Duration  int64
}

func (e RoomError) Error() string {
	return e.Message
}

func roomError(code, message string) error {
	return RoomError{Code: code, Message: message}
}

func NewRoom(id, code, gameType string, db *mongo.Database) *Room {
	gt := platformgames.NormalizeGameType(gameType)
	fen := ""
	if gt == platformgames.GameTypeChess {
		fen = chessgame.StartingFEN
	}
	return &Room{
		ID:               id,
		Code:             code,
		GameType:         gt,
		FEN:              fen,
		Turn:             1,
		CreatedAt:        time.Now(),
		LastActivity:     time.Now(),
		disconnectTimers: make(map[string]*time.Timer),
		db:               db,
	}
}

func (r *Room) MakeMove(userID string, x, y int) error {
	_, _, err := r.ApplyCaroMove(userID, x, y)
	return err
}

func (r *Room) MakeChessMove(userID, from, to, promotion string) error {
	_, _, err := r.ApplyChessMove(userID, from, to, promotion)
	return err
}

func (r *Room) ApplyMove(userID string, x, y int) (map[string]interface{}, bool, error) {
	return r.ApplyCaroMove(userID, x, y)
}

func (r *Room) ApplyCaroMove(userID string, x, y int) (map[string]interface{}, bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.GameOver {
		return nil, false, roomError("game_already_over", "Game is already over")
	}
	if !r.Started {
		return nil, false, roomError("game_not_started", "Game has not started")
	}

	var player int
	if r.PlayerX != nil && r.PlayerX.UserID == userID {
		player = 1
	} else if r.PlayerO != nil && r.PlayerO.UserID == userID {
		player = 2
	} else {
		return nil, false, roomError("not_a_player", "You are not a player in this room")
	}

	if r.Turn != player {
		return nil, false, roomError("not_your_turn", "It is not your turn")
	}

	outcome, err := caro.ApplyMove(&r.Board, player, x, y)
	if err != nil {
		switch err {
		case caro.ErrInvalidCoordinates:
			return nil, false, roomError("invalid_coordinates", "Move coordinates are outside the board")
		case caro.ErrCellOccupied:
			return nil, false, roomError("cell_occupied", "Cell is already occupied")
		default:
			return nil, false, err
		}
	}

	r.Moves = append(r.Moves, RoomMove{X: x, Y: y, Player: player})
	r.LastActivity = time.Now()
	r.WinningCells = outcome.WinningCells

	if len(outcome.WinningCells) > 0 {
		r.GameOver = true
		r.Winner = userID
		r.Result = "win"
		state := r.toGameStateLocked()
		r.saveCompletedGameLocked()
		return state, true, nil
	}

	if outcome.Draw {
		r.GameOver = true
		r.Winner = ""
		r.Result = "draw"
		state := r.toGameStateLocked()
		r.saveCompletedGameLocked()
		return state, true, nil
	}

	if r.Turn == 1 {
		r.Turn = 2
	} else {
		r.Turn = 1
	}

	return r.toGameStateLocked(), false, nil
}

func (r *Room) ApplyChessMove(userID, from, to, promotion string) (map[string]interface{}, bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.GameOver {
		return nil, false, roomError("game_already_over", "Game is already over")
	}
	if !r.Started {
		return nil, false, roomError("game_not_started", "Game has not started")
	}

	var player int
	if r.PlayerX != nil && r.PlayerX.UserID == userID {
		player = 1
	} else if r.PlayerO != nil && r.PlayerO.UserID == userID {
		player = 2
	} else {
		return nil, false, roomError("not_a_player", "You are not a player in this room")
	}

	if r.Turn != player {
		return nil, false, roomError("not_your_turn", "It is not your turn")
	}

	outcome, err := chessgame.ApplyMove(r.FEN, from, to, promotion)
	if err != nil {
		switch err {
		case chessgame.ErrInvalidSquare:
			return nil, false, roomError("invalid_coordinates", "Invalid chess square")
		case chessgame.ErrIllegalMove:
			return nil, false, roomError("illegal_move", "That move is not legal in the current position")
		default:
			return nil, false, err
		}
	}

	r.FEN = outcome.NewFEN
	r.Moves = append(r.Moves, RoomMove{From: from, To: to, Promotion: promotion, Player: player})
	r.LastActivity = time.Now()

	if r.Turn == 1 {
		r.Turn = 2
	} else {
		r.Turn = 1
	}

	if outcome.GameOver {
		r.GameOver = true
		r.Result = outcome.Result
		if outcome.Winner == "white" {
			if r.PlayerX != nil {
				r.Winner = r.PlayerX.UserID
			}
		} else if outcome.Winner == "black" {
			if r.PlayerO != nil {
				r.Winner = r.PlayerO.UserID
			}
		}
		state := r.toGameStateLocked()
		r.saveCompletedGameLocked()
		return state, true, nil
	}

	return r.toGameStateLocked(), false, nil
}

func (r *Room) ToGameState() map[string]interface{} {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.toGameStateLocked()
}

func (r *Room) toGameStateLocked() map[string]interface{} {
	playerX := playerPayload(r.PlayerX)
	playerO := playerPayload(r.PlayerO)
	players := map[string]interface{}{"x": playerX, "o": playerO}

	currentTurn := ""
	if r.Turn == 1 && r.PlayerX != nil {
		currentTurn = r.PlayerX.UserID
	} else if r.Turn == 2 && r.PlayerO != nil {
		currentTurn = r.PlayerO.UserID
	}

	winningCells := r.WinningCells
	if winningCells == nil {
		winningCells = make([][]int, 0)
	}

	status := "waiting"
	if r.GameOver {
		status = "finished"
	} else if r.Started {
		status = "active"
	}

	state := map[string]interface{}{
		"game_type":     r.GameType,
		"room_id":       r.ID,
		"room_code":     r.Code,
		"code":          r.Code,
		"turn":          r.Turn,
		"current_turn":  currentTurn,
		"started":       r.Started,
		"game_over":     r.GameOver,
		"winner":        r.Winner,
		"result":        r.Result,
		"status":        status,
		"players":       players,
		"player_x":      playerX,
		"player_o":      playerO,
		"winning_cells": winningCells,
	}

	if r.GameType == platformgames.GameTypeChess {
		state["fen"] = r.FEN
	} else {
		boardCopy := make([][]int, caro.BoardSize)
		for i := range boardCopy {
			row := make([]int, caro.BoardSize)
			copy(row, r.Board[i][:])
			boardCopy[i] = row
		}
		state["board"] = boardCopy
	}

	return state
}

func playerPayload(client *Client) map[string]string {
	if client == nil {
		return nil
	}
	username := client.Username
	if username == "" {
		username = client.UserID
	}
	return map[string]string{"user_id": client.UserID, "username": username}
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
	r.mu.Lock()
	snapshot := r.gameRecordSnapshotLocked()
	r.mu.Unlock()
	r.saveGameRecordSnapshot(snapshot)
}

func (r *Room) saveCompletedGameLocked() {
	if r.db == nil {
		return
	}
	snapshot := r.gameRecordSnapshotLocked()
	go r.saveGameRecordSnapshot(snapshot)
}

func (r *Room) gameRecordSnapshotLocked() gameRecordSnapshot {
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
	moves := make([]RoomMove, len(r.Moves))
	copy(moves, r.Moves)

	return gameRecordSnapshot{
		GameType:  r.GameType,
		RoomID:    r.ID,
		FEN:       r.FEN,
		PlayerXID: playerXID,
		PlayerOID: playerOID,
		Winner:    r.Winner,
		Result:    r.Result,
		Moves:     moves,
		Duration:  duration,
	}
}

func (r *Room) saveGameRecordSnapshot(snapshot gameRecordSnapshot) {
	if r.db == nil {
		return
	}

	moves := make([]interface{}, 0, len(snapshot.Moves))
	for _, m := range snapshot.Moves {
		if snapshot.GameType == platformgames.GameTypeChess {
			moves = append(moves, map[string]interface{}{
				"from": m.From, "to": m.To, "promotion": m.Promotion, "player": m.Player,
			})
		} else {
			moves = append(moves, map[string]interface{}{
				"x": m.X, "y": m.Y, "player": m.Player,
			})
		}
	}

	eloDeltaX := 0
	eloDeltaO := 0

	if snapshot.PlayerXID != "" && snapshot.PlayerOID != "" {
		eloDeltaX, eloDeltaO = r.updateEloRatings(snapshot.PlayerXID, snapshot.PlayerOID, snapshot.Winner)
	}

	doc := map[string]interface{}{
		"game_type": snapshot.GameType,
		"room_id":   snapshot.RoomID,
		"player_x":  snapshot.PlayerXID,
		"player_o":  snapshot.PlayerOID,
		"players": []map[string]interface{}{
			{"user_id": snapshot.PlayerXID, "seat": "x"},
			{"user_id": snapshot.PlayerOID, "seat": "o"},
		},
		"winner":      snapshot.Winner,
		"result":      snapshot.Result,
		"moves":       moves,
		"duration":    snapshot.Duration,
		"elo_delta_x": eloDeltaX,
		"elo_delta_o": eloDeltaO,
		"rating_changes": []map[string]interface{}{
			{"user_id": snapshot.PlayerXID, "delta": eloDeltaX},
			{"user_id": snapshot.PlayerOID, "delta": eloDeltaO},
		},
		"created_at": time.Now(),
	}
	if snapshot.FEN != "" {
		doc["final_fen"] = snapshot.FEN
	}
	_, _ = r.db.Collection("game_records").InsertOne(context.Background(), doc)
}

func (r *Room) updateEloRatings(playerXID, playerOID, winner string) (deltaX, deltaO int) {
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
	if winner == playerXID {
		result = 1.0
	} else if winner == playerOID {
		result = 0.0
	} else {
		result = 0.5
	}

	newX, newO := elo.Calculate(ratingX, ratingO, result)
	deltaX = newX - ratingX
	deltaO = newO - ratingO

	r.db.Collection("users").UpdateOne(ctx, bson.M{"_id": xObjID}, bson.M{"$set": bson.M{"elo_rating": newX}})
	r.db.Collection("users").UpdateOne(ctx, bson.M{"_id": oObjID}, bson.M{"$set": bson.M{"elo_rating": newO}})
	r.db.Collection("user_game_ratings").UpdateOne(ctx, bson.M{"user_id": playerXID, "game_type": r.GameType}, bson.M{"$set": bson.M{"rating": newX, "updated_at": time.Now()}, "$setOnInsert": bson.M{"user_id": playerXID, "game_type": r.GameType}}, options.Update().SetUpsert(true))
	r.db.Collection("user_game_ratings").UpdateOne(ctx, bson.M{"user_id": playerOID, "game_type": r.GameType}, bson.M{"$set": bson.M{"rating": newO, "updated_at": time.Now()}, "$setOnInsert": bson.M{"user_id": playerOID, "game_type": r.GameType}}, options.Update().SetUpsert(true))

	cache.Del(ctx, "leaderboard:top50")
	cache.Del(ctx, "leaderboard:top50:"+r.GameType)
	cache.Del(ctx, "stats:"+playerXID)
	cache.Del(ctx, "stats:"+playerOID)

	return
}
