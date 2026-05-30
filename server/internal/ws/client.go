package ws

import (
	"encoding/json"
	"log"
	"time"

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
				log.Printf("error: %v", err)
			}
			break
		}

		var msg incomingMessage
		if err := json.Unmarshal(message, &msg); err != nil {
			log.Printf("error parsing message: %v", err)
			continue
		}

		switch msg.Type {
		case EventJoinRoom:
			code := ""
			if v, ok := msg.Payload["code"]; ok {
				code, _ = v.(string)
			}
			c.hub.HandleJoinRoom(c, code)

		case EventMakeMove:
			x, y := 0, 0
			if v, ok := msg.Payload["x"]; ok {
				if f, ok := v.(float64); ok {
					x = int(f)
				}
			}
			if v, ok := msg.Payload["y"]; ok {
				if f, ok := v.(float64); ok {
					y = int(f)
				}
			}
			c.hub.HandleMakeMove(c, x, y)

		case EventResign:
			c.hub.HandleResign(c)

		case EventGameMove:
			if c.CurrentRoom != "" {
				var wsMessage WSMessage
				if err := json.Unmarshal(message, &wsMessage); err == nil {
					c.hub.broadcast <- &wsMessage
				}
			}

		case EventChatMessage:
			c.hub.HandleChatMessage(c, Message{Type: msg.Type, Payload: msg.Payload})

		case EventPing:
			c.send <- &WSMessage{Type: EventPong}
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
				log.Printf("error marshaling message: %v", err)
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
					log.Printf("error marshaling queued message: %v", err)
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
	select {
	case c.send <- message:
	default:
		close(c.send)
		delete(c.hub.clients, c)
	}
}
