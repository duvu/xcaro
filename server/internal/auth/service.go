package auth

import (
	"context"
	"errors"
	"time"

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

func (s *Service) Register(ctx context.Context, req *models.RegisterRequest) (*models.User, error) {
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
	user := &models.User{
		Username:  req.Username,
		Email:     req.Email,
		Password:  string(hashedPassword),
		CreatedAt: now,
		UpdatedAt: now,
	}

	// Lưu vào database
	result, err := s.db.Collection("users").InsertOne(ctx, user)
	if err != nil {
		return nil, err
	}

	user.ID = result.InsertedID.(primitive.ObjectID)
	return user, nil
}

func (s *Service) Login(ctx context.Context, req *models.LoginRequest) (*models.User, error) {
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

	return &user, nil
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
