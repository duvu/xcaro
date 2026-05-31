package social

import (
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func TestPairKeyNormalizesOrder(t *testing.T) {
	a := primitive.NewObjectID().Hex()
	b := primitive.NewObjectID().Hex()
	if pairKey(a, b) != pairKey(b, a) {
		t.Fatalf("pairKey should be order independent")
	}
}

func TestNormalizePageLimit(t *testing.T) {
	page, limit := normalizePageLimit(-2, 500)
	if page != 1 || limit != 100 {
		t.Fatalf("expected page 1 and limit cap 100, got %d/%d", page, limit)
	}
}

func TestGameRecordDTOMapsOutcomeFromCurrentUser(t *testing.T) {
	userID := "user-a"
	doc := bson.M{"_id": primitive.NewObjectID(), "room_id": "room-1", "player_x": userID, "player_o": "user-b", "winner": userID, "result": "win", "created_at": time.Now()}
	record := gameRecordDTO(userID, doc)
	if record.Outcome != "win" || record.Opponent != "user-b" {
		t.Fatalf("expected win against user-b, got outcome=%s opponent=%s", record.Outcome, record.Opponent)
	}

	doc["winner"] = "user-b"
	record = gameRecordDTO(userID, doc)
	if record.Outcome != "loss" {
		t.Fatalf("expected loss, got %s", record.Outcome)
	}

	doc["result"] = "draw"
	doc["winner"] = ""
	record = gameRecordDTO(userID, doc)
	if record.Outcome != "draw" {
		t.Fatalf("expected draw, got %s", record.Outcome)
	}
}
