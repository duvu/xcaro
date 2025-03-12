package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Role string
type Permission string

const (
	RoleAdmin Role = "admin"
	RoleUser  Role = "user"
	RoleGuest Role = "guest"
)

const (
	PermCreateGame   Permission = "create_game"
	PermJoinGame     Permission = "join_game"
	PermStartStream  Permission = "start_stream"
	PermModerateChat Permission = "moderate_chat"
)

type User struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Username    string             `bson:"username" json:"username"`
	Email       string             `bson:"email" json:"email"`
	Password    string             `bson:"password" json:"-"`
	Role        Role               `bson:"role" json:"role"`
	Permissions []Permission       `bson:"permissions" json:"permissions"`
	CreatedAt   time.Time          `bson:"created_at" json:"created_at"`
	UpdatedAt   time.Time          `bson:"updated_at" json:"updated_at"`
	LastLoginAt *time.Time         `bson:"last_login_at,omitempty" json:"last_login_at,omitempty"`
}

// HasPermission kiểm tra xem user có quyền cụ thể không
func (u *User) HasPermission(permission Permission) bool {
	if u.Role == RoleAdmin {
		return true
	}

	for _, p := range u.Permissions {
		if p == permission {
			return true
		}
	}
	return false
}

// HasRole kiểm tra role của user
func (u *User) HasRole(role Role) bool {
	return u.Role == role
}
