package game

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
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

// ListGames lấy danh sách game với các bộ lọc
func (s *Service) ListGames(ctx context.Context, req *models.ListGamesRequest) ([]*models.Game, error) {
	// Xây dựng query
	query := bson.M{}
	if req.Status != "" {
		query["status"] = models.GameStatus(req.Status)
	}

	// Tính toán skip và limit cho phân trang
	skip := (req.Page - 1) * req.Limit
	if skip < 0 {
		skip = 0
	}
	if req.Limit <= 0 {
		req.Limit = 10 // Mặc định 10 game mỗi trang
	}

	// Thực hiện query
	cursor, err := s.db.Collection("games").Find(ctx, query, options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(req.Limit)).
		SetSort(bson.D{{"created_at", -1}}))
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var games []*models.Game
	if err := cursor.All(ctx, &games); err != nil {
		return nil, err
	}

	return games, nil
}

// GetGameHistory lấy lịch sử game của người dùng
func (s *Service) GetGameHistory(ctx context.Context, req *models.GetGameHistoryRequest) ([]*models.Game, error) {
	// Chuyển đổi userID sang ObjectID
	userID, err := primitive.ObjectIDFromHex(req.UserID)
	if err != nil {
		return nil, errors.New("user ID không hợp lệ")
	}

	// Xây dựng query
	query := bson.M{
		"$or": []bson.M{
			{"player1_id": userID},
			{"player2_id": userID},
		},
	}
	if req.Status != "" {
		query["status"] = models.GameStatus(req.Status)
	}

	// Tính toán skip và limit cho phân trang
	skip := (req.Page - 1) * req.Limit
	if skip < 0 {
		skip = 0
	}
	if req.Limit <= 0 {
		req.Limit = 10 // Mặc định 10 game mỗi trang
	}

	// Thực hiện query
	cursor, err := s.db.Collection("games").Find(ctx, query, options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(req.Limit)).
		SetSort(bson.D{{"created_at", -1}}))
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var games []*models.Game
	if err := cursor.All(ctx, &games); err != nil {
		return nil, err
	}

	return games, nil
}

// GetGameStats lấy thống kê game của người dùng
func (s *Service) GetGameStats(ctx context.Context, req *models.GetGameStatsRequest) (*models.GameStats, error) {
	// Chuyển đổi userID sang ObjectID
	userID, err := primitive.ObjectIDFromHex(req.UserID)
	if err != nil {
		return nil, errors.New("user ID không hợp lệ")
	}

	// Xây dựng pipeline cho aggregation
	pipeline := []bson.M{
		{
			"$match": bson.M{
				"$or": []bson.M{
					{"player1_id": userID},
					{"player2_id": userID},
				},
				"status": models.GameStatusFinished,
			},
		},
		{
			"$group": bson.M{
				"_id":         nil,
				"total_games": bson.M{"$sum": 1},
				"wins": bson.M{
					"$sum": bson.M{
						"$cond": []interface{}{
							bson.M{"$eq": []interface{}{"$winner", userID}},
							1,
							0,
						},
					},
				},
				"losses": bson.M{
					"$sum": bson.M{
						"$cond": []interface{}{
							bson.M{
								"$and": []bson.M{
									{"$ne": []interface{}{"$winner", nil}},
									{"$ne": []interface{}{"$winner", userID}},
								},
							},
							1,
							0,
						},
					},
				},
			},
		},
	}

	// Thực hiện aggregation
	cursor, err := s.db.Collection("games").Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var result []bson.M
	if err := cursor.All(ctx, &result); err != nil {
		return nil, err
	}

	// Xử lý kết quả
	stats := &models.GameStats{
		UserID:    req.UserID,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if len(result) > 0 {
		stats.TotalGames = int(result[0]["total_games"].(int32))
		stats.Wins = int(result[0]["wins"].(int32))
		stats.Losses = int(result[0]["losses"].(int32))
		stats.Draws = stats.TotalGames - stats.Wins - stats.Losses

		if stats.TotalGames > 0 {
			stats.WinRate = float64(stats.Wins) / float64(stats.TotalGames) * 100
		}
	}

	return stats, nil
}

// ReplayGame xem lại game đến một nước đi cụ thể
func (s *Service) ReplayGame(ctx context.Context, req *models.ReplayGameRequest) (*models.Game, error) {
	// Chuyển đổi gameID sang ObjectID
	gameID, err := primitive.ObjectIDFromHex(req.GameID)
	if err != nil {
		return nil, errors.New("game ID không hợp lệ")
	}

	// Lấy game từ database
	game, err := s.GetGame(ctx, gameID)
	if err != nil {
		return nil, err
	}

	// Tạo bản sao của game để replay
	replayGame := *game
	replayGame.Board = make([][]string, BoardSize)
	for i := range replayGame.Board {
		replayGame.Board[i] = make([]string, BoardSize)
	}

	// Áp dụng các nước đi đến bước được yêu cầu
	if req.Step > 0 && req.Step <= len(game.Moves) {
		for i := 0; i < req.Step; i++ {
			move := game.Moves[i]
			replayGame.Board[move.Row][move.Col] = move.Symbol
		}
		replayGame.Moves = game.Moves[:req.Step]
	}

	return &replayGame, nil
}

// GetLeaderboard lấy bảng xếp hạng người chơi
func (s *Service) GetLeaderboard(ctx context.Context) ([]*models.LeaderboardEntry, error) {
	// Pipeline để tính toán thống kê cho mỗi người chơi
	pipeline := []bson.M{
		{
			"$match": bson.M{
				"status": models.GameStatusFinished,
			},
		},
		{
			"$group": bson.M{
				"_id":        "$winner",
				"total_wins": bson.M{"$sum": 1},
				"total_games": bson.M{
					"$sum": bson.M{
						"$cond": []interface{}{
							bson.M{
								"$or": []bson.M{
									{"$eq": []interface{}{"$player1_id", "$winner"}},
									{"$eq": []interface{}{"$player2_id", "$winner"}},
								},
							},
							1,
							0,
						},
					},
				},
			},
		},
		{
			"$lookup": bson.M{
				"from":         "users",
				"localField":   "_id",
				"foreignField": "_id",
				"as":           "user",
			},
		},
		{
			"$unwind": "$user",
		},
		{
			"$project": bson.M{
				"user_id":    "$_id",
				"username":   "$user.username",
				"total_wins": 1,
				"win_rate": bson.M{
					"$multiply": []interface{}{
						bson.M{"$divide": []interface{}{"$total_wins", "$total_games"}},
						100,
					},
				},
			},
		},
		{
			"$sort": bson.M{"win_rate": -1, "total_wins": -1},
		},
	}

	// Thực hiện aggregation
	cursor, err := s.db.Collection("games").Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var entries []*models.LeaderboardEntry
	if err := cursor.All(ctx, &entries); err != nil {
		return nil, err
	}

	// Thêm rank cho mỗi entry
	for i, entry := range entries {
		entry.Rank = i + 1
	}

	return entries, nil
}

// SearchGames tìm kiếm game theo các tiêu chí
func (s *Service) SearchGames(ctx context.Context, req *models.SearchGamesRequest) ([]*models.Game, error) {
	// Xây dựng query
	query := bson.M{
		"created_at": bson.M{
			"$gte": req.StartDate,
			"$lte": req.EndDate,
		},
	}
	if req.Status != "" {
		query["status"] = models.GameStatus(req.Status)
	}

	// Tính toán skip và limit cho phân trang
	skip := (req.Page - 1) * req.Limit
	if skip < 0 {
		skip = 0
	}
	if req.Limit <= 0 {
		req.Limit = 10 // Mặc định 10 game mỗi trang
	}

	// Thực hiện query
	cursor, err := s.db.Collection("games").Find(ctx, query, options.Find().
		SetSkip(int64(skip)).
		SetLimit(int64(req.Limit)).
		SetSort(bson.D{{"created_at", -1}}))
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var games []*models.Game
	if err := cursor.All(ctx, &games); err != nil {
		return nil, err
	}

	return games, nil
}

// ExportGameHistory xuất lịch sử game
func (s *Service) ExportGameHistory(ctx context.Context, req *models.ExportHistoryRequest) ([]byte, error) {
	// Chuyển đổi userID sang ObjectID
	userID, err := primitive.ObjectIDFromHex(req.UserID)
	if err != nil {
		return nil, errors.New("user ID không hợp lệ")
	}

	// Xây dựng query
	query := bson.M{
		"$or": []bson.M{
			{"player1_id": userID},
			{"player2_id": userID},
		},
		"created_at": bson.M{
			"$gte": req.StartDate,
			"$lte": req.EndDate,
		},
	}

	// Lấy tất cả game trong khoảng thời gian
	cursor, err := s.db.Collection("games").Find(ctx, query, options.Find().
		SetSort(bson.D{{"created_at", -1}}))
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var games []*models.Game
	if err := cursor.All(ctx, &games); err != nil {
		return nil, err
	}

	// Chuyển đổi sang định dạng yêu cầu
	switch req.Format {
	case "json":
		return json.Marshal(games)
	case "csv":
		// Tạo CSV header
		var csvData strings.Builder
		csvData.WriteString("Game ID,Player 1,Player 2,Winner,Status,Created At,Updated At\n")

		// Thêm dữ liệu
		for _, game := range games {
			winner := "None"
			if game.Winner != nil {
				winner = game.Winner.Hex()
			}
			csvData.WriteString(fmt.Sprintf("%s,%s,%s,%s,%s,%s,%s\n",
				game.ID.Hex(),
				game.Player1ID.Hex(),
				game.Player2ID.Hex(),
				winner,
				game.Status,
				game.CreatedAt.Format(time.RFC3339),
				game.UpdatedAt.Format(time.RFC3339),
			))
		}
		return []byte(csvData.String()), nil
	default:
		return nil, errors.New("định dạng không được hỗ trợ")
	}
}
