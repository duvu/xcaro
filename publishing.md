# Hướng dẫn Build và Publish Ứng dụng Caro

## I. Chuẩn bị

### 1. Tài khoản Developer
- **Google Play**: Đăng ký tài khoản Google Play Console (phí $25 một lần duy nhất)
  - Truy cập: https://play.google.com/console
  - Điền thông tin và thanh toán phí

- **App Store**: Đăng ký Apple Developer Program (phí $99/năm)
  - Truy cập: https://developer.apple.com
  - Đăng ký tài khoản và thanh toán phí

### 2. Cài đặt công cụ phát triển
- **Android Studio**: https://developer.android.com/studio
- **Xcode**: Tải từ Mac App Store (chỉ cho macOS)

## II. Build cho Android

### 1. Tạo keystore cho ứng dụng
```bash
keytool -genkey -v -keystore android/app/xcaro-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias xcaro
```

### 2. Cập nhật thông tin keystore
Mở file `android/app/build.gradle`, thay đổi mật khẩu trong phần `signingConfigs`:
```gradle
signingConfigs {
    release {
        storeFile file("xcaro-key.jks")
        storePassword "mật_khẩu_của_bạn"
        keyAlias "xcaro"
        keyPassword "mật_khẩu_key_của_bạn"
    }
}
```

### 3. Build app bundle
```bash
flutter build appbundle
```
File build sẽ nằm tại: `build/app/outputs/bundle/release/app-release.aab`

### 4. Đăng ký ứng dụng trên Google Play Console
1. Tạo ứng dụng mới
2. Điền thông tin cơ bản:
   - Tên ứng dụng
   - Mô tả ngắn/dài
   - Icon, ảnh screenshot
   - Phân loại ứng dụng
3. Tải file .aab lên
4. Điền thông tin về quyền riêng tư
5. Chọn các quốc gia phát hành
6. Submit để review

## III. Build cho iOS

### 1. Cấu hình Xcode
1. Mở Xcode
2. Mở file `ios/Runner.xcworkspace`
3. Chọn "Runner" trong navigator
4. Trong "Signing & Capabilities":
   - Chọn Team của bạn
   - Cập nhật Bundle Identifier: `vn.x51.game2d.xcaro`

### 2. Build ứng dụng
```bash
flutter build ipa
```
File build sẽ nằm tại: `build/ios/ipa/xcaro.ipa`

### 3. Đăng ký ứng dụng trên App Store Connect
1. Truy cập https://appstoreconnect.apple.com
2. Tạo ứng dụng mới
3. Điền thông tin:
   - Tên ứng dụng
   - Mô tả
   - Screenshots
   - Icon
   - Phân loại
4. Tải file .ipa lên TestFlight để test
5. Sau khi test OK, submit để review

## IV. Các lưu ý quan trọng

### 1. Chính sách quyền riêng tư
- Tạo trang web chính sách quyền riêng tư
- Thêm link vào thông tin ứng dụng

### 2. Tài liệu hỗ trợ
- Chuẩn bị tài liệu hướng dẫn sử dụng
- Email hỗ trợ người dùng

### 3. Phiên bản
- Android: Cập nhật `versionCode` và `versionName` trong `android/app/build.gradle`
- iOS: Cập nhật `version` và `build-number` trong `pubspec.yaml`

### 4. Testing
- Test kỹ ứng dụng trước khi submit
- Sử dụng TestFlight cho iOS
- Tạo phiên bản internal testing trên Google Play

### 5. Thời gian review
- Google Play: 2-3 ngày
- App Store: 1-2 ngày 