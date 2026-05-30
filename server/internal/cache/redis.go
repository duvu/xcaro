package cache

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/redis/go-redis/v9"
)

var RedisClient *redis.Client

func InitRedis() {
	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		redisURL = "redis://localhost:6379"
	}

	opts, err := redis.ParseURL(redisURL)
	if err != nil {
		log.Printf("[cache] WARNING: failed to parse REDIS_URL: %v — Redis disabled", err)
		return
	}

	client := redis.NewClient(opts)
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		log.Printf("[cache] WARNING: cannot connect to Redis: %v — Redis disabled", err)
		return
	}

	RedisClient = client
	log.Println("[cache] Redis connected")
}

func Get(ctx context.Context, key string) (string, error) {
	if RedisClient == nil {
		return "", redis.Nil
	}
	return RedisClient.Get(ctx, key).Result()
}

func Set(ctx context.Context, key, value string, ttl time.Duration) error {
	if RedisClient == nil {
		return nil
	}
	return RedisClient.Set(ctx, key, value, ttl).Err()
}

func Del(ctx context.Context, key string) error {
	if RedisClient == nil {
		return nil
	}
	return RedisClient.Del(ctx, key).Err()
}
