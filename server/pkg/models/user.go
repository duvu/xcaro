package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Role string

const (
	RoleAdmin  Role = "admin"
	RoleMod    Role = "mod"
	RolePlayer Role = "player"
)

type Permission string

const (
	// Game permissions
	PermCreateGame  Permission = "game:create"
	PermDeleteGame  Permission = "game:delete"
	PermManageGames Permission = "game:manage"

	// User permissions
	PermViewUsers   Permission = "user:view"
	PermManageUsers Permission = "user:manage"
	PermBanUsers    Permission = "user:ban"

	// Chat permissions
	PermDeleteMessages Permission = "chat:delete"
	PermMuteUsers      Permission = "chat:mute"
)

// RolePermissions định nghĩa quyền cho từng role
var RolePermissions = map[Role][]Permission{
	RoleAdmin: {
		PermCreateGame, PermDeleteGame, PermManageGames,
		PermViewUsers, PermManageUsers, PermBanUsers,
		PermDeleteMessages, PermMuteUsers,
	},
	RoleMod: {
		PermCreateGame, PermManageGames,
		PermViewUsers, PermBanUsers,
		PermDeleteMessages, PermMuteUsers,
	},
	RolePlayer: {
		PermCreateGame,
	},
}

type User struct {
	ID          primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Username    string             `json:"username" bson:"username"`
	Email       string             `json:"email" bson:"email"`
	Password    string             `json:"-" bson:"password"` // Không trả về password trong JSON
	Role        Role               `json:"role" bson:"role"`
	IsBanned    bool               `json:"is_banned" bson:"is_banned"`
	BanReason   string             `json:"ban_reason,omitempty" bson:"ban_reason,omitempty"`
	FullName    string             `json:"full_name" bson:"full_name"`
	Avatar      string             `json:"avatar" bson:"avatar"`
	DateOfBirth time.Time          `json:"date_of_birth" bson:"date_of_birth"`
	PhoneNumber string             `json:"phone_number" bson:"phone_number"`
	Bio         string             `json:"bio" bson:"bio"`
	GamesPlayed int                `json:"games_played" bson:"games_played"`
	GamesWon    int                `json:"games_won" bson:"games_won"`
	Rating      int                `json:"rating" bson:"rating"`
	CreatedAt   time.Time          `json:"created_at" bson:"created_at"`
	UpdatedAt   time.Time          `json:"updated_at" bson:"updated_at"`
}

// HasPermission kiểm tra xem user có quyền cụ thể không
func (u *User) HasPermission(permission Permission) bool {
	if u.IsBanned {
		return false
	}
	permissions, exists := RolePermissions[u.Role]
	if !exists {
		return false
	}
	for _, p := range permissions {
		if p == permission {
			return true
		}
	}
	return false
}

type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type RegisterRequest struct {
	Username string `json:"username" binding:"required,min=3,max=30"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
}

type UpdateProfileRequest struct {
	FullName    string    `json:"full_name" binding:"omitempty,max=100"`
	Avatar      string    `json:"avatar" binding:"omitempty,url"`
	DateOfBirth time.Time `json:"date_of_birth" binding:"omitempty"`
	PhoneNumber string    `json:"phone_number" binding:"omitempty,e164"`
	Bio         string    `json:"bio" binding:"omitempty,max=500"`
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password" binding:"required"`
	NewPassword     string `json:"new_password" binding:"required,min=6"`
}

type UpdateEmailRequest struct {
	NewEmail string `json:"new_email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type UpdateRoleRequest struct {
	UserID primitive.ObjectID `json:"user_id" binding:"required"`
	Role   Role               `json:"role" binding:"required,oneof=admin mod player"`
}

type BanUserRequest struct {
	UserID    primitive.ObjectID `json:"user_id" binding:"required"`
	BanReason string             `json:"ban_reason" binding:"required,min=1,max=500"`
}

type UnbanUserRequest struct {
	UserID primitive.ObjectID `json:"user_id" binding:"required"`
}

type ListUsersResponse struct {
	Users []User `json:"users"`
	Total int64  `json:"total"`
}
