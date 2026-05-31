package ws

import (
	"errors"
	"testing"
	"time"

	platformgames "github.com/duvu/playverse/server/internal/games"
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

	if count := hubActiveClientCount(hub); count != 2 {
		t.Errorf("Expected 2 clients, got %d", count)
	}

	// Test tham gia phòng
	roomID := "room1"
	client1.JoinRoom(roomID)
	client2.JoinRoom(roomID)
	time.Sleep(100 * time.Millisecond)
	drainMessages(client1.send)
	drainMessages(client2.send)

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

	if count := hubActiveClientCount(hub); count != 0 {
		t.Errorf("Expected 0 clients, got %d", count)
	}
}

func hubActiveClientCount(hub *Hub) int {
	hub.mu.RLock()
	defer hub.mu.RUnlock()
	return len(hub.clients)
}

func drainMessages(ch <-chan *WSMessage) {
	for {
		select {
		case <-ch:
		default:
			return
		}
	}
}

func TestRoomMakeMoveValidationAndCanonicalState(t *testing.T) {
	playerX := testClient("user-x", "Alice")
	playerO := testClient("user-o", "Bob")
	room := NewRoom("ABC123", "ABC123", platformgames.GameTypeCaro, nil)
	room.PlayerX = playerX
	room.PlayerO = playerO
	room.Started = true

	err := room.MakeMove(playerO.UserID, 0, 0)
	assertRoomError(t, err, "not_your_turn")

	err = room.MakeMove(playerX.UserID, -1, 0)
	assertRoomError(t, err, "invalid_coordinates")

	if err := room.MakeMove(playerX.UserID, 0, 0); err != nil {
		t.Fatalf("expected first move to succeed: %v", err)
	}
	state := room.ToGameState()
	if state["room_id"] != "ABC123" || state["room_code"] != "ABC123" || state["code"] != "ABC123" {
		t.Fatalf("expected canonical room identifiers, got %#v", state)
	}
	if state["current_turn"] != playerO.UserID {
		t.Fatalf("expected current_turn to switch to player O, got %#v", state["current_turn"])
	}
	if state["status"] != "active" {
		t.Fatalf("expected active status, got %#v", state["status"])
	}

	err = room.MakeMove(playerO.UserID, 0, 0)
	assertRoomError(t, err, "cell_occupied")
}

func TestRoomWinningCellsAndGameOverPayload(t *testing.T) {
	playerX := testClient("user-x", "Alice")
	playerO := testClient("user-o", "Bob")
	room := NewRoom("ROOM01", "ROOM01", platformgames.GameTypeCaro, nil)
	room.PlayerX = playerX
	room.PlayerO = playerO
	room.Started = true
	room.Turn = 1
	for y := 0; y < 4; y++ {
		room.Board[0][y] = 1
	}

	if err := room.MakeMove(playerX.UserID, 0, 4); err != nil {
		t.Fatalf("expected winning move to succeed: %v", err)
	}
	if !room.GameOver || room.Result != "win" || room.Winner != playerX.UserID {
		t.Fatalf("expected player X win, got gameOver=%v result=%q winner=%q", room.GameOver, room.Result, room.Winner)
	}
	if len(room.WinningCells) != 5 {
		t.Fatalf("expected 5 winning cells, got %#v", room.WinningCells)
	}
	state := room.ToGameState()
	if state["status"] != "finished" || state["game_over"] != true {
		t.Fatalf("expected finished game state, got %#v", state)
	}
}

func TestHubRoomLifecycleRejectsThirdPlayerAndSupportsRejoin(t *testing.T) {
	hub := NewHub()
	playerX := testClientWithHub(hub, "user-x", "Alice")
	playerO := testClientWithHub(hub, "user-o", "Bob")
	third := testClientWithHub(hub, "user-z", "Carol")
	activateClients(hub, playerX, playerO, third)

	hub.HandleCreateRoom(playerX, platformgames.GameTypeCaro)
	created := receiveMessage(t, playerX.send)
	if created.Type != EventGameState {
		t.Fatalf("expected game_state, got %s", created.Type)
	}
	state, ok := created.Payload.(map[string]interface{})
	if !ok {
		t.Fatalf("expected map payload, got %#v", created.Payload)
	}
	if state["game_type"] != platformgames.GameTypeCaro {
		t.Fatalf("expected game_type %q, got %#v", platformgames.GameTypeCaro, state["game_type"])
	}
	code, ok := state["room_code"].(string)
	if !ok || len(code) != 6 {
		t.Fatalf("expected 6-character room code, got %#v", state["room_code"])
	}

	hub.HandleJoinRoom(playerO, code, platformgames.GameTypeCaro)
	xState := receiveMessage(t, playerX.send)
	oState := receiveMessage(t, playerO.send)
	if xState.Type != EventGameState || oState.Type != EventGameState {
		t.Fatalf("expected game_state broadcast, got %s/%s", xState.Type, oState.Type)
	}
	room := hub.gameRooms[playerX.GameRoomID]
	if room == nil || !room.Started || room.PlayerO != playerO {
		t.Fatalf("expected started room with player O, got %#v", room)
	}

	hub.HandleJoinRoom(third, code, platformgames.GameTypeCaro)
	if code := receiveErrorCode(t, third.send); code != "room_full" {
		t.Fatalf("expected room_full, got %q", code)
	}

	rejoin := testClientWithHub(hub, playerX.UserID, "Alice v2")
	activateClients(hub, rejoin)
	hub.HandleRejoinRoom(rejoin, room.ID, "")
	rejoinState := receiveMessage(t, rejoin.send)
	if rejoinState.Type != EventGameState {
		t.Fatalf("expected rejoin game_state, got %s", rejoinState.Type)
	}
	if room.PlayerX != rejoin || rejoin.GameRoomID != room.ID || rejoin.CurrentRoom != room.ID {
		t.Fatalf("expected rejoin to replace player X seat")
	}
}

func TestDisconnectRejoinCancelsReservedSeatTimer(t *testing.T) {
	hub := NewHub()
	playerX := testClientWithHub(hub, "user-x", "Alice")
	playerO := testClientWithHub(hub, "user-o", "Bob")
	activateClients(hub, playerX, playerO)

	room := NewRoom("ROOM42", "ROOM42", platformgames.GameTypeCaro, nil)
	room.PlayerX = playerX
	room.PlayerO = playerO
	room.Started = true
	playerX.GameRoomID = room.ID
	playerX.CurrentRoom = room.ID
	playerO.GameRoomID = room.ID
	playerO.CurrentRoom = room.ID
	hub.gameRooms[room.ID] = room
	hub.codes[room.Code] = room

	hub.handleClientDisconnect(playerX)
	room.mu.Lock()
	_, hasTimer := room.disconnectTimers[playerX.UserID]
	room.mu.Unlock()
	if !hasTimer {
		t.Fatalf("expected disconnect timer for reserved player X seat")
	}

	rejoin := testClientWithHub(hub, playerX.UserID, "Alice rejoined")
	activateClients(hub, rejoin)
	hub.HandleRejoinRoom(rejoin, room.ID, "")
	msg := receiveMessage(t, rejoin.send)
	if msg.Type != EventGameState {
		t.Fatalf("expected game_state after rejoin, got %s", msg.Type)
	}

	room.mu.Lock()
	_, hasTimer = room.disconnectTimers[playerX.UserID]
	room.mu.Unlock()
	if hasTimer {
		t.Fatalf("expected reconnect to cancel disconnect timer")
	}
	if room.PlayerX != rejoin {
		t.Fatalf("expected rejoined client to replace player X seat")
	}
}

func TestPreStartDisconnectFreesSeatAndRoomCannotStart(t *testing.T) {
	hub := NewHub()
	creator := testClientWithHub(hub, "user-x", "Alice")
	joiner := testClientWithHub(hub, "user-o", "Bob")
	activateClients(hub, creator, joiner)

	hub.HandleCreateRoom(creator, platformgames.GameTypeCaro)
	created := receiveMessage(t, creator.send)
	state, ok := created.Payload.(map[string]interface{})
	if !ok {
		t.Fatalf("expected map payload, got %#v", created.Payload)
	}
	code, ok := state["room_code"].(string)
	if !ok {
		t.Fatalf("expected room code in state %#v", state)
	}
	room := hub.codes[code]

	hub.handleClientDisconnect(creator)
	if room.PlayerX != nil || room.Started {
		t.Fatalf("expected pre-start disconnect to free creator seat without starting room")
	}

	hub.HandleJoinRoom(joiner, code, platformgames.GameTypeCaro)
	if code := receiveErrorCode(t, joiner.send); code != "room_not_found" {
		t.Fatalf("expected room_not_found for abandoned waiting room, got %q", code)
	}
}

func TestQuickMatchRejectsDuplicateAndPairsDifferentUsers(t *testing.T) {
	hub := NewHub()
	first := testClientWithHub(hub, "user-a", "Alice")
	duplicate := testClientWithHub(hub, "user-a", "Alice tab 2")
	second := testClientWithHub(hub, "user-b", "Bob")
	activateClients(hub, first, duplicate, second)

	hub.EnqueueQuickMatch(first, platformgames.GameTypeCaro)
	if len(hub.matchQueue) != 1 {
		t.Fatalf("expected one queued client, got %d", len(hub.matchQueue))
	}
	hub.EnqueueQuickMatch(duplicate, platformgames.GameTypeCaro)
	if code := receiveErrorCode(t, duplicate.send); code != "already_queued" {
		t.Fatalf("expected already_queued, got %q", code)
	}

	hub.EnqueueQuickMatch(second, platformgames.GameTypeCaro)
	firstFound := receiveMessage(t, first.send)
	secondFound := receiveMessage(t, second.send)
	if firstFound.Type != EventQuickMatchFound || secondFound.Type != EventQuickMatchFound {
		t.Fatalf("expected quick_match_found for both players, got %s/%s", firstFound.Type, secondFound.Type)
	}
	firstPayload, ok := firstFound.Payload.(map[string]interface{})
	if !ok || firstPayload["game_type"] != platformgames.GameTypeCaro {
		t.Fatalf("expected quick_match_found payload to include game_type %q, got %#v", platformgames.GameTypeCaro, firstFound.Payload)
	}
	if first.GameRoomID == "" || first.GameRoomID != second.GameRoomID {
		t.Fatalf("expected both quick-match clients in same room")
	}
	if len(hub.matchQueue) != 0 {
		t.Fatalf("expected empty queue after pairing, got %d", len(hub.matchQueue))
	}
}

func TestQuickMatchCancelAndDisconnectRemoveQueuedClients(t *testing.T) {
	hub := NewHub()
	first := testClientWithHub(hub, "user-a", "Alice")
	second := testClientWithHub(hub, "user-b", "Bob")
	activateClients(hub, first, second)

	hub.EnqueueQuickMatch(first, platformgames.GameTypeCaro)
	hub.DequeueQuickMatch(first)
	if code := receiveMessage(t, first.send).Type; code != EventQuickMatchCancelled {
		t.Fatalf("expected quick_match_cancelled, got %s", code)
	}
	if len(hub.matchQueue) != 0 {
		t.Fatalf("expected empty queue after cancellation, got %d", len(hub.matchQueue))
	}

	hub.EnqueueQuickMatch(second, platformgames.GameTypeCaro)
	hub.handleClientDisconnect(second)
	if len(hub.matchQueue) != 0 {
		t.Fatalf("expected disconnect to remove queued client, got %d", len(hub.matchQueue))
	}
}

func TestChessRoomLegalMoveAndScholarsMate(t *testing.T) {
	hub := NewHub()
	playerX := testClientWithHub(hub, "user-x", "Alice")
	playerO := testClientWithHub(hub, "user-o", "Bob")
	activateClients(hub, playerX, playerO)

	hub.HandleCreateRoom(playerX, platformgames.GameTypeChess)
	created := receiveMessage(t, playerX.send)
	if created.Type != EventGameState {
		t.Fatalf("expected game_state on chess room creation, got %s", created.Type)
	}
	state, ok := created.Payload.(map[string]interface{})
	if !ok {
		t.Fatalf("expected map payload, got %#v", created.Payload)
	}
	if state["game_type"] != platformgames.GameTypeChess {
		t.Fatalf("expected game_type chess, got %#v", state["game_type"])
	}
	fen, ok := state["fen"].(string)
	if !ok || fen == "" {
		t.Fatalf("expected fen field in chess game_state, got %#v", state["fen"])
	}
	code := state["room_code"].(string)

	hub.HandleJoinRoom(playerO, code, platformgames.GameTypeChess)
	receiveMessage(t, playerX.send)
	receiveMessage(t, playerO.send)

	room := hub.gameRooms[playerX.GameRoomID]
	if room == nil || !room.Started {
		t.Fatalf("expected started chess room")
	}

	scholarsMate := []struct{ from, to, prom string }{
		{"e2", "e4", ""},
		{"e7", "e5", ""},
		{"d1", "h5", ""},
		{"b8", "c6", ""},
		{"f1", "c4", ""},
		{"g8", "f6", ""},
		{"h5", "f7", ""},
	}

	players := []*Client{playerX, playerO, playerX, playerO, playerX, playerO, playerX}
	for i, mv := range scholarsMate {
		hub.HandleChessMakeMove(players[i], mv.from, mv.to, mv.prom)
		xMsg := receiveMessage(t, playerX.send)
		oMsg := receiveMessage(t, playerO.send)
		if i < len(scholarsMate)-1 {
			if xMsg.Type != EventGameState || oMsg.Type != EventGameState {
				t.Fatalf("move %d: expected game_state, got %s/%s", i+1, xMsg.Type, oMsg.Type)
			}
		} else {
			if xMsg.Type != EventGameOver || oMsg.Type != EventGameOver {
				t.Fatalf("scholar's mate: expected game_over, got %s/%s", xMsg.Type, oMsg.Type)
			}
			endState, ok := xMsg.Payload.(map[string]interface{})
			if !ok {
				t.Fatalf("expected map payload for game_over, got %#v", xMsg.Payload)
			}
			if endState["winner"] != playerX.UserID {
				t.Fatalf("expected player X (white) to win Scholar's mate, got winner=%#v", endState["winner"])
			}
			if endState["result"] != "win" {
				t.Fatalf("expected result=win, got %#v", endState["result"])
			}
		}
	}
}

func TestChessRoomIllegalMoveReturnsError(t *testing.T) {
	hub := NewHub()
	playerX := testClientWithHub(hub, "user-x", "Alice")
	playerO := testClientWithHub(hub, "user-o", "Bob")
	activateClients(hub, playerX, playerO)

	hub.HandleCreateRoom(playerX, platformgames.GameTypeChess)
	created := receiveMessage(t, playerX.send)
	state := created.Payload.(map[string]interface{})
	code := state["room_code"].(string)

	hub.HandleJoinRoom(playerO, code, platformgames.GameTypeChess)
	receiveMessage(t, playerX.send)
	receiveMessage(t, playerO.send)

	hub.HandleChessMakeMove(playerX, "e2", "e5", "")
	if errCode := receiveErrorCode(t, playerX.send); errCode != "illegal_move" {
		t.Fatalf("expected illegal_move error, got %q", errCode)
	}
}

func testClient(userID, username string) *Client {
	return &Client{
		send:     make(chan *WSMessage, 256),
		UserID:   userID,
		Username: username,
	}
}

func testClientWithHub(hub *Hub, userID, username string) *Client {
	client := testClient(userID, username)
	client.hub = hub
	return client
}

func activateClients(hub *Hub, clients ...*Client) {
	hub.mu.Lock()
	defer hub.mu.Unlock()
	for _, client := range clients {
		hub.clients[client] = true
	}
}

func receiveMessage(t *testing.T, ch <-chan *WSMessage) *WSMessage {
	t.Helper()
	select {
	case msg := <-ch:
		return msg
	case <-time.After(time.Second):
		t.Fatal("timeout waiting for websocket message")
	}
	return nil
}

func receiveErrorCode(t *testing.T, ch <-chan *WSMessage) string {
	t.Helper()
	msg := receiveMessage(t, ch)
	if msg.Type != EventError {
		t.Fatalf("expected error event, got %s", msg.Type)
	}
	switch payload := msg.Payload.(type) {
	case ErrorPayload:
		return payload.Code
	case map[string]interface{}:
		code, _ := payload["code"].(string)
		return code
	default:
		t.Fatalf("unexpected error payload %#v", msg.Payload)
	}
	return ""
}

func assertRoomError(t *testing.T, err error, expectedCode string) {
	t.Helper()
	var roomErr RoomError
	if !errors.As(err, &roomErr) {
		t.Fatalf("expected RoomError %q, got %v", expectedCode, err)
	}
	if roomErr.Code != expectedCode {
		t.Fatalf("expected RoomError code %q, got %q", expectedCode, roomErr.Code)
	}
}
