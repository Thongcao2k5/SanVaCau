# Lập trình trên thiết bị di động — Sân & Cầu

Đồ án quản lý sân cầu lông và cửa hàng dụng cụ thể thao, gồm ứng dụng Flutter, REST API Node.js/TypeScript và PostgreSQL.

## Thành phần

- `frontend/san_va_cau_app`: ứng dụng Flutter cho Android/Windows/Web.
- `backend`: Express + TypeScript + Prisma + PostgreSQL.
- `data-crawl`: mã thu thập và dữ liệu mẫu sản phẩm.
- `SanVaCau_Database_PostgreSQL.sql`: cấu trúc database SQL tham khảo.
- `SanVaCau_SeedData_PostgreSQL_Clean.sql`: dữ liệu mẫu SQL.
- `backend/prisma/schema.prisma`: schema được backend sử dụng.
- `backend/prisma/seed.ts`: seed chính, có thể chạy lặp lại.

Không commit file `.env` thật. Các file `.env.example` chỉ chứa placeholder.

## Thiết lập sau khi clone hoặc merge

- Backend: chạy `npm ci`, tạo `backend/.env` theo `.env.example`, rồi chạy
  `npx prisma generate`. Database đã có dữ liệu cần `npx prisma db push`
  để bổ sung các trường theo schema hiện tại; không dùng tùy chọn bỏ qua cảnh báo mất dữ liệu.
- Database mới: dùng snapshot theo `database/README.md`, sau đó chạy
  `npm run seed:products` trong `backend` để bổ sung biến thể demo.
- Flutter đã kiểm tra với Flutter **3.47.2 / Dart 3.13.2**. Trong
  `frontend/san_va_cau_app`, chạy `flutter pub get`. Giữ `pubspec.lock` và
  `backend/package-lock.json` khi merge để cài lại đúng phiên bản thư viện.
- VS Code có đề xuất extension Dart và Flutter trong `.vscode/extensions.json`.
  Android Studio cần plugin Flutter/Dart và trỏ tới Flutter SDK của máy đang dùng.
  Không sao chép `.idea`, `node_modules`, `.dart_tool`, `build` hoặc `local.properties` từ máy khác.
- Gửi OTP cần cấu hình `SMTP_*` trong `backend/.env`, với địa chỉ gửi được nhà cung cấp chấp nhận.
- Android thật cùng Wi-Fi: thêm `--dart-define=API_BASE_URL=http://<IP_MAY_TINH>:3000/api`
  vào Additional run args. Nếu dùng USB, chạy `adb reverse tcp:3000 tcp:3000`
  và dùng `--dart-define=API_BASE_URL=http://127.0.0.1:3000/api`.
- Ảnh chi nhánh admin tải lên lưu trong `backend/uploads`; thư mục này không đưa lên Git.
  Khi chuyển máy triển khai, cần sao chép hoặc lưu trữ riêng ảnh tải lên.

Thay đổi giao diện dùng các thư viện đã khai báo trong `pubspec.yaml`
(bao gồm `image_picker`); phần cắt ảnh dùng Flutter SDK, không cần cài thêm
thư viện thanh toán MoMo hoặc VNPAY.

## Yêu cầu

- Flutter SDK tương thích Dart `^3.13.2`.
- Node.js 22 hoặc mới hơn.
- PostgreSQL 17, hoặc Docker Desktop có Docker Compose.
- Android Studio/Android SDK nếu chạy trên Android.

## 1. Khởi động PostgreSQL bằng Docker

Tại thư mục gốc:

```powershell
Copy-Item .env.example .env
```

Đổi `POSTGRES_PASSWORD` trong `.env`, sau đó chạy:

```bash
docker compose up -d postgres
docker compose ps
```

Nếu đã cài PostgreSQL trực tiếp, chỉ cần tạo hai database:

```sql
CREATE DATABASE sanvacau;
CREATE DATABASE sanvacau_test;
```

## 2. Cấu hình và chạy backend

Muốn dùng dữ liệu snapshot đã có sản phẩm và lịch đặt sân, làm theo [database/README.md](database/README.md) thay cho bước tạo schema và seed bên dưới.

```powershell
cd backend
Copy-Item .env.example .env
npm ci
npx prisma generate
npx prisma db push
npm run seed
npm run dev
```

Cập nhật `DATABASE_URL` và `JWT_SECRET` trong `backend/.env` trước khi chạy. Backend mặc định ở:

```text
http://localhost:3000/api
```

Kiểm tra:

```text
GET http://localhost:3000/api/health
```

Seed tạo tài khoản quản trị dùng cho môi trường local:

```text
Email: admin@shopvacau.com
Password: Admin123456
```

Hãy đổi mật khẩu này nếu triển khai ngoài máy local.

### Bổ sung biến thể sản phẩm demo

Catalog và seeder sản phẩm được tích hợp từ nhánh `feature/thinh_branch`.
Trong thư mục `backend`, chạy `npm run seed:products` để bổ sung biến thể
trọng lượng/cỡ cán vợt, màu/size giày và áo, gói quấn cán cùng tồn kho demo.
Lệnh có thể chạy lại, giữ dữ liệu sản phẩm và tồn kho đã có, không đổi tài khoản
hoặc lịch sân. Giá, cấu hình và tồn kho trong catalog chỉ là dữ liệu minh họa.
Schema hiện tại vẫn giữ OTP, ảnh đại diện và khung đặt sân 30 phút.

### Dùng SQL thay Prisma

Có thể chạy lần lượt:

```bash
psql -U postgres -d sanvacau -f SanVaCau_Database_PostgreSQL.sql
psql -U postgres -d sanvacau -f SanVaCau_SeedData_PostgreSQL_Clean.sql
```

Không chạy đồng thời SQL seed và `npm run seed` trên một database mới nếu không cần dữ liệu trùng lặp.

## 3. Chạy Flutter

```bash
cd frontend/san_va_cau_app
flutter pub get
flutter analyze
flutter run
```

### Android Emulator

Mặc định ứng dụng dùng:

```text
http://10.0.2.2:3000/api
```

### Điện thoại thật cùng mạng LAN

```bash
flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://<IP_MAY_TINH>:3000/api
```

Máy tính và điện thoại phải cùng mạng và mạng không bật client isolation.

### Điện thoại thật qua cáp USB

```bash
adb reverse tcp:3000 tcp:3000
flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

## 4. Chạy kiểm thử

### Khung đặt sân 30 phút

Mỗi ô timeline là 30 phút, đầy đủ từ 06:00 đến 22:00. Giá mẫu là 40.000đ/30 phút trước 12:00 và 60.000đ/30 phút từ 12:00. Chọn ba ô liên tiếp để đặt 1 giờ 30 phút; có thể chọn nhiều sân trong một lần xác nhận. Với database thiếu giờ, chạy `npm run schedule:fill` trong `backend` để bổ sung bảng giá mà vẫn giữ giá đã có.

Với database cũ dùng khung 1 giờ, chạy `npm run migrate:half-hour-slots` trong `backend`. Lệnh chia bảng giá theo thời lượng và giữ nguyên lịch đã đặt; API khóa các ô 30 phút trùng lịch cũ. Seed mới tạo trực tiếp các khung 30 phút.

Backend:

```powershell
cd backend
Copy-Item .env.test.example .env.test
npm run typecheck
npm test
```

Flutter:

```bash
cd frontend/san_va_cau_app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Lưu ý bảo mật

- Không đưa `.env`, mật khẩu database thật, JWT secret hoặc token lên Git.
- Seed credential chỉ dành cho phát triển local.
- Không mở cổng PostgreSQL hoặc backend trực tiếp ra Internet.
- Khi triển khai thật, dùng HTTPS và secret riêng cho từng môi trường.
