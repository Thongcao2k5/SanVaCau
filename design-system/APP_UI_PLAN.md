# Kế hoạch thiết kế UI App Sân&Cầu

## Phạm vi hiện tại: chỉ `design-system/`

1. Chốt hướng thị giác, token, cách tổ chức màn và quy tắc component trong `APP_UI_RULES.md`.
2. Tạo `app-ui-preview.html` để xem trực tiếp Trang chủ, Sản phẩm, Đặt sân và thư viện component. Mọi dữ liệu trong preview đều là mẫu.
3. Kiểm tra liên kết asset, cú pháp JavaScript, các trạng thái tương tác và diff. Không sửa source Flutter, backend hoặc quy tắc trong `.agent/`.

## Bước sau khi hướng thiết kế được thống nhất

- Chuyển token và component đã chốt sang Flutter `lib/core/`.
- Áp dụng dần vào màn thật, có kiểm thử trên thiết bị và kiểm tra các kích thước màn.
- Kết nối dữ liệu API tương ứng; không dùng dữ liệu mẫu của preview trong App.

## Tiêu chí hoàn thành đợt thiết kế

- Thành viên có một tài liệu quy tắc và một preview độc lập để tham chiếu.
- Preview thể hiện được các trạng thái chính: mặc định, chọn, disabled, trống/lỗi mẫu, màu giá và trạng thái sân.
- Không có thay đổi trong `frontend/` hoặc `backend/`.
