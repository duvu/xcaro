package game

import (
	"context"
	"errors"
	"time"

	"github.com/duvu/xcaro/server/internal/ws"
	"github.com/duvu/xcaro/server/pkg/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

const (
	BoardSize = 15 // Kích thước bàn cờ 15x15
)

type Service struct {
	db  *mongo.Database
	hub *ws.Hub
}

func NewService(db *mongo.Database, hub *ws.Hub) *Service {
	return &Service{
		db:  db,
		hub: hub,
	}
}

// broadcastGame gửi thông tin game đến tất cả clients trong game
func (s *Service) broadcastGame(game *models.Game) {
	s.hub.Broadcast(&ws.WSMessage{
		Type:    ws.EventGameState,
		RoomID:  game.ID.Hex(),
		Payload: game,
	})
}

func (s *Service) CreateGame(ctx context.Context, req *models.CreateGameRequest) (*models.Game, error) {
	// Tạo bàn cờ trống
	board := make([][]string, BoardSize)
	for i := range board {
		board[i] = make([]string, BoardSize)
	}

	// Tạo game mới
	now := time.Now()
	game := &models.Game{
		Player1ID: req.Player1ID,
		Board:     board,
		Moves:     []models.Move{},
		Status:    models.GameStatusWaiting,
		NextTurn:  req.Player1ID,
		CreatedAt: now,
		UpdatedAt: now,
	}

	// Lưu vào database
	result, err := s.db.Collection("games").InsertOne(ctx, game)
	if err != nil {
		return nil, err
	}

	game.ID = result.InsertedID.(primitive.ObjectID)
	return game, nil
}

func (s *Service) JoinGame(ctx context.Context, req *models.JoinGameRequest) (*models.Game, error) {
	// Tìm game
	var game models.Game
	err := s.db.Collection("games").FindOne(ctx, bson.M{
		"_id":    req.GameID,
		"status": models.GameStatusWaiting,
	}).Decode(&game)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("game không tồn tại hoặc đã đầy người chơi")
		}
		return nil, err
	}

	// Cập nhật game
	now := time.Now()
	update := bson.M{
		"$set": bson.M{
			"player2_id": req.Player2ID,
			"status":     models.GameStatusPlaying,
			"updated_at": now,
		},
	}

	err = s.db.Collection("games").FindOneAndUpdate(
		ctx,
		bson.M{"_id": req.GameID},
		update,
		options.FindOneAndUpdate().SetReturnDocument(options.After),
	).Decode(&game)

	if err != nil {
		return nil, err
	}

	// Broadcast thông tin game mới
	s.broadcastGame(&game)

	return &game, nil
}

func (s *Service) MakeMove(ctx context.Context, req *models.MakeMoveRequest) (*models.Game, error) {
	// Tìm game
	var game models.Game
	err := s.db.Collection("games").FindOne(ctx, bson.M{
		"_id":    req.GameID,
		"status": models.GameStatusPlaying,
	}).Decode(&game)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("game không tồn tại hoặc đã kết thúc")
		}
		return nil, err
	}

	// Kiểm tra lượt đi
	if game.NextTurn != req.PlayerID {
		return nil, errors.New("chưa đến lượt của bạn")
	}

	// Kiểm tra vị trí hợp lệ
	if req.Row < 0 || req.Row >= BoardSize || req.Col < 0 || req.Col >= BoardSize {
		return nil, errors.New("vị trí không hợp lệ")
	}
	if game.Board[req.Row][req.Col] != "" {
		return nil, errors.New("vị trí đã được đánh")
	}

	// Xác định ký hiệu (X/O) cho người chơi
	symbol := "O"
	if game.Player1ID == req.PlayerID {
		symbol = "X"
	}

	// Cập nhật bàn cờ
	game.Board[req.Row][req.Col] = symbol
	move := models.Move{
		PlayerID: req.PlayerID,
		Row:      req.Row,
		Col:      req.Col,
		Symbol:   symbol,
		Time:     time.Now(),
	}
	game.Moves = append(game.Moves, move)

	// Kiểm tra thắng/thua
	if s.checkWin(game.Board, req.Row, req.Col) {
		game.Status = models.GameStatusFinished
		game.Winner = &req.PlayerID
	} else {
		// Chuyển lượt
		if req.PlayerID == game.Player1ID {
			game.NextTurn = game.Player2ID
		} else {
			game.NextTurn = game.Player1ID
		}
	}

	// Cập nhật game trong database
	game.UpdatedAt = time.Now()
	err = s.db.Collection("games").FindOneAndReplace(
		ctx,
		bson.M{"_id": req.GameID},
		game,
	).Err()
	if err != nil {
		return nil, err
	}

	// Broadcast thông tin game mới
	s.broadcastGame(&game)

	return &game, nil
}

// checkWin kiểm tra xem có người thắng tại vị trí (row, col) không
func (s *Service) checkWin(board [][]string, row, col int) bool {
	symbol := board[row][col]
	count := 0

	// Kiểm tra hàng ngang
	for i := col - 4; i <= col+4; i++ {
		if i < 0 || i >= BoardSize {
			continue
		}
		if board[row][i] == symbol {
			count++
			if count == 5 {
				return true
			}
		} else {
			count = 0
		}
	}

	// Kiểm tra hàng dọc
	count = 0
	for i := row - 4; i <= row+4; i++ {
		if i < 0 || i >= BoardSize {
			continue
		}
		if board[i][col] == symbol {
			count++
			if count == 5 {
				return true
			}
		} else {
			count = 0
		}
	}

	// Kiểm tra đường chéo chính
	count = 0
	for i := -4; i <= 4; i++ {
		r, c := row+i, col+i
		if r < 0 || r >= BoardSize || c < 0 || c >= BoardSize {
			continue
		}
		if board[r][c] == symbol {
			count++
			if count == 5 {
				return true
			}
		} else {
			count = 0
		}
	}

	// Kiểm tra đường chéo phụ
	count = 0
	for i := -4; i <= 4; i++ {
		r, c := row+i, col-i
		if r < 0 || r >= BoardSize || c < 0 || c >= BoardSize {
			continue
		}
		if board[r][c] == symbol {
			count++
			if count == 5 {
				return true
			}
		} else {
			count = 0
		}
	}

	return false
}

func (s *Service) GetGame(ctx context.Context, gameID primitive.ObjectID) (*models.Game, error) {
	var game models.Game
	err := s.db.Collection("games").FindOne(ctx, bson.M{"_id": gameID}).Decode(&game)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("game không tồn tại")
		}
		return nil, err
	}
	return &game, nil
} 