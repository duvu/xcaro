package ws

import (
	"encoding/json"
	"log/slog"
	"time"

	platformgames "github.com/duvu/playverse/server/internal/games"
	"github.com/gorilla/websocket"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512 * 1024
)

type Client struct {
	hub *Hub

	conn *websocket.Conn

	send chan *WSMessage

	UserID   string
	Username string

	CurrentRoom string
	GameRoomID  string
}

func NewClient(hub *Hub, conn *websocket.Conn, userID, username string) *Client {
	return &Client{
		hub:      hub,
		conn:     conn,
		send:     make(chan *WSMessage, 256),
		UserID:   userID,
		Username: username,
	}
}

type incomingMessage struct {
	Type    string                 `json:"type"`
	Payload map[string]interface{} `json:"payload"`
}

func payloadString(payload map[string]interface{}, key string) (string, bool) {
	value, ok := payload[key]
	if !ok {
		return "", false
	}
	text, ok := value.(string)
	return text, ok && text != ""
}

func payloadInt(payload map[string]interface{}, key string) (int, bool) {
	value, ok := payload[key]
	if !ok {
		return 0, false
	}
	number, ok := value.(float64)
	if !ok {
		return 0, false
	}
	return int(number), true
}

func (c *Client) ReadPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				slog.Error("websocket read error", "error", err, "user_id", c.UserID)
			}
			break
		}

		var msg incomingMessage
		if err := json.Unmarshal(message, &msg); err != nil {
			slog.Warn("invalid message", "error", err, "user_id", c.UserID)
			c.hub.sendError(c, "invalid_json", "Message must be valid JSON")
			continue
		}
		if msg.Payload == nil {
			msg.Payload = map[string]interface{}{}
		}

		switch msg.Type {
		case EventCreateRoom:
			gameType, _ := payloadString(msg.Payload, "game_type")
			c.hub.HandleCreateRoom(c, gameType)

		case EventJoinRoom, EventJoinRoomByCode:
			code, ok := payloadString(msg.Payload, "code")
			if !ok {
				c.hub.sendError(c, "invalid_payload", "Room code is required")
				continue
			}
			gameType, _ := payloadString(msg.Payload, "game_type")
			c.hub.HandleJoinRoom(c, code, gameType)

		case EventRejoinRoom:
			roomID, _ := payloadString(msg.Payload, "room_id")
			code, _ := payloadString(msg.Payload, "code")
			if roomID == "" && code == "" {
				c.hub.sendError(c, "invalid_payload", "room_id or code is required")
				continue
			}
			c.hub.HandleRejoinRoom(c, roomID, code)

		case EventMakeMove:
			gameType, _ := payloadString(msg.Payload, "game_type")
			if platformgames.NormalizeGameType(gameType) == platformgames.GameTypeChess {
				from, okFrom := payloadString(msg.Payload, "from")
				to, okTo := payloadString(msg.Payload, "to")
				if !okFrom || !okTo {
					c.hub.sendError(c, "invalid_payload", "Chess move payload requires from and to squares")
					continue
				}
				promotion, _ := payloadString(msg.Payload, "promotion")
				c.hub.HandleChessMakeMove(c, from, to, promotion)
			} else {
				x, okX := payloadInt(msg.Payload, "x")
				y, okY := payloadInt(msg.Payload, "y")
				if !okX || !okY {
					c.hub.sendError(c, "invalid_payload", "Move payload requires numeric x and y")
					continue
				}
				c.hub.HandleMakeMove(c, x, y)
			}

		case EventResign:
			c.hub.HandleResign(c)

		case EventLeaveRoom:
			c.hub.HandleLeaveGameRoom(c)

		case EventGameMove:
			if c.CurrentRoom != "" {
				var wsMessage WSMessage
				if err := json.Unmarshal(message, &wsMessage); err == nil {
					c.hub.broadcast <- &wsMessage
				}
			}

		case EventChatMessage:
			c.hub.HandleChatMessage(c, Message{Type: msg.Type, Payload: msg.Payload})

		case EventQuickMatchRequest:
			gameType, _ := payloadString(msg.Payload, "game_type")
			c.hub.EnqueueQuickMatch(c, platformgames.NormalizeGameType(gameType))

		case EventQuickMatchCancel:
			c.hub.DequeueQuickMatch(c)

		case EventPing:
			c.Send(&WSMessage{Type: EventPong})

		default:
			c.hub.sendError(c, "unknown_event", "Unsupported WebSocket event")
		}
	}
}

func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			data, err := json.Marshal(message)
			if err != nil {
				slog.Warn("marshal error", "error", err)
				continue
			}

			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(data)

			n := len(c.send)
			for i := 0; i < n; i++ {
				data, err := json.Marshal(<-c.send)
				if err != nil {
					slog.Warn("marshal error", "error", err)
					continue
				}
				w.Write([]byte("\n"))
				w.Write(data)
			}

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func (c *Client) JoinRoom(roomID string) {
	if c.CurrentRoom != "" {
		c.LeaveRoom()
	}
	c.CurrentRoom = roomID
	c.hub.JoinRoom(roomID, c)
}

func (c *Client) LeaveRoom() {
	if c.CurrentRoom != "" {
		c.hub.LeaveRoom(c.CurrentRoom, c)
		c.CurrentRoom = ""
	}
}

func (c *Client) Send(message *WSMessage) {
	defer func() {
		if recover() != nil {
			slog.Warn("websocket send channel closed", "user_id", c.UserID)
		}
	}()

	select {
	case c.send <- message:
	default:
		c.hub.mu.Lock()
		if c.hub.clients[c] {
			delete(c.hub.clients, c)
			close(c.send)
		}
		c.hub.mu.Unlock()
	}
}
