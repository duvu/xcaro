package auth

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/duvu/playverse/server/pkg/models"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Handler xử lý các request liên quan đến authentication và user management
type Handler struct {
	service *Service
}

func writeProfileError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, ErrUserNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
	case errors.Is(err, ErrCurrentPasswordInvalid),
		errors.Is(err, ErrPasswordInvalid),
		errors.Is(err, ErrEmailAlreadyUsed),
		errors.Is(err, ErrEmailUnchanged),
		errors.Is(err, ErrInvalidUserID),
		errors.Is(err, ErrEmailAlreadyVerified):
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
	}
}

// NewHandler tạo một handler mới
func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// Register godoc
// @Summary Đăng ký tài khoản mới
// @Description Tạo tài khoản mới với username và password
// @Tags auth
// @Accept json
// @Produce json
// @Param request body models.RegisterRequest true "Thông tin đăng ký"
// @Success 201 {object} map[string]interface{} "user và token"
// @Failure 400 {object} map[string]string "error"
// @Router /auth/register [post]
func (h *Handler) Register(c *gin.Context) {
	var req models.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	resp, err := h.service.Register(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, resp)
}

// Login godoc
// @Summary Đăng nhập
// @Description Đăng nhập với username và password
// @Tags auth
// @Accept json
// @Produce json
// @Param request body models.LoginRequest true "Thông tin đăng nhập"
// @Success 200 {object} map[string]interface{} "user và token"
// @Failure 401 {object} map[string]string "error"
// @Router /auth/login [post]
func (h *Handler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	resp, err := h.service.Login(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, resp)
}

func (h *Handler) Refresh(c *gin.Context) {
	var req models.RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	resp, err := h.service.Refresh(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, resp)
}

func (h *Handler) Logout(c *gin.Context) {
	userIDStr := c.GetString("user_id")
	objectID, err := primitive.ObjectIDFromHex(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user ID không hợp lệ"})
		return
	}

	if err := h.service.Logout(c.Request.Context(), objectID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "đăng xuất thành công"})
}

func (h *Handler) GetProfile(c *gin.Context) {
	// Lấy user ID từ context (đã được set bởi middleware auth)
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "không tìm thấy thông tin người dùng"})
		return
	}

	// Chuyển đổi userID sang ObjectID
	objectID, ok := userID.(primitive.ObjectID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "lỗi định dạng ID"})
		return
	}

	// Lấy thông tin profile
	user, err := h.service.GetProfile(c.Request.Context(), objectID)
	if err != nil {
		writeProfileError(c, err)
		return
	}

	c.JSON(http.StatusOK, user)
}

// UpdateProfile godoc
// @Summary Cập nhật profile
// @Description Cập nhật thông tin cá nhân của người dùng
// @Tags profile
// @Security ApiKeyAuth
// @Accept json
// @Produce json
// @Param request body models.UpdateProfileRequest true "Thông tin cập nhật"
// @Success 200 {object} map[string]string "message"
// @Failure 400,401 {object} map[string]string "error"
// @Router /profile [put]
func (h *Handler) UpdateProfile(c *gin.Context) {
	// Lấy user ID từ context
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "không tìm thấy thông tin người dùng"})
		return
	}

	objectID, ok := userID.(primitive.ObjectID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "lỗi định dạng ID"})
		return
	}

	// Parse request body
	var req models.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Cập nhật profile
	if err := h.service.UpdateProfile(c.Request.Context(), objectID, &req); err != nil {
		writeProfileError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "cập nhật profile thành công"})
}

// ChangePassword godoc
// @Summary Đổi mật khẩu
// @Description Đổi mật khẩu của người dùng hiện tại
// @Tags profile
// @Security ApiKeyAuth
// @Accept json
// @Produce json
// @Param request body models.ChangePasswordRequest true "Thông tin đổi mật khẩu"
// @Success 200 {object} map[string]string "message"
// @Failure 400,401 {object} map[string]string "error"
// @Router /profile/password [put]
func (h *Handler) ChangePassword(c *gin.Context) {
	// Lấy user ID từ context
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "không tìm thấy thông tin người dùng"})
		return
	}

	objectID, ok := userID.(primitive.ObjectID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "lỗi định dạng ID"})
		return
	}

	// Parse request body
	var req models.ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Đổi mật khẩu
	if err := h.service.ChangePassword(c.Request.Context(), objectID, &req); err != nil {
		writeProfileError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "đổi mật khẩu thành công"})
}

// UpdateEmail godoc
// @Summary Cập nhật email
// @Description Cập nhật email của người dùng hiện tại
// @Tags profile
// @Security ApiKeyAuth
// @Accept json
// @Produce json
// @Param request body models.UpdateEmailRequest true "Thông tin cập nhật email"
// @Success 200 {object} map[string]string "message"
// @Failure 400,401 {object} map[string]string "error"
// @Router /profile/email [put]
func (h *Handler) UpdateEmail(c *gin.Context) {
	// Lấy user ID từ context
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "không tìm thấy thông tin người dùng"})
		return
	}

	objectID, ok := userID.(primitive.ObjectID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "lỗi định dạng ID"})
		return
	}

	// Parse request body
	var req models.UpdateEmailRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Cập nhật email
	if err := h.service.UpdateEmail(c.Request.Context(), objectID, &req); err != nil {
		writeProfileError(c, err)
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "cập nhật email thành công, vui lòng xác minh email mới"})
}

// ListUsers godoc
// @Summary Lấy danh sách người dùng
// @Description Lấy danh sách tất cả người dùng (chỉ admin)
// @Tags admin
// @Security ApiKeyAuth
// @Produce json
// @Param page query int false "Số trang" default(1)
// @Param limit query int false "Số lượng mỗi trang" default(10)
// @Success 200 {object} models.ListUsersResponse
// @Failure 401,403 {object} map[string]string "error"
// @Router /admin/users [get]
func (h *Handler) ListUsers(c *gin.Context) {
	// Parse query parameters
	page := int64(1)
	limit := int64(10)
	if p, err := strconv.ParseInt(c.DefaultQuery("page", "1"), 10, 64); err == nil {
		page = p
	}
	if l, err := strconv.ParseInt(c.DefaultQuery("limit", "10"), 10, 64); err == nil {
		limit = l
	}

	// Lấy danh sách users
	response, err := h.service.ListUsers(c.Request.Context(), page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

// UpdateRole godoc
// @Summary Cập nhật role người dùng
// @Description Cập nhật role của một người dùng (chỉ admin)
// @Tags admin
// @Security ApiKeyAuth
// @Accept json
// @Produce json
// @Param id path string true "User ID"
// @Param request body models.UpdateRoleRequest true "Thông tin cập nhật role"
// @Success 200 {object} map[string]string "message"
// @Failure 400,401,403 {object} map[string]string "error"
// @Router /admin/users/{id}/role [put]
func (h *Handler) UpdateRole(c *gin.Context) {
	var req models.UpdateRoleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Kiểm tra người dùng hiện tại có phải admin không
	currentUser, exists := c.Get("user")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "không tìm thấy thông tin người dùng"})
		return
	}
	u, ok := currentUser.(*models.User)
	if !ok || u.Role != models.RoleAdmin {
		c.JSON(http.StatusForbidden, gin.H{"error": "chỉ admin mới có quyền thay đổi role"})
		return
	}

	// Cập nhật role
	if err := h.service.UpdateRole(c.Request.Context(), &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "cập nhật role thành công"})
}

// BanUser godoc
// @Summary Cấm người dùng
// @Description Cấm một người dùng (chỉ admin)
// @Tags admin
// @Security ApiKeyAuth
// @Accept json
// @Produce json
// @Param id path string true "User ID"
// @Param request body models.BanUserRequest true "Thông tin cấm người dùng"
// @Success 200 {object} map[string]string "message"
// @Failure 400,401,403 {object} map[string]string "error"
// @Router /admin/users/{id}/ban [post]
func (h *Handler) BanUser(c *gin.Context) {
	var req models.BanUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Ban user
	if err := h.service.BanUser(c.Request.Context(), &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "cấm người dùng thành công"})
}

// UnbanUser godoc
// @Summary Bỏ cấm người dùng
// @Description Bỏ cấm một người dùng (chỉ admin)
// @Tags admin
// @Security ApiKeyAuth
// @Accept json
// @Produce json
// @Param id path string true "User ID"
// @Param request body models.UnbanUserRequest true "Thông tin bỏ cấm người dùng"
// @Success 200 {object} map[string]string "message"
// @Failure 400,401,403 {object} map[string]string "error"
// @Router /admin/users/{id}/unban [post]
func (h *Handler) UnbanUser(c *gin.Context) {
	var req models.UnbanUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Unban user
	if err := h.service.UnbanUser(c.Request.Context(), &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "bỏ cấm người dùng thành công"})
}

func (h *Handler) VerifyEmail(c *gin.Context) {
	token := c.Query("token")
	if err := h.service.VerifyEmail(c.Request.Context(), token); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	c.JSON(200, gin.H{"message": "Email verified successfully"})
}

func (h *Handler) ResendVerification(c *gin.Context) {
	userID := c.GetString("user_id")
	if err := h.service.ResendVerification(c.Request.Context(), userID); err != nil {
		writeProfileError(c, err)
		return
	}
	c.JSON(200, gin.H{"message": "Verification email sent"})
}
