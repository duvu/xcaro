# Danh sách việc cần làm

## Client

### Chức năng
- [ ] Hoàn thiện chức năng đăng nhập/đăng ký
  - [ ] Thêm xác thực email
  - [ ] Quên mật khẩu
  - [ ] Đăng nhập bằng Google/Facebook
- [ ] Cải thiện AI
  - [ ] Thêm các mức độ khó
  - [ ] Tối ưu thuật toán đánh giá nước đi
  - [ ] Thêm khả năng học từ người chơi
- [ ] Chức năng chơi online
  - [ ] Tạo/tham gia phòng chơi
  - [ ] Chat trong game
  - [ ] Xem thông tin đối thủ
  - [ ] Bảng xếp hạng
- [ ] Lưu lịch sử game
  - [ ] Xem lại các ván đã chơi
  - [ ] Thống kê thắng/thua
  - [ ] Xuất file PGN

### Giao diện
- [ ] Thêm animation cho các nước đi
- [ ] Cải thiện giao diện mobile
- [ ] Thêm theme sáng/tối
- [ ] Thêm âm thanh (đã có file nhưng chưa hoạt động)
- [ ] Thêm tutorial cho người mới

### Kỹ thuật
- [ ] Tối ưu performance
  - [ ] Lazy loading các component
  - [ ] Caching API calls
  - [ ] Giảm kích thước bundle
- [ ] Unit tests
- [ ] Integration tests
- [ ] E2E tests
- [ ] CI/CD pipeline

## Server

### API
- [ ] Authentication
  - [ ] JWT refresh token
  - [ ] OAuth2 providers
  - [ ] Rate limiting
- [ ] Game logic
  - [ ] Validate nước đi
  - [ ] Xử lý timeout
  - [ ] Xử lý disconnect
- [ ] Websocket
  - [ ] Xử lý reconnect
  - [ ] Room management
  - [ ] Broadcasting events

### Database
- [ ] Schema migration
- [ ] Indexes cho queries
- [ ] Caching layer (Redis)
- [ ] Backup strategy

### Deployment
- [ ] Docker compose cho development
- [ ] Kubernetes manifests cho production
- [ ] Monitoring
  - [ ] Logging (ELK stack)
  - [ ] Metrics (Prometheus)
  - [ ] Tracing (Jaeger)
- [ ] Auto-scaling
- [ ] Load balancing

### Security
- [ ] SSL/TLS
- [ ] CORS policy
- [ ] Input validation
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] CSRF protection
- [ ] Security headers
- [ ] Rate limiting
- [ ] DDoS protection

### Documentation
- [ ] API documentation
- [ ] Deployment guide
- [ ] Development guide
- [ ] Architecture diagram
- [ ] Database schema
- [ ] Sequence diagrams cho các luồng chính

## DevOps
- [ ] Git workflow
  - [ ] Branch strategy
  - [ ] Code review process
  - [ ] Release process
- [ ] CI/CD
  - [ ] Unit tests
  - [ ] Integration tests
  - [ ] Security scans
  - [ ] Performance tests
  - [ ] Automated deployment
- [ ] Monitoring
  - [ ] Uptime monitoring
  - [ ] Error tracking
  - [ ] Performance monitoring
  - [ ] User analytics

## Testing
- [ ] Unit tests
  - [ ] Client
  - [ ] Server
- [ ] Integration tests
  - [ ] API endpoints
  - [ ] WebSocket connections
- [ ] E2E tests
  - [ ] Game flows
  - [ ] Authentication flows
- [ ] Performance tests
  - [ ] Load testing
  - [ ] Stress testing
  - [ ] Scalability testing 