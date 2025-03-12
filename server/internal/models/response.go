package models

// APIResponse là format chuẩn cho tất cả các API response
type APIResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
	Meta    *MetaData   `json:"meta,omitempty"`
}

// MetaData chứa thông tin phân trang và các metadata khác
type MetaData struct {
	Page      int   `json:"page,omitempty"`
	Limit     int   `json:"limit,omitempty"`
	Total     int64 `json:"total,omitempty"`
	TotalPage int   `json:"total_page,omitempty"`
}

// NewSuccessResponse tạo response thành công
func NewSuccessResponse(data interface{}) *APIResponse {
	return &APIResponse{
		Success: true,
		Data:    data,
	}
}

// NewErrorResponse tạo response lỗi
func NewErrorResponse(err string) *APIResponse {
	return &APIResponse{
		Success: false,
		Error:   err,
	}
}

// NewPaginationResponse tạo response có phân trang
func NewPaginationResponse(data interface{}, page, limit int, total int64) *APIResponse {
	totalPage := int(total) / limit
	if int(total)%limit > 0 {
		totalPage++
	}

	return &APIResponse{
		Success: true,
		Data:    data,
		Meta: &MetaData{
			Page:      page,
			Limit:     limit,
			Total:     total,
			TotalPage: totalPage,
		},
	}
}
