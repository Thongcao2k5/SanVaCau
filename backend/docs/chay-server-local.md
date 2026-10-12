# Bật server thủ công trên máy hiện tại

Dự án có một REST API Express phục vụ tất cả chức năng, gồm MoMo và VNPay. API chạy ở cổng **3000**, dùng PostgreSQL riêng của dự án ở **127.0.0.1:5433**. `data-crawl` là công cụ thu thập dữ liệu, không phải server API. PostgreSQL Windows ở cổng 5432 là dịch vụ riêng; cấu hình hiện tại của backend dùng cổng 5433.

## 1. Bật PostgreSQL của dự án

Mở PowerShell, chạy:

```powershell
Set-Location 'D:\Lap-trinh-tren-thiet-bi-di-dong'
& 'D:\PostgreSQL\bin\pg_ctl.exe' status -D '.\artifacts\postgres-local'
```

Nếu báo `no server running`, bật database đã có dữ liệu:

```powershell
& 'D:\PostgreSQL\bin\pg_ctl.exe' start -D 'D:\Lap-trinh-tren-thiet-bi-di-dong\artifacts\postgres-local' -l 'D:\Lap-trinh-tren-thiet-bi-di-dong\artifacts\postgres-local.log' -o '-p 5433 -h 127.0.0.1' -w
```

Khi báo `server started`, PostgreSQL tiếp tục chạy sau khi đóng PowerShell. Các lệnh này dùng dữ liệu hiện có; không cần chạy seed hoặc nhập lại SQL mỗi lần bật server.

## 2. Bật API

Trong một PowerShell khác:

```powershell
Set-Location 'D:\Lap-trinh-tren-thiet-bi-di-dong\backend'
npm run dev
```

Giữ cửa sổ này mở. Khi thấy `SanVaCau API listening on port 3000` là API đã bật. Backend đọc cấu hình `backend/.env`; `DATABASE_URL` hiện trỏ đến PostgreSQL cổng 5433.

Nếu cổng 3000 đang được dùng, kiểm tra API trước; không chạy thêm một bản:

```powershell
Invoke-RestMethod 'http://localhost:3000/api/health'
Invoke-RestMethod 'http://localhost:3000/api/health/db'
```

API được bật nền trong phiên hỗ trợ này. Có thể tìm tiến trình bằng:

```powershell
Get-NetTCPConnection -LocalPort 3000 -State Listen | Select-Object OwningProcess
```

Nếu cần chuyển sang chạy trong terminal, kiểm tra đúng tiến trình của dự án trước khi dừng:

```powershell
$apiListener = Get-NetTCPConnection -LocalPort 3000 -State Listen | Select-Object -First 1
Get-CimInstance Win32_Process -Filter "ProcessId=$($apiListener.OwningProcess)" | Select-Object ProcessId,CommandLine
# Chỉ khi CommandLine là server.ts của dự án:
Stop-Process -Id $apiListener.OwningProcess
npm run dev
```

Log của bản API chạy nền: `backend/.dev-server.stdout.log` và `backend/.dev-server.stderr.log`.

## 3. Xem dữ liệu

Mở trình duyệt hoặc gọi từ Postman:

| Dữ liệu | URL |
| --- | --- |
| Trạng thái API | http://localhost:3000/api/health |
| Kết nối database | http://localhost:3000/api/health/db |
| Sản phẩm | http://localhost:3000/api/products |
| Chi nhánh | http://localhost:3000/api/branches |
| Sân | http://localhost:3000/api/courts |

API riêng tư như lịch sử thanh toán yêu cầu đăng nhập và header `Authorization: Bearer <TOKEN>`.

Chạy ứng dụng để xem dữ liệu qua giao diện:

```powershell
Set-Location 'D:\Lap-trinh-tren-thiet-bi-di-dong\frontend\san_va_cau_app'
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api
```

Android Emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

Điện thoại thật qua USB:

```powershell
adb reverse tcp:3000 tcp:3000
flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

Chạy `flutter devices` để lấy `DEVICE_ID`. Điện thoại cùng Wi-Fi có thể dùng `http://192.168.100.167:3000/api` (IP của máy lúc viết hướng dẫn); IP có thể đổi, kiểm tra bằng `ipconfig`. Windows Firewall cần cho phép kết nối đến cổng 3000 nếu dùng LAN.

## 4. Tắt server

API chạy trong terminal: nhấn **Ctrl+C**. API chạy nền: kiểm tra rồi dừng đúng PID theo bước 2.

Tắt PostgreSQL riêng của dự án:

```powershell
& 'D:\PostgreSQL\bin\pg_ctl.exe' stop -D 'D:\Lap-trinh-tren-thiet-bi-di-dong\artifacts\postgres-local' -m fast -w
```

## 5. Kiểm thử và VNPay

Database kiểm thử `sanvacau_test` cũng nằm ở cổng 5433; `.env.test` tách biệt với database ứng dụng. Trong `backend`:

```powershell
npm run typecheck
npm test -- tests/integration/vnpay.test.ts tests/integration/momo.test.ts tests/integration/payment.test.ts
node --import tsx --test tests/unit/vnpay.test.ts
```

VNPay đã tích hợp Sandbox, MoMo được giữ lại. Cần điền `VNPAY_TMN_CODE`, `VNPAY_HASH_SECRET`, `VNPAY_RETURN_URL` vào `backend/.env`, đăng ký IPN URL HTTPS công khai với VNPay rồi khởi động lại API. Chi tiết trong `frontend/san_va_cau_app/README.md`. API localhost đủ để xem dữ liệu; callback thanh toán cần backend có URL công khai.
