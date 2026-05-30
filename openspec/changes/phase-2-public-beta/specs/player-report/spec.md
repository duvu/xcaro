# Player Report Spec

## Overview

Allow players to flag abusive, spammy, or suspected bot behavior during an active game. Reports are stored for admin review.

## Requirements

### Server — Model

- New model `Report` in `server/pkg/models/report.go`:
  ```go
  type Report struct {
    ID             primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    ReporterID     primitive.ObjectID `bson:"reporter_id" json:"reporter_id"`
    ReportedUserID primitive.ObjectID `bson:"reported_user_id" json:"reported_user_id"`
    GameID         string             `bson:"game_id" json:"game_id"`
    Reason         string             `bson:"reason" json:"reason"` // "abuse" | "spam" | "bot" | "other"
    Details        string             `bson:"details,omitempty" json:"details,omitempty"`
    CreatedAt      time.Time          `bson:"created_at" json:"created_at"`
  }
  ```
- `Reason` MUST be validated against allowed values: `"abuse"`, `"spam"`, `"bot"`, `"other"`.
- `Details` is optional; max 500 characters.
- A reporter MUST NOT report the same `reported_user_id` in the same `game_id` more than once; server returns `409` on duplicate.

### Server — Handler and Route

- New `internal/report/` package with `Handler.SubmitReport(c *gin.Context)`.
- Route: `POST /api/reports` — authenticated, rate-limited 3/hour/user.
- Request body: `{ "reported_user_id": "...", "game_id": "...", "reason": "...", "details": "..." }`.
- Response: `201` on success with `{ "id": "..." }`; `400` on validation error; `409` on duplicate; `429` on rate limit.
- Inserts report to MongoDB `reports` collection.
- No notification or admin email in Phase 2.
- Existing `GET /api/admin/users` admin route is sufficient for Phase 2 moderation review.

### Client — Report Dialog

- `GameScreen` MUST show a three-dot menu (or existing game menu) with a "Báo cáo đối thủ" option.
- Tapping opens a dialog with:
  - A radio group for reason: "Vi phạm" (abuse), "Spam chat" (spam), "Bot" (bot), "Khác" (other).
  - An optional freeform text field for details (max 500 chars).
  - "Hủy" and "Gửi báo cáo" buttons.
- Pressing "Gửi báo cáo":
  - Calls `POST /api/reports` with the current `game_id` and opponent's `user_id`.
  - On `201`: close dialog and show `SnackBar("Đã gửi báo cáo. Cảm ơn!")`.
  - On `409`: show `SnackBar("Bạn đã báo cáo người này trong trận này rồi.")`.
  - On `429`: show `SnackBar("Bạn đã gửi quá nhiều báo cáo. Thử lại sau.")`.
  - On other errors: show `SnackBar("Không thể gửi báo cáo. Thử lại.")`.
- The report option MUST only be visible during an active game against a human opponent (not AI, not offline).

## Acceptance Criteria

- A report submitted during an active game is stored in the `reports` collection with correct fields.
- Submitting a second report for the same user in the same game returns `409`.
- Submitting more than 3 reports per hour returns `429`.
- The dialog validates reason selection before allowing submission.
- Report option is not visible in AI or offline game modes.
