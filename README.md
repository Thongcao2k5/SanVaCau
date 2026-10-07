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
