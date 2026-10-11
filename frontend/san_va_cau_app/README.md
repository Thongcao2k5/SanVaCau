# san_va_cau_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

### MoMo Sandbox

Ứng dụng dùng `momo_payment_flutter: ^1.0.2` để mở `payUrl` do backend cung cấp. Backend ký yêu cầu tạo/query và xác minh IPN; Flutter không chứa SecretKey hoặc nút giả lập thành công/thất bại. Chỉ gọi `https://test-payment.momo.vn`, không có chế độ production.

Cấu hình `backend/.env` bằng khóa Sandbox từ tài khoản đối tác MoMo:

```env
MOMO_PARTNER_CODE=
MOMO_ACCESS_KEY=
MOMO_SECRET_KEY=
MOMO_IPN_URL=https://YOUR_PUBLIC_HOST/api/payments/momo/ipn
MOMO_REDIRECT_URL=https://YOUR_PUBLIC_HOST/api/payments/momo/return
```

URL callback cần HTTPS công khai (deploy backend hoặc tunnel cổng 3000); localhost/IP LAN không nhận được IPN từ MoMo. Chưa có khóa thì app báo chưa cấu hình trước khi tạo đơn. Dùng tài khoản/app kiểm thử theo hướng dẫn MoMo, không dùng khóa production.

Sau khi cập nhật schema chạy `npx prisma db push` và `npx prisma generate` trong backend rồi khởi động server. Cài Flutter bằng `flutter pub get`, Stop/Run lại sau thay đổi native. Chọn MoMo Sandbox ở checkout, mở trang thanh toán, quay về ứng dụng và bấm Kiểm tra kết quả. Có thể mở tiếp giao dịch đang chờ từ Lịch sử thanh toán. Redirect không xác nhận thanh toán; trạng thái chỉ được cập nhật bằng IPN có chữ ký hoặc query trực tiếp từ backend.

Tài liệu: https://developers.momo.vn/v3/vi/docs/payment/api/wallet/onetime/

### VNPay Sandbox

Hướng dẫn cho cả nhóm về bật/tắt Cloudflare Tunnel, cập nhật callback khi URL đổi và phần IPN cần làm tiếp: [Thanh toán local trong README gốc](../../README.md#thanh-toán-local-khi-nào-cần-cloudflare-tunnel).

VNPay được bổ sung bên cạnh MoMo và tiền mặt. Đã cài `vnpay_payment_flutter: ^1.0.0`; dùng bảng thông báo của thư viện, mở URL thanh toán bằng `url_launcher`. Backend tạo URL và xác minh HMAC-SHA512, Flutter không chứa Hash Secret.

Đăng ký Sandbox tại https://sandbox.vnpayment.vn/devreg/ để nhận TMN Code và Hash Secret. Điền trong `backend/.env`:

```env
VNPAY_TMN_CODE=
VNPAY_HASH_SECRET=
VNPAY_RETURN_URL=https://YOUR_PUBLIC_HOST/api/payments/vnpay/return
```

Đăng ký IPN URL `https://YOUR_PUBLIC_HOST/api/payments/vnpay/ipn` với VNPay. Backend phải truy cập được qua HTTPS công khai, có thể dùng tunnel khi chạy local. Khởi động lại backend và Stop/Run Flutter sau thay đổi Android. Scheme `sanvacau` trên iOS dùng chung cho callback MoMo và VNPay.

Chọn VNPay ở checkout, mở VNPay Sandbox và dùng dữ liệu ngân hàng thử nghiệm theo hướng dẫn VNPay. Khi quay về app, trang thanh toán kiểm tra trạng thái đã được backend xác nhận; cũng có thể bấm Kiểm tra kết quả hoặc mở lại từ Lịch sử thanh toán. Return URL không tự xác nhận giao dịch. Chỉ IPN hợp lệ, đúng merchant và đúng số tiền mới cập nhật trạng thái; nút kiểm tra truy vấn API querydr và xác minh chữ ký, merchant, mã tham chiếu, số tiền trước khi cập nhật. VNPay có thể giới hạn truy vấn lặp lại trong 5 phút.

URL thanh toán có hạn 15 phút. Giao dịch đang chờ không được tạo lại hoặc đổi sang MoMo để tránh trả tiền hai lần; chỉ thử lại sau khi backend nhận IPN thất bại. Nếu thiếu hoặc chậm IPN, giao dịch vẫn chờ và cần kiểm tra cấu hình callback/đối soát với VNPay. Chưa cấu hình khóa thì app báo lỗi trước khi tạo đơn.

Nếu cơ sở dữ liệu chưa có `checkout_url` và `gateway_trans_id`, áp dụng `database/migrations/20261010_momo_sandbox.sql` (dùng chung cho hai cổng thanh toán). Không cần thay đổi provider vì trường này là chuỗi.

Tài liệu: https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html
