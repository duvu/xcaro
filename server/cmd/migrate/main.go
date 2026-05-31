package main

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/joho/godotenv"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func main() {
	godotenv.Load()

	mongoURI := os.Getenv("MONGODB_URI")
	if mongoURI == "" {
		log.Fatal("MONGODB_URI not set")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatal(err)
	}
	defer client.Disconnect(ctx)

	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "playverse"
	}
	db := client.Database(dbName)

	result, err := db.Collection("users").UpdateMany(ctx, bson.M{}, bson.M{
		"$set": bson.M{"elo_rating": 1200, "email_verified": true},
	})
	if err != nil {
		log.Fatalf("migration failed: %v", err)
	}
	log.Printf("migration complete: matched=%d modified=%d", result.MatchedCount, result.ModifiedCount)
}
