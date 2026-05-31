package ws

import (
	"context"
	"errors"
	"log/slog"
	"math/rand"
	"sync"
	"time"

	platformgames "github.com/duvu/playverse/server/internal/games"
	"github.com/duvu/playverse/server/internal/metrics"
	"github.com/duvu/playverse/server/pkg/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

type Hub struct {
	clients    map[*Client]bool
	rooms      map[string]map[*Client]bool
	gameRooms  map[string]*Room
	codes      map[string]*Room
	matchQueue []*Client
	broadcast  chan *WSMessage
	register   chan *Client
	unregister chan *Client
	mu         sync.RWMutex
	db         *mongo.Database
}

func NewHub() *Hub {
	return &Hub{
		broadcast:  make(chan *WSMessage),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		clients:    make(map[*Client]bool),
		rooms:      make(map[string]map[*Client]bool),
		gameRooms:  make(map[string]*Room),
		codes:      make(map[string]*Room),
	}
}

func NewHubWithDB(db *mongo.Database) *Hub {
	h := NewHub()
	h.db = db
	return h
}

func (h *Hub) Run() {
	go h.cleanupExpiredRooms()

	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client] = true
			h.mu.Unlock()
			metrics.Get().IncConnections()

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
			}
			h.mu.Unlock()
			metrics.Get().DecConnections()
			h.handleClientDisconnect(client)

		case message := <-h.broadcast:
			h.mu.Lock()
			for client := range h.clients {
				if client.CurrentRoom == message.RoomID {
					select {
					case client.send <- message:
					default:
						close(client.send)
						delete(h.clients, client)
					}
				}
			}
			h.mu.Unlock()
		}
	}
}

func (h *Hub) Register(client *Client) {
	h.register <- client
}

func (h *Hub) Broadcast(message *WSMessage) {
	select {
	case h.broadcast <- message:
	default:
		slog.Warn("broadcast channel full")
	}
}

func (h *Hub) sendError(client *Client, code, message string) {
	client.Send(&WSMessage{
		Type:    EventError,
		Payload: ErrorPayload{Code: code, Message: message},
	})
}

func (h *Hub) JoinRoom(roomID string, client *Client) {
	h.mu.Lock()

	if h.rooms[roomID] == nil {
		h.rooms[roomID] = make(map[*Client]bool)
	}
	h.rooms[roomID][client] = true
	h.mu.Unlock()

	h.BroadcastToRoom(roomID, &WSMessage{
		Type:   EventPlayerJoin,
		RoomID: roomID,
		Payload: map[string]interface{}{
			"user_id": client.UserID,
		},
	})
}

func (h *Hub) LeaveRoom(roomID string, client *Client) {
	h.mu.Lock()

	leftRoom := false
	if room, ok := h.rooms[roomID]; ok {
		delete(room, client)
		leftRoom = true
	}
	h.mu.Unlock()

	if leftRoom {
		h.BroadcastToRoom(roomID, &WSMessage{
			Type:   EventPlayerLeave,
			RoomID: roomID,
			Payload: map[string]interface{}{
				"user_id": client.UserID,
			},
		})
	}
}

func (h *Hub) GetClientCount(roomID string) int {
	h.mu.RLock()
	defer h.mu.RUnlock()

	return len(h.rooms[roomID])
}

func (h *Hub) BroadcastToRoom(roomID string, message *WSMessage) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if room, ok := h.rooms[roomID]; ok {
		for client := range room {
			select {
			case client.send <- message:
			default:
				close(client.send)
				delete(room, client)
			}
		}
	}
}

func (h *Hub) HandleCreateRoom(client *Client, gameType string) {
	gameType = platformgames.NormalizeGameType(gameType)
	if !platformgames.IsSupportedGameType(gameType) {
		h.sendError(client, "unsupported_game_type", "Game type is not supported yet")
		return
	}
	if !h.isEmailVerified(client) {
		h.sendError(client, "email_not_verified", "Please verify your email to play online")
		return
	}

	code := generateRoomCode()
	h.mu.Lock()
	for {
		if _, exists := h.codes[code]; !exists {
			break
		}
		code = generateRoomCode()
	}

	room := NewRoom(code, code, gameType, h.db)
	room.mu.Lock()
	room.PlayerX = client
	state := room.toGameStateLocked()
	room.mu.Unlock()
	h.gameRooms[room.ID] = room
	h.codes[code] = room
	h.mu.Unlock()
	metrics.Get().IncGames()

	client.GameRoomID = room.ID
	client.CurrentRoom = room.ID
	client.Send(&WSMessage{
		Type:     EventGameState,
		GameType: room.GameType,
		RoomID:   room.ID,
		Payload:  state,
	})
}

func (h *Hub) HandleJoinRoom(client *Client, code, gameType string) {
	gameType = platformgames.NormalizeGameType(gameType)
	if !platformgames.IsSupportedGameType(gameType) {
		h.sendError(client, "unsupported_game_type", "Game type is not supported yet")
		return
	}
	if !h.isEmailVerified(client) {
		h.sendError(client, "email_not_verified", "Please verify your email to play online")
		return
	}

	h.mu.Lock()

	if code == "" {
		h.mu.Unlock()
		h.HandleCreateRoom(client, gameType)
		return
	}

	room, exists := h.codes[code]
	if !exists {
		h.mu.Unlock()
		h.sendError(client, "room_not_found", "Room not found")
		return
	}
	room.mu.Lock()
	if room.PlayerX == nil {
		room.mu.Unlock()
		h.mu.Unlock()
		h.sendError(client, "room_not_found", "Room not found")
		return
	}
	if room.GameType != gameType {
		room.mu.Unlock()
		h.mu.Unlock()
		h.sendError(client, "game_type_mismatch", "Requested game type does not match the room")
		return
	}

	bothFull := room.PlayerO != nil && room.PlayerX != nil
	if bothFull {
		isPlayerX := room.PlayerX.UserID == client.UserID
		isPlayerO := room.PlayerO.UserID == client.UserID
		room.mu.Unlock()
		if !isPlayerX && !isPlayerO {
			h.mu.Unlock()
			h.sendError(client, "room_full", "Room is full")
			return
		}
		h.mu.Unlock()
		h.handleRejoin(client, room)
		return
	}

	if room.PlayerX != nil && room.PlayerX.UserID == client.UserID {
		state := room.toGameStateLocked()
		room.mu.Unlock()
		h.mu.Unlock()
		client.GameRoomID = room.ID
		client.CurrentRoom = room.ID
		client.Send(&WSMessage{Type: EventGameState, GameType: room.GameType, RoomID: room.ID, Payload: state})
		return
	}
	if room.PlayerO != nil && room.PlayerO.UserID == client.UserID {
		room.mu.Unlock()
		h.mu.Unlock()
		h.handleRejoin(client, room)
		return
	}

	room.PlayerO = client
	client.GameRoomID = room.ID
	client.CurrentRoom = room.ID

	if room.PlayerX != nil && room.PlayerO != nil {
		room.Started = true
		room.StartedAt = time.Now()
	}
	state := room.toGameStateLocked()
	room.mu.Unlock()
	h.mu.Unlock()

	h.broadcastGameState(room, state)
}

func (h *Hub) HandleRejoinRoom(client *Client, roomID, code string) {
	h.mu.RLock()
	var room *Room
	if roomID != "" {
		room = h.gameRooms[roomID]
	}
	if room == nil && code != "" {
		room = h.codes[code]
	}
	h.mu.RUnlock()

	if room == nil {
		h.sendError(client, "room_not_found", "Room not found")
		return
	}

	room.mu.Lock()
	isPlayerX := room.PlayerX != nil && room.PlayerX.UserID == client.UserID
	isPlayerO := room.PlayerO != nil && room.PlayerO.UserID == client.UserID
	room.mu.Unlock()
	if !isPlayerX && !isPlayerO {
		h.sendError(client, "not_a_player", "You are not a player in this room")
		return
	}

	h.handleRejoin(client, room)
}

func (h *Hub) handleRejoin(client *Client, room *Room) {
	room.mu.Lock()
	if room.PlayerX != nil && room.PlayerX.UserID == client.UserID {
		room.PlayerX = client
	} else if room.PlayerO != nil && room.PlayerO.UserID == client.UserID {
		room.PlayerO = client
	}
	room.LastActivity = time.Now()

	if timer, ok := room.disconnectTimers[client.UserID]; ok {
		timer.Stop()
		delete(room.disconnectTimers, client.UserID)
	}
	state := room.toGameStateLocked()
	room.mu.Unlock()

	client.GameRoomID = room.ID
	client.CurrentRoom = room.ID
	client.Send(&WSMessage{Type: EventGameState, RoomID: room.ID, Payload: state})
}

func (h *Hub) HandleMakeMove(client *Client, x, y int) {
	h.mu.RLock()
	room, ok := h.gameRooms[client.GameRoomID]
	h.mu.RUnlock()

	if !ok {
		h.sendError(client, "no_active_game", "Not in an active game")
		return
	}

	state, gameOver, err := room.ApplyCaroMove(client.UserID, x, y)
	if err != nil {
		var roomErr RoomError
		if errors.As(err, &roomErr) {
			h.sendError(client, roomErr.Code, roomErr.Message)
		} else {
			h.sendError(client, "move_rejected", err.Error())
		}
		return
	}
	metrics.Get().IncMoves()

	if gameOver {
		h.broadcastToGameRoom(room, &WSMessage{
			Type:     EventGameOver,
			GameType: room.GameType,
			RoomID:   room.ID,
			Payload:  state,
		})
	} else {
		h.broadcastGameState(room, state)
	}
}

func (h *Hub) HandleChessMakeMove(client *Client, from, to, promotion string) {
	h.mu.RLock()
	room, ok := h.gameRooms[client.GameRoomID]
	h.mu.RUnlock()

	if !ok {
		h.sendError(client, "no_active_game", "Not in an active game")
		return
	}

	state, gameOver, err := room.ApplyChessMove(client.UserID, from, to, promotion)
	if err != nil {
		var roomErr RoomError
		if errors.As(err, &roomErr) {
			h.sendError(client, roomErr.Code, roomErr.Message)
		} else {
			h.sendError(client, "move_rejected", err.Error())
		}
		return
	}
	metrics.Get().IncMoves()

	if gameOver {
		h.broadcastToGameRoom(room, &WSMessage{
			Type:     EventGameOver,
			GameType: room.GameType,
			RoomID:   room.ID,
			Payload:  state,
		})
	} else {
		h.broadcastGameState(room, state)
	}
}

func (h *Hub) HandleResign(client *Client) {
	h.mu.RLock()
	room, ok := h.gameRooms[client.GameRoomID]
	h.mu.RUnlock()

	if !ok {
		h.sendError(client, "no_active_game", "Not in an active game")
		return
	}

	room.mu.Lock()
	if room.GameOver {
		room.mu.Unlock()
		h.sendError(client, "game_already_over", "Game is already over")
		return
	}
	if !room.Started {
		room.mu.Unlock()
		h.sendError(client, "game_not_started", "Game has not started")
		return
	}
	if room.PlayerX == nil || room.PlayerO == nil || (room.PlayerX.UserID != client.UserID && room.PlayerO.UserID != client.UserID) {
		room.mu.Unlock()
		h.sendError(client, "not_a_player", "You are not a player in this room")
		return
	}
	room.GameOver = true
	room.Result = "resign"
	opponent := room.GetOpponent(client.UserID)
	if opponent != nil {
		room.Winner = opponent.UserID
	}
	room.saveCompletedGameLocked()
	state := room.toGameStateLocked()
	room.mu.Unlock()

	h.broadcastToGameRoom(room, &WSMessage{
		Type:     EventGameOver,
		GameType: room.GameType,
		RoomID:   room.ID,
		Payload:  state,
	})
}

func (h *Hub) handleClientDisconnect(client *Client) {
	h.removeQueuedClient(client, false, false)

	if client.GameRoomID == "" {
		return
	}

	h.mu.RLock()
	room, ok := h.gameRooms[client.GameRoomID]
	h.mu.RUnlock()

	if !ok {
		return
	}

	room.mu.Lock()
	if room.GameOver {
		room.mu.Unlock()
		return
	}

	if !room.Started {
		if room.PlayerX == client {
			room.PlayerX = nil
		}
		if room.PlayerO == client {
			room.PlayerO = nil
		}
		room.LastActivity = time.Now()
		room.mu.Unlock()
		return
	}
	if room.PlayerX != client && room.PlayerO != client {
		room.mu.Unlock()
		return
	}
	if timer, ok := room.disconnectTimers[client.UserID]; ok {
		timer.Stop()
	}
	timer := time.AfterFunc(30*time.Second, func() {
		room.mu.Lock()
		if room.GameOver || (room.PlayerX != client && room.PlayerO != client) {
			room.mu.Unlock()
			return
		}
		room.GameOver = true
		room.Result = "forfeit"
		opponent := room.GetOpponent(client.UserID)
		if opponent != nil {
			room.Winner = opponent.UserID
		}
		room.saveCompletedGameLocked()
		state := room.toGameStateLocked()
		room.mu.Unlock()

		h.broadcastToGameRoom(room, &WSMessage{
			Type:     EventGameOver,
			GameType: room.GameType,
			RoomID:   room.ID,
			Payload:  state,
		})
	})
	room.disconnectTimers[client.UserID] = timer
	room.mu.Unlock()
}

func (h *Hub) HandleLeaveGameRoom(client *Client) {
	h.removeQueuedClient(client, true, false)

	h.mu.RLock()
	room, ok := h.gameRooms[client.GameRoomID]
	h.mu.RUnlock()
	if !ok || room == nil {
		client.LeaveRoom()
		client.GameRoomID = ""
		return
	}

	room.mu.Lock()
	if room.GameOver {
		room.mu.Unlock()
		client.GameRoomID = ""
		client.CurrentRoom = ""
		return
	}
	if room.Started {
		room.mu.Unlock()
		h.HandleResign(client)
		client.GameRoomID = ""
		client.CurrentRoom = ""
		return
	}

	if room.PlayerX == client {
		room.PlayerX = nil
	}
	if room.PlayerO == client {
		room.PlayerO = nil
	}
	room.LastActivity = time.Now()
	empty := room.PlayerX == nil && room.PlayerO == nil
	roomID := room.ID
	roomCode := room.Code
	room.mu.Unlock()

	if empty {
		h.mu.Lock()
		delete(h.gameRooms, roomID)
		delete(h.codes, roomCode)
		h.mu.Unlock()
	}

	client.GameRoomID = ""
	client.CurrentRoom = ""
	client.Send(&WSMessage{Type: EventLeaveRoom, GameType: room.GameType, RoomID: roomID, Payload: map[string]interface{}{"room_id": roomID, "game_type": room.GameType}})
}

func (h *Hub) broadcastGameState(room *Room, state map[string]interface{}) {
	h.broadcastToGameRoom(room, &WSMessage{
		Type:     EventGameState,
		GameType: room.GameType,
		RoomID:   room.ID,
		Payload:  state,
	})
}

func (h *Hub) broadcastToGameRoom(room *Room, msg *WSMessage) {
	if msg.GameType == "" {
		msg.GameType = room.GameType
	}
	room.mu.Lock()
	px := room.PlayerX
	po := room.PlayerO
	room.mu.Unlock()

	h.sendToActiveClient(px, msg)
	h.sendToActiveClient(po, msg)
}

func (h *Hub) sendToActiveClient(client *Client, msg *WSMessage) {
	if client == nil {
		return
	}
	h.mu.RLock()
	active := h.clients[client]
	h.mu.RUnlock()
	if active {
		client.Send(msg)
	}
}

func (h *Hub) cleanupExpiredRooms() {
	ticker := time.NewTicker(time.Minute)
	defer ticker.Stop()
	for range ticker.C {
		h.mu.Lock()
		for id, room := range h.gameRooms {
			room.mu.Lock()
			activeX := room.PlayerX != nil && h.clients[room.PlayerX]
			activeO := room.PlayerO != nil && h.clients[room.PlayerO]
			empty := !activeX && !activeO
			stale := time.Since(room.LastActivity) > 5*time.Minute
			removable := !room.Started || room.GameOver
			room.mu.Unlock()
			if empty && stale && removable {
				delete(h.gameRooms, id)
				delete(h.codes, room.Code)
			}
		}
		h.mu.Unlock()
	}
}

func generateRoomCode() string {
	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, 6)
	for i := range b {
		b[i] = chars[rand.Intn(len(chars))]
	}
	return string(b)
}

func (h *Hub) isEmailVerified(client *Client) bool {
	if h.db == nil {
		return true
	}
	objectID, err := primitive.ObjectIDFromHex(client.UserID)
	if err != nil {
		return false
	}
	var user models.User
	if err := h.db.Collection("users").FindOne(context.Background(), bson.M{"_id": objectID}).Decode(&user); err != nil {
		return false
	}
	return user.EmailVerified
}

func (h *Hub) usernameForUser(userID string) string {
	if h.db == nil {
		return ""
	}
	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return ""
	}
	var user models.User
	if err := h.db.Collection("users").FindOne(context.Background(), bson.M{"_id": objectID}).Decode(&user); err != nil {
		return ""
	}
	return user.Username
}

func (h *Hub) EnqueueQuickMatch(client *Client, gameType string) {
	gameType = platformgames.NormalizeGameType(gameType)
	if !platformgames.IsSupportedGameType(gameType) {
		h.sendError(client, "unsupported_game_type", "Game type is not supported yet")
		return
	}
	if !h.isEmailVerified(client) {
		h.sendError(client, "email_not_verified", "Please verify your email to play online")
		return
	}

	h.mu.Lock()
	h.pruneInactiveQueueLocked()
	for _, queued := range h.matchQueue {
		if queued.UserID == client.UserID {
			queueSize := int64(len(h.matchQueue))
			h.mu.Unlock()
			metrics.Get().SetQueueSize(queueSize)
			h.sendError(client, "already_queued", "You are already waiting for quick match")
			return
		}
	}

	if len(h.matchQueue) > 0 {
		opponent := h.matchQueue[0]
		h.matchQueue = h.matchQueue[1:]

		code := generateRoomCode()
		for {
			if _, exists := h.codes[code]; !exists {
				break
			}
			code = generateRoomCode()
		}

		room := NewRoom(code, code, gameType, h.db)
		room.PlayerX = opponent
		room.PlayerO = client
		room.Started = true
		room.StartedAt = time.Now()
		h.gameRooms[room.ID] = room
		h.codes[code] = room
		opponent.GameRoomID = room.ID
		opponent.CurrentRoom = room.ID
		client.GameRoomID = room.ID
		client.CurrentRoom = room.ID

		queueSize := int64(len(h.matchQueue))
		h.mu.Unlock()

		metrics.Get().IncGames()
		metrics.Get().SetQueueSize(queueSize)

		state := room.ToGameState()
		opponent.Send(&WSMessage{Type: EventQuickMatchFound, GameType: room.GameType, Payload: map[string]interface{}{
			"game_type":  room.GameType,
			"room_id":    room.ID,
			"room_code":  room.Code,
			"color":      "X",
			"game_state": state,
		}})
		client.Send(&WSMessage{Type: EventQuickMatchFound, GameType: room.GameType, Payload: map[string]interface{}{
			"game_type":  room.GameType,
			"room_id":    room.ID,
			"room_code":  room.Code,
			"color":      "O",
			"game_state": state,
		}})
		h.broadcastToGameRoom(room, &WSMessage{Type: EventGameState, GameType: room.GameType, RoomID: room.ID, Payload: state})
		slog.Info("quick_match_found", "room_id", room.ID, "player_x", opponent.UserID, "player_o", client.UserID)
		return
	}

	h.matchQueue = append(h.matchQueue, client)
	queueSize := int64(len(h.matchQueue))
	h.mu.Unlock()

	metrics.Get().SetQueueSize(queueSize)
	slog.Info("quick_match_queued", "user_id", client.UserID, "queue_size", queueSize)

	go func() {
		time.Sleep(60 * time.Second)
		h.mu.Lock()
		found := false
		for i, c := range h.matchQueue {
			if c == client {
				h.matchQueue = append(h.matchQueue[:i], h.matchQueue[i+1:]...)
				found = true
				break
			}
		}
		qSize := int64(len(h.matchQueue))
		h.mu.Unlock()
		if found {
			metrics.Get().SetQueueSize(qSize)
			client.Send(&WSMessage{Type: EventQuickMatchTimeout, Payload: map[string]interface{}{}})
		}
	}()
}

func (h *Hub) pruneInactiveQueueLocked() {
	activeQueue := h.matchQueue[:0]
	for _, queued := range h.matchQueue {
		if h.clients[queued] {
			activeQueue = append(activeQueue, queued)
		}
	}
	h.matchQueue = activeQueue
}

func (h *Hub) removeQueuedClient(client *Client, matchUser bool, notify bool) bool {
	h.mu.Lock()
	removed := false
	for i, queued := range h.matchQueue {
		if queued == client || (matchUser && queued.UserID == client.UserID) {
			h.matchQueue = append(h.matchQueue[:i], h.matchQueue[i+1:]...)
			removed = true
			break
		}
	}
	queueSize := int64(len(h.matchQueue))
	h.mu.Unlock()

	metrics.Get().SetQueueSize(queueSize)
	if removed && notify {
		client.Send(&WSMessage{Type: EventQuickMatchCancelled, Payload: map[string]interface{}{}})
	}
	return removed
}

func (h *Hub) DequeueQuickMatch(client *Client) {
	h.removeQueuedClient(client, true, true)
}

func (h *Hub) HandleChatMessage(client *Client, msg Message) {
	payload, ok := msg.Payload.(map[string]interface{})
	if !ok {
		h.sendError(client, "invalid_payload", "Message payload is required")
		return
	}
	content, _ := payload["content"].(string)
	content = trimSpace(content)
	if content == "" || len(content) > 500 {
		h.sendError(client, "invalid_message", "Message must be 1-500 characters")
		return
	}

	h.mu.RLock()
	room, exists := h.gameRooms[client.GameRoomID]
	h.mu.RUnlock()
	if !exists || room == nil {
		h.sendError(client, "no_active_game", "Not in an active game")
		return
	}

	broadcast := &WSMessage{
		Type: EventChatMessage,
		Payload: map[string]interface{}{
			"sender_id": client.UserID,
			"content":   content,
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		},
	}
	h.broadcastToGameRoom(room, broadcast)
}

func trimSpace(s string) string {
	result := []byte{}
	leading := true
	for i := 0; i < len(s); i++ {
		if s[i] == ' ' || s[i] == '\t' || s[i] == '\n' || s[i] == '\r' {
			if !leading {
				result = append(result, s[i])
			}
		} else {
			leading = false
			result = append(result, s[i])
		}
	}
	for len(result) > 0 && (result[len(result)-1] == ' ' || result[len(result)-1] == '\t' || result[len(result)-1] == '\n' || result[len(result)-1] == '\r') {
		result = result[:len(result)-1]
	}
	return string(result)
}
