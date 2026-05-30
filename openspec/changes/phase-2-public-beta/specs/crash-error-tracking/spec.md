# Spec: Crash and Error Tracking

## Purpose

Capture uncaught Flutter exceptions and forward them to the server so beta crash patterns are visible before users churn silently.

## Data Model

```go
// pkg/models/error_report.go
type ErrorReport struct {
    ID         primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    UserID     string             `bson:"user_id" json:"user_id"`
    Platform   string             `bson:"platform" json:"platform"`   // "android" | "ios" | "web"
    AppVersion string             `bson:"app_version" json:"app_version"`
    Error      string             `bson:"error" json:"error"`
    StackTrace string             `bson:"stack_trace" json:"stack_trace"` // truncated at 4096 chars
    CreatedAt  time.Time          `bson:"created_at" json:"created_at"`
}
```

## REST API

### Submit Error Report

`POST /api/errors`

Auth: required (Bearer token).

Rate limit: 10 per hour per user.

Request body:
```json
{
  "platform": "android",
  "app_version": "1.0.0",
  "error": "Null check operator used on a null value",
  "stack_trace": "..."
}
```

Response `201`: `{ "message": "Error recorded" }`.

Response `400`: missing required fields.

## Server Requirements

- **ERR-S-1**: Create `internal/errors/` package with `ErrorReportService` (MongoDB insert into `error_reports` collection) and `ErrorReportHandler`.
- **ERR-S-2**: Register `POST /api/errors` under the existing `protected` group with a 10/hour/user rate limiter.
- **ERR-S-3**: Truncate `stack_trace` to 4096 characters server-side before inserting.
- **ERR-S-4**: Log `slog.Error("flutter.crash", "user_id", ..., "error", ...)` on insert.

## Client Requirements

- **ERR-C-1**: In `main.dart`, inside `runApp`, set:
  ```dart
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _reportError(details.exceptionAsString(), details.stack?.toString() ?? '');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _reportError(error.toString(), stack.toString());
    return true;
  };
  ```
- **ERR-C-2**: `_reportError(String error, String stack)` is a top-level function that:
  - Returns immediately if the user is not authenticated (no access token available).
  - Calls `ApiService.submitErrorReport(...)` in a `try/catch` that silently swallows any HTTP error to avoid crash loops.
- **ERR-C-3**: Add `submitErrorReport` to `ApiService`:
  ```dart
  Future<void> submitErrorReport({
    required String error,
    required String stackTrace,
  }) async { ... }
  ```
  It posts to `POST /api/errors` with `platform` from `Platform.operatingSystem` and `appVersion` from `PackageInfo.fromPlatform()` (add `package_info_plus` dependency).
- **ERR-C-4**: Add `package_info_plus` to `client/pubspec.yaml`.
- **ERR-C-5**: `_reportError` silently fails if the server is unreachable; it must never throw and must never show UI to the user.

## Acceptance Criteria

- A deliberately thrown exception in the app results in a document in the `error_reports` MongoDB collection.
- The `stack_trace` field is never longer than 4096 characters.
- If the server is down, the app continues running without showing an error to the user.
- Unauthenticated users (not logged in) do not submit error reports.
