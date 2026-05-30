package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"log/slog"
	"time"

	"github.com/duvu/xcaro/server/internal/email"
	"github.com/duvu/xcaro/server/pkg/models"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"golang.org/x/crypto/bcrypt"
)

type Service struct {
	db *mongo.Database
}

func NewService(db *mongo.Database) *Service {
	return &Service{db: db}
}

func (s *Service) Register(ctx context.Context, req *models.RegisterRequest) (*models.AuthResponse, error) {
	// Kiểm tra username đã tồn tại
	var existingUser models.User
	err := s.db.Collection("users").FindOne(ctx, bson.M{"username": req.Username}).Decode(&existingUser)
	if err == nil {
		return nil, errors.New("tên người dùng đã tồn tại")
	}
	if err != mongo.ErrNoDocuments {
		return nil, err
	}

	// Kiểm tra email đã tồn tại
	err = s.db.Collection("users").FindOne(ctx, bson.M{"email": req.Email}).Decode(&existingUser)
	if err == nil {
		return nil, errors.New("email đã tồn tại")
	}
	if err != mongo.ErrNoDocuments {
		return nil, err
	}

	// Mã hóa mật khẩu
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	// Tạo user mới
	now := time.Now()

	tokenBytes := make([]byte, 32)
	if _, err := rand.Read(tokenBytes); err != nil {
		return nil, err
	}
	plainToken := hex.EncodeToString(tokenBytes)
	hash := sha256.Sum256([]byte(plainToken))
	hashedToken := hex.EncodeToString(hash[:])

	user := &models.User{
		Username:             req.Username,
		Email:                req.Email,
		Password:             string(hashedPassword),
		EmailVerified:        false,
		EmailVerifyToken:     hashedToken,
		EmailVerifyExpiresAt: now.Add(24 * time.Hour),
		EloRating:            1200,
		CreatedAt:            now,
		UpdatedAt:            now,
	}

	// Lưu vào database
	result, err := s.db.Collection("users").InsertOne(ctx, user)
	if err != nil {
		return nil, err
	}
	user.ID = result.InsertedID.(primitive.ObjectID)

	go func() {
		if err := email.SendVerificationEmail(user.Email, plainToken); err != nil {
			slog.Error("send verification email failed", "event", "register", "email", user.Email, "error", err)
		}
	}()

	accessToken, err := GenerateToken(user.ID.Hex())
	if err != nil {
		return nil, err
	}
	refreshToken, err := GenerateRefreshToken(user.ID.Hex())
	if err != nil {
		return nil, err
	}

	refreshExpiry := time.Now().Add(7 * 24 * time.Hour)
	_, err = s.db.Collection("users").UpdateOne(ctx, bson.M{"_id": user.ID}, bson.M{
		"$set": bson.M{
			"refresh_token":            refreshToken,
			"refresh_token_expires_at": refreshExpiry,
		},
	})
	if err != nil {
		return nil, err
	}

	return &models.AuthResponse{
		User:         user,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (s *Service) Login(ctx context.Context, req *models.LoginRequest) (*models.AuthResponse, error) {
	var user models.User
	err := s.db.Collection("users").FindOne(ctx, bson.M{"username": req.Username}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("tên người dùng hoặc mật khẩu không đúng")
		}
		return nil, err
	}

	// Kiểm tra mật khẩu
	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password))
	if err != nil {
		return nil, errors.New("tên người dùng hoặc mật khẩu không đúng")
	}

	accessToken, err := GenerateToken(user.ID.Hex())
	if err != nil {
		return nil, err
	}
	refreshToken, err := GenerateRefreshToken(user.ID.Hex())
	if err != nil {
		return nil, err
	}

	refreshExpiry := time.Now().Add(7 * 24 * time.Hour)
	_, err = s.db.Collection("users").UpdateOne(ctx, bson.M{"_id": user.ID}, bson.M{
		"$set": bson.M{
			"refresh_token":            refreshToken,
			"refresh_token_expires_at": refreshExpiry,
		},
	})
	if err != nil {
		return nil, err
	}

	return &models.AuthResponse{
		User:         &user,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (s *Service) Refresh(ctx context.Context, req *models.RefreshTokenRequest) (*models.AuthResponse, error) {
	userID, err := ValidateRefreshToken(req.RefreshToken)
	if err != nil {
		return nil, errors.New("refresh token không hợp lệ")
	}

	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return nil, errors.New("user ID không hợp lệ")
	}

	var user models.User
	err = s.db.Collection("users").FindOne(ctx, bson.M{"_id": objectID}).Decode(&user)
	if err != nil {
		return nil, errors.New("không tìm thấy người dùng")
	}

	if user.RefreshToken != req.RefreshToken || time.Now().After(user.RefreshTokenExpiresAt) {
		return nil, errors.New("refresh token không hợp lệ hoặc đã hết hạn")
	}

	newAccessToken, err := GenerateToken(userID)
	if err != nil {
		return nil, err
	}
	newRefreshToken, err := GenerateRefreshToken(userID)
	if err != nil {
		return nil, err
	}

	refreshExpiry := time.Now().Add(7 * 24 * time.Hour)
	_, err = s.db.Collection("users").UpdateOne(ctx, bson.M{"_id": objectID}, bson.M{
		"$set": bson.M{
			"refresh_token":            newRefreshToken,
			"refresh_token_expires_at": refreshExpiry,
		},
	})
	if err != nil {
		return nil, err
	}

	return &models.AuthResponse{
		User:         &user,
		AccessToken:  newAccessToken,
		RefreshToken: newRefreshToken,
	}, nil
}

func (s *Service) Logout(ctx context.Context, userID primitive.ObjectID) error {
	_, err := s.db.Collection("users").UpdateOne(ctx, bson.M{"_id": userID}, bson.M{
		"$unset": bson.M{
			"refresh_token":            "",
			"refresh_token_expires_at": "",
		},
	})
	return err
}

func (s *Service) GetProfile(ctx context.Context, userID primitive.ObjectID) (*models.User, error) {
	var user models.User
	err := s.db.Collection("users").FindOne(ctx, bson.M{"_id": userID}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, errors.New("không tìm thấy người dùng")
		}
		return nil, err
	}
	return &user, nil
}

func (s *Service) UpdateProfile(ctx context.Context, userID primitive.ObjectID, req *models.UpdateProfileRequest) error {
	update := bson.M{
		"$set": bson.M{
			"full_name":     req.FullName,
			"avatar":        req.Avatar,
			"date_of_birth": req.DateOfBirth,
			"phone_number":  req.PhoneNumber,
			"bio":           req.Bio,
			"updated_at":    time.Now(),
		},
	}

	result, err := s.db.Collection("users").UpdateOne(ctx, bson.M{"_id": userID}, update)
	if err != nil {
		return err
	}
	if result.MatchedCount == 0 {
		return errors.New("không tìm thấy người dùng")
	}
	return nil
}

func (s *Service) ChangePassword(ctx context.Context, userID primitive.ObjectID, req *models.ChangePasswordRequest) error {
	// Lấy thông tin user hiện tại
	var user models.User
	err := s.db.Collection("users").FindOne(ctx, bson.M{"_id": userID}).Decode(&user)
	if err != nil {
		return err
	}

	// Kiểm tra mật khẩu hiện tại
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.CurrentPassword)); err != nil {
		return errors.New("mật khẩu hiện tại không đúng")
	}

	// Hash mật khẩu mới
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	// Cập nhật mật khẩu
	update := bson.M{
		"$set": bson.M{
			"password":   string(hashedPassword),
			"updated_at": time.Now(),
		},
	}

	result, err := s.db.Collection("users").UpdateOne(ctx, bson.M{"_id": userID}, update)
	if err != nil {
		return err
	}
	if result.MatchedCount == 0 {
		return errors.New("không tìm thấy người dùng")
	}
	return nil
}

func (s *Service) UpdateEmail(ctx context.Context, userID primitive.ObjectID, req *models.UpdateEmailRequest) error {
	// Kiểm tra email mới đã tồn tại chưa
	count, err := s.db.Collection("users").CountDocuments(ctx, bson.M{"email": req.NewEmail})
	if err != nil {
		return err
	}
	if count > 0 {
		return errors.New("email đã được sử dụng")
	}

	// Lấy thông tin user hiện tại
	var user models.User
	err = s.db.Collection("users").FindOne(ctx, bson.M{"_id": userID}).Decode(&user)
	if err != nil {
		return err
	}

	// Kiểm tra mật khẩu
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		return errors.New("mật khẩu không đúng")
	}

	// Cập nhật email
	update := bson.M{
		"$set": bson.M{
			"email":      req.NewEmail,
			"updated_at": time.Now(),
		},
	}

	result, err := s.db.Collection("users").UpdateOne(ctx, bson.M{"_id": userID}, update)
	if err != nil {
		return err
	}
	if result.MatchedCount == 0 {
		return errors.New("không tìm thấy người dùng")
	}
	return nil
}

func (s *Service) ListUsers(ctx context.Context, page, limit int64) (*models.ListUsersResponse, error) {
	// Tính skip để phân trang
	skip := (page - 1) * limit

	// Lấy tổng số users
	total, err := s.db.Collection("users").CountDocuments(ctx, bson.M{})
	if err != nil {
		return nil, err
	}

	// Lấy danh sách users
	cursor, err := s.db.Collection("users").Find(ctx, bson.M{}, options.Find().
		SetSkip(skip).
		SetLimit(limit).
		SetSort(bson.M{"created_at": -1}))
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var users []models.User
	if err := cursor.All(ctx, &users); err != nil {
		return nil, err
	}

	return &models.ListUsersResponse{
		Users: users,
		Total: total,
	}, nil
}

func (s *Service) UpdateRole(ctx context.Context, req *models.UpdateRoleRequest) error {
	// Cập nhật role
	update := bson.M{
		"$set": bson.M{
			"role":       req.Role,
			"updated_at": time.Now(),
		},
	}

	result, err := s.db.Collection("users").UpdateOne(ctx, bson.M{"_id": req.UserID}, update)
	if err != nil {
		return err
	}
	if result.MatchedCount == 0 {
		return errors.New("không tìm thấy người dùng")
	}
	return nil
}

func (s *Service) BanUser(ctx context.Context, req *models.BanUserRequest) error {
	// Kiểm tra user có tồn tại không
	var user models.User
	err := s.db.Collection("users").FindOne(ctx, bson.M{"_id": req.UserID}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return errors.New("không tìm thấy người dùng")
		}
		return err
	}

	// Không cho phép ban admin
	if user.Role == models.RoleAdmin {
		return errors.New("không thể cấm admin")
	}

	// Cập nhật trạng thái ban
	update := bson.M{
		"$set": bson.M{
			"is_banned":  true,
			"ban_reason": req.BanReason,
			"updated_at": time.Now(),
		},
	}

	result, err := s.db.Collection("users").UpdateOne(ctx, bson.M{"_id": req.UserID}, update)
	if err != nil {
		return err
	}
	if result.MatchedCount == 0 {
		return errors.New("không tìm thấy người dùng")
	}
	return nil
}

func (s *Service) UnbanUser(ctx context.Context, req *models.UnbanUserRequest) error {
	// Cập nhật trạng thái unban
	update := bson.M{
		"$set": bson.M{
			"is_banned":  false,
			"ban_reason": "",
			"updated_at": time.Now(),
		},
	}

	result, err := s.db.Collection("users").UpdateOne(ctx, bson.M{"_id": req.UserID}, update)
	if err != nil {
		return err
	}
	if result.MatchedCount == 0 {
		return errors.New("không tìm thấy người dùng")
	}
	return nil
}

func (s *Service) VerifyEmail(ctx context.Context, token string) error {
	hash := sha256.Sum256([]byte(token))
	hashedToken := hex.EncodeToString(hash[:])

	var user models.User
	err := s.db.Collection("users").FindOne(ctx, bson.M{"email_verify_token": hashedToken}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return errors.New("invalid or expired token")
		}
		return err
	}

	if time.Now().After(user.EmailVerifyExpiresAt) {
		return errors.New("token has expired")
	}

	_, err = s.db.Collection("users").UpdateOne(ctx, bson.M{"_id": user.ID}, bson.M{
		"$set":   bson.M{"email_verified": true, "updated_at": time.Now()},
		"$unset": bson.M{"email_verify_token": "", "email_verify_expires_at": ""},
	})
	return err
}

func (s *Service) ResendVerification(ctx context.Context, userID string) error {
	objectID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		return errors.New("invalid user ID")
	}

	var user models.User
	if err := s.db.Collection("users").FindOne(ctx, bson.M{"_id": objectID}).Decode(&user); err != nil {
		return errors.New("user not found")
	}
	if user.EmailVerified {
		return errors.New("email already verified")
	}

	tokenBytes := make([]byte, 32)
	if _, err := rand.Read(tokenBytes); err != nil {
		return err
	}
	plainToken := hex.EncodeToString(tokenBytes)
	hsh := sha256.Sum256([]byte(plainToken))
	hashedToken := hex.EncodeToString(hsh[:])

	_, err = s.db.Collection("users").UpdateOne(ctx, bson.M{"_id": objectID}, bson.M{
		"$set": bson.M{
			"email_verify_token":      hashedToken,
			"email_verify_expires_at": time.Now().Add(24 * time.Hour),
			"updated_at":              time.Now(),
		},
	})
	if err != nil {
		return err
	}

	go func() {
		if err := email.SendVerificationEmail(user.Email, plainToken); err != nil {
			slog.Error("send verification email failed", "event", "resend", "email", user.Email, "error", err)
		}
	}()
	return nil
}
