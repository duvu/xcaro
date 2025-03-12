package ws

import (
	"sync"
)

const (
	MessageTypeMove         = "move"
	MessageTypeChat         = "chat"
	MessageTypeOffer        = "offer"         // WebRTC offer
	MessageTypeAnswer       = "answer"        // WebRTC answer
	MessageTypeIceCandidate = "ice-candidate" // WebRTC ICE candidate
)

type Message struct {
	Type    string      `json:"type"`
	Payload interface{} `json:"payload"`
}

type ChatMessage struct {
	UserID    string `json:"user_id"`
	Username  string `json:"username"`
	Content   string `json:"content"`
	Timestamp int64  `json:"timestamp"`
}

type WebRTCMessage struct {
	UserID string      `json:"user_id"`
	Data   interface{} `json:"data"`
}

type BroadcastMessage struct {
	GameID  string
	Message []byte
}

// Hub duy trì danh sách các clients và broadcasts messages
type Hub struct {
	// Registered clients
	clients map[*Client]bool

	// Rooms và clients trong mỗi room
	rooms map[string]map[*Client]bool

	// Inbound messages từ clients
	broadcast chan *WSMessage

	// Register requests từ clients
	register chan *Client

	// Unregister requests từ clients
	unregister chan *Client

	// Mutex để bảo vệ concurrent access
	mu sync.RWMutex
}

func NewHub() *Hub {
	return &Hub{
		broadcast:  make(chan *WSMessage),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		clients:    make(map[*Client]bool),
		rooms:      make(map[string]map[*Client]bool),
	}
}

func (h *Hub) Run() {
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

				// Remove from rooms
				for roomID, room := range h.rooms {
					if _, ok := room[client]; ok {
						delete(room, client)
						// Notify other clients in room
						h.BroadcastToRoom(roomID, &WSMessage{
							Type:   EventPlayerLeave,
							RoomID: roomID,
							Payload: map[string]interface{}{
								"user_id": client.UserID,
							},
						})
					}
				}
			}
			h.mu.Unlock()

		case message := <-h.broadcast:
			h.mu.RLock()
			// Broadcast to specific room if RoomID is provided
			if message.RoomID != "" {
				h.BroadcastToRoom(message.RoomID, message)
			} else {
				// Broadcast to all clients
				for client := range h.clients {
					select {
					case client.send <- message:
					default:
						h.mu.RUnlock()
						h.mu.Lock()
						close(client.send)
						delete(h.clients, client)
						h.mu.Unlock()
						h.mu.RLock()
					}
				}
			}
			h.mu.RUnlock()
		}
	}
}

// JoinRoom adds a client to a room
func (h *Hub) JoinRoom(roomID string, client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if h.rooms[roomID] == nil {
		h.rooms[roomID] = make(map[*Client]bool)
	}
	h.rooms[roomID][client] = true

	// Notify other clients in room
	h.BroadcastToRoom(roomID, &WSMessage{
		Type:   EventPlayerJoin,
		RoomID: roomID,
		Payload: map[string]interface{}{
			"user_id": client.UserID,
		},
	})
}

// LeaveRoom removes a client from a room
func (h *Hub) LeaveRoom(roomID string, client *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if room, ok := h.rooms[roomID]; ok {
		delete(room, client)
		// Notify other clients in room
		h.BroadcastToRoom(roomID, &WSMessage{
			Type:   EventPlayerLeave,
			RoomID: roomID,
			Payload: map[string]interface{}{
				"user_id": client.UserID,
			},
		})
	}
}

// BroadcastToRoom sends a message to all clients in a room
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

// SendToClient sends a message to a specific client
func (h *Hub) SendToClient(client *Client, message *WSMessage) {
	select {
	case client.send <- message:
	default:
		h.mu.Lock()
		close(client.send)
		delete(h.clients, client)
		h.mu.Unlock()
	}
}

// GetRoomClients returns all clients in a room
func (h *Hub) GetRoomClients(roomID string) []*Client {
	h.mu.RLock()
	defer h.mu.RUnlock()

	var clients []*Client
	if room, ok := h.rooms[roomID]; ok {
		for client := range room {
			clients = append(clients, client)
		}
	}
	return clients
}

// GetClientCount returns the number of clients in a room
func (h *Hub) GetClientCount(roomID string) int {
	h.mu.RLock()
	defer h.mu.RUnlock()

	if room, ok := h.rooms[roomID]; ok {
		return len(room)
	}
	return 0
}
