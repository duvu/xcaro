package ws

import (
	"context"
	"log"
	"math/rand"
	"sync"
	"time"

	"github.com/duvu/xcaro/server/pkg/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

type Hub struct {
	clients    map[*Client]bool
	rooms      map[string]map[*Client]bool
	gameRooms  map[string]*Room
	codes      map[string]*Room
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

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
			}
			h.mu.Unlock()
			h.handleClientDisconnect(client)

		case message := <-h.broadcast:
			h.mu.RLock()
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
			h.mu.RUnlock()
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
		log.Printf("broadcast channel is full")
	}
}

func (h *Hub) JoinRoom(roomID string, client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if h.rooms[roomID] == nil {
		h.rooms[roomID] = make(map[*Client]bool)
	}
	h.rooms[roomID][client] = true

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
	defer h.mu.Unlock()

	if room, ok := h.rooms[roomID]; ok {
		delete(room, client)
		h.BroadcastToRoom(roomID, &WSMessage{
			Type:   EventPlayerLeave,
			RoomID: roomID,
			Payload: map[string]interface{}{
				"user_id": client.UserID,
			},
		})
	}
}

func (h *Hub) BroadcastToRoom(roomID string, message *WSMessage) {
	h.mu.RLock()
	defer h.mu.RUnlock()

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

func (h *Hub) HandleCreateRoom(client *Client) {
	if !h.isEmailVerified(client) {
		client.send <- &WSMessage{
			Type: EventError,
			Payload: map[string]interface{}{
				"code":    "email_not_verified",
				"message": "Please verify your email to play online",
			},
		}
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

	room := NewRoom(code, code, h.db)
	room.PlayerX = client
	h.gameRooms[room.ID] = room
	h.codes[code] = room
	h.mu.Unlock()

	client.GameRoomID = room.ID
	client.Send(&WSMessage{
		Type:    EventGameState,
		RoomID:  room.ID,
		Payload: room.ToGameState(),
	})
}

func (h *Hub) HandleJoinRoom(client *Client, code string) {
	if !h.isEmailVerified(client) {
		client.send <- &WSMessage{
			Type: EventError,
			Payload: map[string]interface{}{
				"code":    "email_not_verified",
				"message": "Please verify your email to play online",
			},
		}
		return
	}

	h.mu.Lock()

	if code == "" {
		h.mu.Unlock()
		h.HandleCreateRoom(client)
		return
	}

	room, exists := h.codes[code]
	if !exists {
		h.mu.Unlock()
		client.Send(&WSMessage{
			Type:    EventError,
			Payload: map[string]string{"message": "phòng không tồn tại"},
		})
		return
	}

	bothFull := room.PlayerO != nil && room.PlayerX != nil
	if bothFull {
		isPlayerX := room.PlayerX.UserID == client.UserID
		isPlayerO := room.PlayerO.UserID == client.UserID
		if !isPlayerX && !isPlayerO {
			h.mu.Unlock()
			client.Send(&WSMessage{
				Type:    EventError,
				Payload: map[string]string{"message": "phòng đã đầy"},
			})
			return
		}
		h.mu.Unlock()
		h.handleRejoin(client, room)
		return
	}

	if room.PlayerX != nil && room.PlayerX.UserID == client.UserID {
		h.mu.Unlock()
		client.GameRoomID = room.ID
		client.Send(&WSMessage{Type: EventGameState, RoomID: room.ID, Payload: room.ToGameState()})
		return
	}

	room.PlayerO = client
	client.GameRoomID = room.ID

	if room.PlayerX != nil && room.PlayerO != nil {
		room.Started = true
		room.StartedAt = time.Now()
	}
	state := room.ToGameState()
	h.mu.Unlock()

	h.broadcastGameState(room, state)
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
	state := room.ToGameState()
	room.mu.Unlock()

	client.GameRoomID = room.ID
	client.Send(&WSMessage{Type: EventGameState, RoomID: room.ID, Payload: state})
}

func (h *Hub) HandleMakeMove(client *Client, x, y int) {
	h.mu.RLock()
	room, ok := h.gameRooms[client.GameRoomID]
	h.mu.RUnlock()

	if !ok {
		client.Send(&WSMessage{Type: EventError, Payload: map[string]string{"message": "không tìm thấy phòng"}})
		return
	}

	if err := room.MakeMove(client.UserID, x, y); err != nil {
		client.Send(&WSMessage{Type: EventError, Payload: map[string]string{"message": err.Error()}})
		return
	}

	state := room.ToGameState()
	if room.GameOver {
		h.broadcastToGameRoom(room, &WSMessage{
			Type:    EventGameOver,
			RoomID:  room.ID,
			Payload: state,
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
		return
	}

	room.mu.Lock()
	if room.GameOver {
		room.mu.Unlock()
		return
	}
	room.GameOver = true
	room.Result = "resign"
	opponent := room.GetOpponent(client.UserID)
	if opponent != nil {
		room.Winner = opponent.UserID
	}
	if room.db != nil {
		go room.saveGameRecord()
	}
	state := room.ToGameState()
	room.mu.Unlock()

	h.broadcastToGameRoom(room, &WSMessage{
		Type:    EventGameOver,
		RoomID:  room.ID,
		Payload: state,
	})
}

func (h *Hub) handleClientDisconnect(client *Client) {
	if client.GameRoomID == "" {
		return
	}

	h.mu.RLock()
	room, ok := h.gameRooms[client.GameRoomID]
	h.mu.RUnlock()

	if !ok || room.GameOver {
		return
	}

	room.mu.Lock()
	timer := time.AfterFunc(30*time.Second, func() {
		room.mu.Lock()
		if room.GameOver {
			room.mu.Unlock()
			return
		}
		room.GameOver = true
		room.Result = "forfeit"
		opponent := room.GetOpponent(client.UserID)
		if opponent != nil {
			room.Winner = opponent.UserID
		}
		if room.db != nil {
			go room.saveGameRecord()
		}
		state := room.ToGameState()
		room.mu.Unlock()

		h.broadcastToGameRoom(room, &WSMessage{
			Type:    EventGameOver,
			RoomID:  room.ID,
			Payload: state,
		})
	})
	room.disconnectTimers[client.UserID] = timer
	room.mu.Unlock()
}

func (h *Hub) broadcastGameState(room *Room, state map[string]interface{}) {
	h.broadcastToGameRoom(room, &WSMessage{
		Type:    EventGameState,
		RoomID:  room.ID,
		Payload: state,
	})
}

func (h *Hub) broadcastToGameRoom(room *Room, msg *WSMessage) {
	room.mu.Lock()
	px := room.PlayerX
	po := room.PlayerO
	room.mu.Unlock()

	if px != nil {
		px.Send(msg)
	}
	if po != nil {
		po.Send(msg)
	}
}

func (h *Hub) cleanupExpiredRooms() {
	ticker := time.NewTicker(time.Minute)
	defer ticker.Stop()
	for range ticker.C {
		h.mu.Lock()
		for id, room := range h.gameRooms {
			room.mu.Lock()
			empty := room.PlayerX == nil && room.PlayerO == nil
			stale := time.Since(room.LastActivity) > 5*time.Minute
			room.mu.Unlock()
			if empty && stale {
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
		return true
	}
	var user models.User
	if err := h.db.Collection("users").FindOne(context.Background(), bson.M{"_id": objectID}).Decode(&user); err != nil {
		return true
	}
	return user.EmailVerified
}

func (h *Hub) HandleChatMessage(client *Client, msg Message) {
	content, _ := msg.Payload.(map[string]interface{})["content"].(string)
	content = trimSpace(content)
	if content == "" || len(content) > 500 {
		client.send <- &WSMessage{
			Type: EventError,
			Payload: map[string]interface{}{
				"code":    "invalid_message",
				"message": "Message must be 1-500 characters",
			},
		}
		return
	}

	h.mu.RLock()
	room, exists := h.gameRooms[client.GameRoomID]
	h.mu.RUnlock()
	if !exists || room == nil {
		client.send <- &WSMessage{Type: EventError, Payload: map[string]interface{}{"code": "no_active_game", "message": "Not in an active game"}}
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
