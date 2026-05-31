package social

import (
	"context"
	"errors"
	"net/http"
	"regexp"
	"sort"
	"strings"
	"time"

	platformgames "github.com/duvu/playverse/server/internal/games"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Service struct {
	db *mongo.Database
}

func NewService(db *mongo.Database) *Service {
	return &Service{db: db}
}

func (s *Service) EnsureIndexes(ctx context.Context) error {
	_, err := s.db.Collection("friend_requests").Indexes().CreateMany(ctx, []mongo.IndexModel{
		{Keys: bson.D{{Key: "recipient_id", Value: 1}, {Key: "status", Value: 1}, {Key: "created_at", Value: -1}}},
		{Keys: bson.D{{Key: "requester_id", Value: 1}, {Key: "status", Value: 1}, {Key: "created_at", Value: -1}}},
		{Keys: bson.D{{Key: "pair_key", Value: 1}, {Key: "status", Value: 1}}, Options: options.Index().SetUnique(true).SetPartialFilterExpression(bson.M{"status": RequestStatusPending})},
	})
	if err != nil {
		return err
	}
	_, err = s.db.Collection("friendships").Indexes().CreateMany(ctx, []mongo.IndexModel{
		{Keys: bson.D{{Key: "pair_key", Value: 1}}, Options: options.Index().SetUnique(true)},
		{Keys: bson.D{{Key: "user_a", Value: 1}, {Key: "created_at", Value: -1}}},
		{Keys: bson.D{{Key: "user_b", Value: 1}, {Key: "created_at", Value: -1}}},
	})
	return err
}

type HistoryFilters struct {
	Page     int64
	Limit    int64
	GameType string
	Result   string
	Opponent string
	From     *time.Time
	To       *time.Time
}

func (s *Service) DashboardSummary(ctx context.Context, userID, gameType string) (*DashboardSummary, error) {
	gameType = platformgames.NormalizeGameType(gameType)
	profile, err := s.playerSummary(ctx, userID, userID)
	if err != nil {
		return nil, err
	}
	stats, err := s.stats(ctx, userID, gameType)
	if err != nil {
		return nil, err
	}
	recent, err := s.History(ctx, userID, HistoryFilters{Page: 1, Limit: 5, GameType: gameType})
	if err != nil {
		return nil, err
	}
	friendCount, err := s.db.Collection("friendships").CountDocuments(ctx, friendshipFilter(userID))
	if err != nil {
		return nil, err
	}
	incoming, err := s.db.Collection("friend_requests").CountDocuments(ctx, bson.M{"recipient_id": userID, "status": RequestStatusPending})
	if err != nil {
		return nil, err
	}
	outgoing, err := s.db.Collection("friend_requests").CountDocuments(ctx, bson.M{"requester_id": userID, "status": RequestStatusPending})
	if err != nil {
		return nil, err
	}
	return &DashboardSummary{Profile: profile, Stats: stats, RecentGames: recent.Games, FriendCount: friendCount, IncomingRequestCount: incoming, OutgoingRequestCount: outgoing}, nil
}

func (s *Service) History(ctx context.Context, userID string, filters HistoryFilters) (*HistoryResponse, error) {
	page, limit := normalizePageLimit(filters.Page, filters.Limit)
	match := bson.M{"$or": []bson.M{{"player_x": userID}, {"player_o": userID}}}
	match = mergeQuery(match, gameTypeFilter(filters.GameType))
	if filters.Opponent != "" {
		match["$or"] = []bson.M{{"player_x": userID, "player_o": filters.Opponent}, {"player_x": filters.Opponent, "player_o": userID}}
	}
	if filters.Result != "" {
		switch filters.Result {
		case "win":
			match["winner"] = userID
		case "loss":
			match["winner"] = bson.M{"$nin": []string{"", userID}}
			match["result"] = bson.M{"$ne": "draw"}
		case "draw":
			match["result"] = "draw"
		default:
			match["result"] = filters.Result
		}
	}
	if filters.From != nil || filters.To != nil {
		created := bson.M{}
		if filters.From != nil {
			created["$gte"] = *filters.From
		}
		if filters.To != nil {
			created["$lte"] = *filters.To
		}
		match["created_at"] = created
	}
	cursor, err := s.db.Collection("game_records").Find(ctx, match, options.Find().SetSort(bson.D{{Key: "created_at", Value: -1}}).SetSkip((page-1)*limit).SetLimit(limit+1))
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	records := make([]GameRecordDTO, 0)
	for cursor.Next(ctx) {
		var doc bson.M
		if err := cursor.Decode(&doc); err != nil {
			return nil, err
		}
		records = append(records, gameRecordDTO(userID, doc))
	}
	if err := cursor.Err(); err != nil {
		return nil, err
	}
	hasMore := int64(len(records)) > limit
	if hasMore {
		records = records[:limit]
	}
	return &HistoryResponse{Games: records, Page: page, Limit: limit, HasMore: hasMore}, nil
}

func (s *Service) SearchPlayers(ctx context.Context, currentUserID, query string, page, limit int64) ([]PlayerSummary, error) {
	page, limit = normalizePageLimit(page, limit)
	filter := bson.M{"_id": bson.M{"$ne": objectIDOrNil(currentUserID)}}
	if strings.TrimSpace(query) != "" {
		filter["username"] = primitive.Regex{Pattern: regexp.QuoteMeta(strings.TrimSpace(query)), Options: "i"}
	}
	cursor, err := s.db.Collection("users").Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "username", Value: 1}}).SetSkip((page-1)*limit).SetLimit(limit))
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	players := make([]PlayerSummary, 0)
	for cursor.Next(ctx) {
		var doc bson.M
		if err := cursor.Decode(&doc); err != nil {
			return nil, err
		}
		players = append(players, s.playerSummaryFromDoc(ctx, currentUserID, doc))
	}
	return players, cursor.Err()
}

func (s *Service) SendFriendRequest(ctx context.Context, requesterID, recipientID string) (*FriendRequestDTO, error) {
	if requesterID == recipientID {
		return nil, apiError(http.StatusBadRequest, "self_friend_request", "không thể kết bạn với chính mình")
	}
	if err := s.ensureUserExists(ctx, recipientID); err != nil {
		return nil, err
	}
	pair := pairKey(requesterID, recipientID)
	existingFriend, err := s.db.Collection("friendships").CountDocuments(ctx, bson.M{"pair_key": pair})
	if err != nil {
		return nil, err
	}
	if existingFriend > 0 {
		return nil, apiError(http.StatusConflict, "already_friends", "hai người chơi đã là bạn bè")
	}
	pending, err := s.db.Collection("friend_requests").CountDocuments(ctx, bson.M{"pair_key": pair, "status": RequestStatusPending})
	if err != nil {
		return nil, err
	}
	if pending > 0 {
		return nil, apiError(http.StatusConflict, "duplicate_request", "đã có lời mời kết bạn đang chờ xử lý")
	}
	now := time.Now()
	doc := bson.M{"requester_id": requesterID, "recipient_id": recipientID, "pair_key": pair, "status": RequestStatusPending, "created_at": now, "updated_at": now}
	result, err := s.db.Collection("friend_requests").InsertOne(ctx, doc)
	if mongo.IsDuplicateKeyError(err) {
		return nil, apiError(http.StatusConflict, "duplicate_request", "đã có lời mời kết bạn đang chờ xử lý")
	}
	if err != nil {
		return nil, err
	}
	doc["_id"] = result.InsertedID
	return s.friendRequestDTO(ctx, doc)
}

func (s *Service) ListRequests(ctx context.Context, userID, box string) ([]FriendRequestDTO, error) {
	filter := bson.M{"status": RequestStatusPending}
	if box == "outgoing" {
		filter["requester_id"] = userID
	} else {
		filter["recipient_id"] = userID
	}
	cursor, err := s.db.Collection("friend_requests").Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "created_at", Value: -1}}))
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	requests := make([]FriendRequestDTO, 0)
	for cursor.Next(ctx) {
		var doc bson.M
		if err := cursor.Decode(&doc); err != nil {
			return nil, err
		}
		dto, err := s.friendRequestDTO(ctx, doc)
		if err != nil {
			return nil, err
		}
		requests = append(requests, *dto)
	}
	return requests, cursor.Err()
}

func (s *Service) AcceptRequest(ctx context.Context, userID, requestID string) (*FriendshipDTO, error) {
	request, err := s.updateRequestStatus(ctx, userID, requestID, "recipient_id", RequestStatusAccepted)
	if err != nil {
		return nil, err
	}
	now := time.Now()
	friendship := bson.M{"user_a": minString(request.RequesterID, request.RecipientID), "user_b": maxString(request.RequesterID, request.RecipientID), "pair_key": pairKey(request.RequesterID, request.RecipientID), "created_at": now, "updated_at": now}
	_, err = s.db.Collection("friendships").UpdateOne(ctx, bson.M{"pair_key": friendship["pair_key"]}, bson.M{"$setOnInsert": friendship}, options.Update().SetUpsert(true))
	if err != nil {
		return nil, err
	}
	return s.friendshipDTO(ctx, userID, friendship)
}

func (s *Service) RejectRequest(ctx context.Context, userID, requestID string) error {
	_, err := s.updateRequestStatus(ctx, userID, requestID, "recipient_id", RequestStatusRejected)
	return err
}

func (s *Service) CancelRequest(ctx context.Context, userID, requestID string) error {
	_, err := s.updateRequestStatus(ctx, userID, requestID, "requester_id", RequestStatusCancelled)
	return err
}

func (s *Service) ListFriends(ctx context.Context, userID string) ([]FriendshipDTO, error) {
	cursor, err := s.db.Collection("friendships").Find(ctx, friendshipFilter(userID), options.Find().SetSort(bson.D{{Key: "created_at", Value: -1}}))
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	friends := make([]FriendshipDTO, 0)
	for cursor.Next(ctx) {
		var doc bson.M
		if err := cursor.Decode(&doc); err != nil {
			return nil, err
		}
		dto, err := s.friendshipDTO(ctx, userID, doc)
		if err != nil {
			return nil, err
		}
		friends = append(friends, *dto)
	}
	return friends, cursor.Err()
}

func (s *Service) RemoveFriend(ctx context.Context, userID, friendID string) error {
	result, err := s.db.Collection("friendships").DeleteOne(ctx, bson.M{"pair_key": pairKey(userID, friendID)})
	if err != nil {
		return err
	}
	if result.DeletedCount == 0 {
		return apiError(http.StatusNotFound, "friendship_not_found", "không tìm thấy quan hệ bạn bè")
	}
	return nil
}

func (s *Service) updateRequestStatus(ctx context.Context, userID, requestID, ownerField, status string) (*FriendRequestDTO, error) {
	id, err := primitive.ObjectIDFromHex(requestID)
	if err != nil {
		return nil, apiError(http.StatusBadRequest, "invalid_request_id", "mã lời mời không hợp lệ")
	}
	now := time.Now()
	result := s.db.Collection("friend_requests").FindOneAndUpdate(ctx, bson.M{"_id": id, ownerField: userID, "status": RequestStatusPending}, bson.M{"$set": bson.M{"status": status, "updated_at": now, "responded_at": now}}, options.FindOneAndUpdate().SetReturnDocument(options.After))
	var doc bson.M
	if err := result.Decode(&doc); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return nil, apiError(http.StatusNotFound, "request_not_found", "không tìm thấy lời mời đang chờ xử lý")
		}
		return nil, err
	}
	return s.friendRequestDTO(ctx, doc)
}

func (s *Service) stats(ctx context.Context, userID, gameType string) (GameStatsDTO, error) {
	query := mergeQuery(bson.M{"$or": []bson.M{{"player_x": userID}, {"player_o": userID}}}, gameTypeFilter(gameType))
	cursor, err := s.db.Collection("game_records").Find(ctx, query)
	if err != nil {
		return GameStatsDTO{}, err
	}
	defer cursor.Close(ctx)
	stats := GameStatsDTO{GameType: platformgames.NormalizeGameType(gameType), EloRating: 1200}
	for cursor.Next(ctx) {
		var doc bson.M
		if err := cursor.Decode(&doc); err != nil {
			return GameStatsDTO{}, err
		}
		result := stringValue(doc["result"])
		winner := stringValue(doc["winner"])
		switch {
		case result == "draw":
			stats.Draws++
		case winner == userID:
			stats.Wins++
		case winner != "":
			stats.Losses++
		}
	}
	if err := cursor.Err(); err != nil {
		return GameStatsDTO{}, err
	}
	if stats.GameType == platformgames.GameTypeCaro {
		profile, err := s.playerSummary(ctx, userID, userID)
		if err == nil {
			stats.EloRating = profile.EloRating
			stats.Rank = profile.Rank
		}
	} else {
		var ratingDoc bson.M
		if err := s.db.Collection("user_game_ratings").FindOne(ctx, bson.M{"user_id": userID, "game_type": stats.GameType}).Decode(&ratingDoc); err == nil {
			stats.EloRating = intValue(ratingDoc["rating"], 1200)
			rank, _ := s.db.Collection("user_game_ratings").CountDocuments(ctx, bson.M{"game_type": stats.GameType, "rating": bson.M{"$gt": stats.EloRating}})
			stats.Rank = rank + 1
		}
	}
	return stats, nil
}

func (s *Service) friendRequestDTO(ctx context.Context, doc bson.M) (*FriendRequestDTO, error) {
	requesterID := stringValue(doc["requester_id"])
	recipientID := stringValue(doc["recipient_id"])
	requester, err := s.playerSummary(ctx, requesterID, requesterID)
	if err != nil {
		return nil, err
	}
	recipient, err := s.playerSummary(ctx, requesterID, recipientID)
	if err != nil {
		return nil, err
	}
	return &FriendRequestDTO{ID: objectIDHex(doc["_id"]), Status: stringValue(doc["status"]), RequesterID: requesterID, RecipientID: recipientID, Requester: requester, Recipient: recipient, CreatedAt: timeValue(doc["created_at"]), UpdatedAt: timeValue(doc["updated_at"])}, nil
}

func (s *Service) friendshipDTO(ctx context.Context, currentUserID string, doc bson.M) (*FriendshipDTO, error) {
	friendID := stringValue(doc["user_a"])
	if friendID == currentUserID {
		friendID = stringValue(doc["user_b"])
	}
	friend, err := s.playerSummary(ctx, currentUserID, friendID)
	if err != nil {
		return nil, err
	}
	return &FriendshipDTO{Friend: friend, CreatedAt: timeValue(doc["created_at"])}, nil
}

func (s *Service) playerSummary(ctx context.Context, currentUserID, userID string) (PlayerSummary, error) {
	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return PlayerSummary{}, apiError(http.StatusBadRequest, "invalid_user_id", "mã người dùng không hợp lệ")
	}
	var doc bson.M
	if err := s.db.Collection("users").FindOne(ctx, bson.M{"_id": objectID}).Decode(&doc); err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return PlayerSummary{}, apiError(http.StatusNotFound, "user_not_found", "không tìm thấy người chơi")
		}
		return PlayerSummary{}, err
	}
	return s.playerSummaryFromDoc(ctx, currentUserID, doc), nil
}

func (s *Service) playerSummaryFromDoc(ctx context.Context, currentUserID string, doc bson.M) PlayerSummary {
	id := objectIDHex(doc["_id"])
	elo := intValue(doc["elo_rating"], 1200)
	rank, _ := s.db.Collection("users").CountDocuments(ctx, bson.M{"elo_rating": bson.M{"$gt": elo}})
	status, requestID := s.friendStatus(ctx, currentUserID, id)
	return PlayerSummary{ID: id, Username: stringValue(doc["username"]), Avatar: stringValue(doc["avatar"]), Bio: stringValue(doc["bio"]), EloRating: elo, Rank: rank + 1, FriendStatus: status, FriendRequestID: requestID}
}

func (s *Service) friendStatus(ctx context.Context, currentUserID, otherID string) (string, string) {
	if currentUserID == "" || currentUserID == otherID {
		return "self", ""
	}
	pair := pairKey(currentUserID, otherID)
	count, err := s.db.Collection("friendships").CountDocuments(ctx, bson.M{"pair_key": pair})
	if err == nil && count > 0 {
		return "friends", ""
	}
	var req bson.M
	err = s.db.Collection("friend_requests").FindOne(ctx, bson.M{"pair_key": pair, "status": RequestStatusPending}).Decode(&req)
	if err == nil {
		id := objectIDHex(req["_id"])
		if stringValue(req["requester_id"]) == currentUserID {
			return "pending_outgoing", id
		}
		return "pending_incoming", id
	}
	return "none", ""
}

func (s *Service) ensureUserExists(ctx context.Context, userID string) error {
	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return apiError(http.StatusBadRequest, "invalid_user_id", "mã người dùng không hợp lệ")
	}
	count, err := s.db.Collection("users").CountDocuments(ctx, bson.M{"_id": objectID})
	if err != nil {
		return err
	}
	if count == 0 {
		return apiError(http.StatusNotFound, "user_not_found", "không tìm thấy người chơi")
	}
	return nil
}

func gameRecordDTO(userID string, doc bson.M) GameRecordDTO {
	playerX := stringValue(doc["player_x"])
	playerO := stringValue(doc["player_o"])
	opponent := playerO
	if opponent == userID {
		opponent = playerX
	}
	result := stringValue(doc["result"])
	winner := stringValue(doc["winner"])
	outcome := "loss"
	if result == "draw" {
		outcome = "draw"
	} else if winner == userID {
		outcome = "win"
	} else if winner == "" {
		outcome = result
	}
	return GameRecordDTO{ID: objectIDHex(doc["_id"]), GameType: normalizedGameTypeFromDoc(doc), RoomID: stringValue(doc["room_id"]), Result: result, Winner: winner, Opponent: opponent, Outcome: outcome, CreatedAt: timeValue(doc["created_at"])}
}

func mergeQuery(base, extra bson.M) bson.M {
	if len(extra) == 0 {
		return base
	}
	if len(base) == 0 {
		return extra
	}
	return bson.M{"$and": []bson.M{base, extra}}
}

func gameTypeFilter(gameType string) bson.M {
	normalized := platformgames.NormalizeGameType(gameType)
	if normalized == platformgames.GameTypeCaro {
		return bson.M{"$or": []bson.M{{"game_type": normalized}, {"game_type": bson.M{"$exists": false}}}}
	}
	return bson.M{"game_type": normalized}
}

func normalizedGameTypeFromDoc(doc bson.M) string {
	return platformgames.NormalizeGameType(stringValue(doc["game_type"]))
}

func friendshipFilter(userID string) bson.M {
	return bson.M{"$or": []bson.M{{"user_a": userID}, {"user_b": userID}}}
}

func pairKey(a, b string) string {
	parts := []string{a, b}
	sort.Strings(parts)
	return strings.Join(parts, ":")
}

func minString(a, b string) string {
	if a < b {
		return a
	}
	return b
}

func maxString(a, b string) string {
	if a > b {
		return a
	}
	return b
}

func normalizePageLimit(page, limit int64) (int64, int64) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	return page, limit
}

func apiError(status int, code, message string) *APIError {
	return &APIError{Status: status, Code: code, Message: message}
}

func objectIDOrNil(id string) interface{} {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return primitive.NilObjectID
	}
	return objectID
}

func objectIDHex(value interface{}) string {
	switch v := value.(type) {
	case primitive.ObjectID:
		return v.Hex()
	case string:
		return v
	default:
		return ""
	}
}

func stringValue(value interface{}) string {
	if s, ok := value.(string); ok {
		return s
	}
	return ""
}

func intValue(value interface{}, fallback int) int {
	switch v := value.(type) {
	case int:
		return v
	case int32:
		return int(v)
	case int64:
		return int(v)
	case float64:
		return int(v)
	default:
		return fallback
	}
}

func timeValue(value interface{}) time.Time {
	if t, ok := value.(time.Time); ok {
		return t
	}
	return time.Time{}
}
