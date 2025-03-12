package ws

import (
	"testing"
	"time"
)

func TestHub(t *testing.T) {
	hub := NewHub()
	go hub.Run()

	// Tạo test client
	client1 := &Client{
		hub:      hub,
		send:     make(chan *WSMessage, 256),
		UserID:   "user1",
		Username: "User 1",
	}

	client2 := &Client{
		hub:      hub,
		send:     make(chan *WSMessage, 256),
		UserID:   "user2",
		Username: "User 2",
	}

	// Test đăng ký client
	hub.register <- client1
	hub.register <- client2
	time.Sleep(100 * time.Millisecond) // Đợi xử lý

	if len(hub.clients) != 2 {
		t.Errorf("Expected 2 clients, got %d", len(hub.clients))
	}

	// Test tham gia phòng
	roomID := "room1"
	client1.JoinRoom(roomID)
	client2.JoinRoom(roomID)
	time.Sleep(100 * time.Millisecond)

	if hub.GetClientCount(roomID) != 2 {
		t.Errorf("Expected 2 clients in room, got %d", hub.GetClientCount(roomID))
	}

	// Test broadcast message
	testMsg := &WSMessage{
		Type:    EventChatMessage,
		RoomID:  roomID,
		Payload: map[string]interface{}{"content": "Hello"},
	}
	hub.broadcast <- testMsg

	// Kiểm tra nhận message
	select {
	case msg := <-client1.send:
		if msg.Type != EventChatMessage {
			t.Errorf("Expected message type %s, got %s", EventChatMessage, msg.Type)
		}
	case <-time.After(time.Second):
		t.Error("Timeout waiting for message")
	}

	// Test rời phòng
	client1.LeaveRoom()
	time.Sleep(100 * time.Millisecond)

	if hub.GetClientCount(roomID) != 1 {
		t.Errorf("Expected 1 client in room, got %d", hub.GetClientCount(roomID))
	}

	// Test hủy đăng ký client
	hub.unregister <- client1
	hub.unregister <- client2
	time.Sleep(100 * time.Millisecond)

	if len(hub.clients) != 0 {
		t.Errorf("Expected 0 clients, got %d", len(hub.clients))
	}
}
