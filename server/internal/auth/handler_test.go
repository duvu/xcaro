package auth

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestWriteProfileError(t *testing.T) {
	gin.SetMode(gin.TestMode)

	testCases := []struct {
		name     string
		err      error
		expected int
	}{
		{name: "not found", err: ErrUserNotFound, expected: http.StatusNotFound},
		{name: "bad request", err: ErrCurrentPasswordInvalid, expected: http.StatusBadRequest},
		{name: "internal", err: errors.New("boom"), expected: http.StatusInternalServerError},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			recorder := httptest.NewRecorder()
			context, _ := gin.CreateTestContext(recorder)

			writeProfileError(context, tc.err)

			if recorder.Code != tc.expected {
				t.Fatalf("expected status %d, got %d", tc.expected, recorder.Code)
			}
		})
	}
}
