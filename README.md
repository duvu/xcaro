# PlayVerse

Game cờ caro đơn giản được viết bằng Flutter và Dart.

## Cấu trúc dự án

- `client/`: Ứng dụng Flutter cho phía client
- `server/`: Server backend (đang phát triển)

## Tính năng

- [x] Chơi 2 người trên cùng thiết bị
- [x] Hiệu ứng âm thanh khi đánh và thắng
- [x] Giao diện đơn giản, dễ sử dụng
- [x] Chơi với máy (AI) — Easy / Medium / Hard
- [x] Chơi online với người khác (JWT auth + WebSocket)
- [x] Bảng xếp hạng Elo
- [x] Chat trong game

## Cài đặt

### Client

1. Di chuyển vào thư mục client:
```bash
cd client
```

2. Cài đặt dependencies:
```bash
flutter pub get
```

3. Chạy ứng dụng:
```bash
flutter run
```

### Server

Chi tiết sẽ được cập nhật sau.

## CI/CD

Two GitHub Actions workflows are included in `.github/workflows/`:

- **`pr.yml`** — runs on every PR to `main`: `go vet`, `go test`, `flutter analyze`, `flutter test`
- **`deploy.yml`** — runs on push to `main`: builds Docker image, pushes to GHCR, deploys via SSH

### Required GitHub Actions Secrets

Configure these secrets in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `GHCR_TOKEN` | GitHub Personal Access Token with `write:packages` scope (for pushing to GHCR) |
| `DEPLOY_SSH_KEY` | Private SSH key for connecting to the deploy server |
| `DEPLOY_HOST` | Hostname or IP of the deploy server |
| `DEPLOY_USER` | SSH username on the deploy server |

The deploy workflow SSHs into the server and runs `docker-compose pull && docker-compose up -d` in `~/playverse/`.

## Release Readiness

Phase 1 stabilization evidence lives in:

- [`docs/release-readiness.md`](docs/release-readiness.md) — release gate checklist
- [`docs/RELEASE_EVIDENCE.md`](docs/RELEASE_EVIDENCE.md) — command output summary and go/no-go decision
- [`docs/qa-matrix.md`](docs/qa-matrix.md) — manual QA matrix and environment blockers

Canonical validation commands:

```bash
cd server
go build ./...
go vet ./...
go test ./...
```

```bash
cd client
flutter pub get
flutter analyze
flutter test
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 flutter build apk --release
```

## License

MIT License - xem file [LICENSE](LICENSE) để biết thêm chi tiết.
