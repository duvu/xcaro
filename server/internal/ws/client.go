package ws

import (
	"encoding/json"
	"log"
	"time"

	"github.com/gorilla/websocket"
)

const (
	// Time allowed to write a message to the peer
	writeWait = 10 * time.Second

	// Time allowed to read the next pong message from the peer
	pongWait = 60 * time.Second

	// Send pings to peer with this period. Must be less than pongWait
	pingPeriod = (pongWait * 9) / 10

	// Maximum message size allowed from peer
	maxMessageSize = 512
)

// Client is a middleman between the websocket connection and the hub
type Client struct {
	hub *Hub

	// The websocket connection
	conn *websocket.Conn

	// Buffered channel of outbound messages
	send chan *WSMessage

	// User info
	UserID   string
	Username string

	// Room info
	CurrentRoom string
}

// NewClient creates a new client
func NewClient(hub *Hub, conn *websocket.Conn, userID, username string) *Client {
	return &Client{
		hub:      hub,
		conn:     conn,
		send:     make(chan *WSMessage, 256),
		UserID:   userID,
		Username: username,
	}
}

// ReadPump pumps messages from the websocket connection to the hub
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

		// Parse message
		var wsMessage WSMessage
		if err := json.Unmarshal(message, &wsMessage); err != nil {
			log.Printf("error parsing message: %v", err)
			continue
		}

		// Handle different message types
		switch wsMessage.Type {
		case EventGameMove:
			// Handle game move
			if c.CurrentRoom != "" {
				c.hub.broadcast <- &wsMessage
			}

		case EventChatMessage:
			// Handle chat message
			if c.CurrentRoom != "" {
				// Add user info to payload
				if payload, ok := wsMessage.Payload.(map[string]interface{}); ok {
					payload["user_id"] = c.UserID
					payload["username"] = c.Username
					payload["timestamp"] = time.Now().Unix()
					wsMessage.Payload = payload
				}
				c.hub.broadcast <- &wsMessage
			}

		case EventPing:
			// Handle ping
			c.send <- &WSMessage{
				Type: EventPong,
			}
		}
	}
}

// WritePump pumps messages from the hub to the websocket connection
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
				// The hub closed the channel
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			// Marshal message
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

			// Add queued messages to the current websocket message
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

// JoinRoom makes the client join a room
func (c *Client) JoinRoom(roomID string) {
	if c.CurrentRoom != "" {
		c.LeaveRoom()
	}
	c.CurrentRoom = roomID
	c.hub.JoinRoom(roomID, c)
}

// LeaveRoom makes the client leave their current room
func (c *Client) LeaveRoom() {
	if c.CurrentRoom != "" {
		c.hub.LeaveRoom(c.CurrentRoom, c)
		c.CurrentRoom = ""
	}
}
