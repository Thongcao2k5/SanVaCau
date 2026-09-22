# Quy tắc thiết kế UI App Sân&Cầu

**Trạng thái:** đề xuất thiết kế để team review. [Mở bản xem trước](./app-ui-preview.html). Tất cả màn, giá và lịch sân trong preview là dữ liệu mẫu; tài liệu này chưa thay đổi App Flutter.

## Hướng thiết kế

Giao diện mang cảm giác thể thao, nhanh và đáng tin cậy. Màu đỏ Sân&Cầu tạo điểm nhấn cho hành động chính, giá và lựa chọn; nền sáng ấm và thẻ trắng giữ thông tin dễ đọc. Mỗi màn ưu tiên việc người dùng cần quyết định: chọn sân, xem giá, chọn sản phẩm hoặc xem trạng thái đơn.

Hướng này kế thừa [showcase hiện có](./showcase.html) và [quy chuẩn UI/UX](../.agent/rules/ui-ux-design-system.md). Bản preview mới tập trung vào trải nghiệm App; showcase cũ vẫn là thư viện tham khảo rộng hơn.

## Token bắt buộc

| Vai trò | Giá trị | Cách dùng |
| --- | --- | --- |
| Primary | `#DC2626` | CTA chính, giá, trạng thái đang chọn |
| Primary dark | `#991B1B` | Nhấn/hover trên CTA chính |
| Primary soft | `#FCE7E7` | Nền tag, vùng nhấn nhẹ |
| Background | `#FFFBFB` | Nền toàn màn |
| Surface | `#FFFFFF` | Thẻ, thanh điều hướng, input |
| Border | `#FECACA` | Thẻ và vùng tương tác |
| Text primary | `#1F2937` | Tiêu đề, nội dung chính |
| Text secondary | `#64748B` | Mô tả, metadata |
| Available | `#16A34A` / `#F0FDF4` | Slot còn trống, trạng thái thành công |
| Booked | `#94A3B8` / `#F1F5F9` | Slot đã đặt, disabled |

Font chính: **Plus Jakarta Sans**, hỗ trợ tiếng Việt; dùng bản font trong `assets/fonts/` cho preview. Cỡ chữ: hero `24/800`, tiêu đề màn `20/700`, tiêu đề mục `16/700`, nội dung `14/400–600`, nhãn `12/600`, chú thích `11/500`. Giãn dòng nội dung tối thiểu `1.4`. Giữ khả năng phóng to chữ khi triển khai trên App.

Khoảng cách theo thang `4, 8, 12, 16, 20, 24, 32`; lề màn mặc định `16`. Bo góc: thẻ nhỏ `8`, input/nút `10`, hero `18`, pill `999`. Mục tiêu chạm tối thiểu `44 × 44`.

## Cấu trúc màn

| Màn | Thứ tự nội dung | Quy tắc quyết định |
| --- | --- | --- |
| Trang chủ | Chọn chi nhánh → hero → khám phá nhanh → sản phẩm nổi bật → nội dung mới | Hero có CTA đặt sân nổi bật, CTA sản phẩm phụ |
| Sản phẩm | Tiêu đề → tìm kiếm → lọc → danh sách | Thẻ hiển thị ảnh, tên, thương hiệu, biến thể/tồn kho khi có, giá VNĐ |
| Đặt sân | Chi nhánh → ngày → chú giải → ma trận sân/giờ → tổng tiền | Slot trống xanh, chọn đỏ, đã đặt xám; tổng tiền luôn thấy khi đã chọn |
| Giỏ hàng | Món hàng → chi nhánh nhận → tổng → CTA | Kiểm tra tồn kho và giá trước bước xác nhận |
| Tài khoản | Hồ sơ → đặt sân/đơn hàng → cài đặt | Tình trạng lịch/đơn dùng cả nhãn chữ và màu |

Giỏ hàng và Tài khoản mới có quy tắc, chưa có màn preview chi tiết. Không đưa dữ liệu giả từ preview vào App.

## Hợp đồng component cho bước Flutter sau này

| Component | Biến thể / trạng thái | Quy tắc dùng |
| --- | --- | --- |
| Button | Primary, outlined, text; normal, disabled, loading | Một CTA chính trên mỗi cụm; nhãn là động từ rõ nghĩa |
| Surface card | Tĩnh hoặc bấm được | Nền trắng, viền đỏ nhạt, padding `12`; cả thẻ là vùng chạm nếu có điều hướng |
| Section header | Tiêu đề và action tùy chọn | Action ở cuối hàng, tiêu đề có thể xuống dòng ở màn hẹp |
| Status tag | Brand, available, booked | Luôn ghi chữ, không chỉ dựa vào màu |
| Price | Giá sản phẩm hoặc giá/giờ | Dấu chấm nhóm nghìn và hậu tố `đ`, `đ/giờ` |
| Feedback state | Loading, empty, error | Mô tả ngắn, có thao tác thử lại khi phù hợp |
| Slot cell | Available, selected, booked | Hiển thị trạng thái, giá, vùng chạm đủ lớn; booked không tương tác |

## Quy tắc cho thành viên

1. Dùng token ở trên trước khi thêm màu, cỡ chữ hoặc khoảng cách mới. Nếu thiếu token, cập nhật tài liệu này và preview cùng lúc.
2. Dùng đúng component theo vai trò. Không sao chép CSS từ preview trực tiếp vào Flutter; chuyển quy tắc thành component native sau khi duyệt hướng thiết kế.
3. Một trạng thái phải đọc được khi không nhìn màu. Ảnh lỗi, tải dữ liệu, rỗng và lỗi API đều cần giao diện riêng.
4. Giá lấy từ `product_variant.price` hoặc `court_price`; không gán giá vào `product` hay dữ liệu mẫu của preview.
5. Kiểm tra ở chiều rộng `320`, `390` và `430` px, chữ được phóng to, vùng chạm và tương phản trước khi bàn giao màn App.

## Những gì preview chứng minh

Preview cho thấy hướng thị giác và hành vi mẫu của tab, lọc sản phẩm, chọn ngày và chọn slot. Nó không xác minh API, điều hướng App, kiểm soát đặt trùng sân hoặc thanh toán.
