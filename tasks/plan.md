# Implementation Plan: Hoàn thiện và nghiệm thu giao diện người dùng

## Overview

Hoàn thiện phần ứng dụng dành cho khách hàng dựa trên các chức năng đã có, loại trừ tích hợp thanh toán thật. Công việc tập trung vào chốt các thay đổi đang dở, bổ sung bằng chứng kiểm thử cho các luồng quan trọng và sửa các lỗi được tái hiện bằng test hoặc kiểm tra runtime. Không thay đổi API contract, schema hay khu vực quản trị nếu không cần thiết cho luồng khách hàng.

## Architecture Decisions

- Giữ nguyên kiến trúc feature hiện tại và các API contract đang dùng.
- Mỗi luồng được nghiệm thu theo lát dọc: UI -> API client/fake -> trạng thái thành công/lỗi/rỗng -> widget test.
- Mọi lỗi hành vi phải có test tái hiện trước khi sửa.
- Không triển khai thanh toán thật; chỉ đảm bảo phần checkout trước điểm chuyển sang thanh toán hoạt động đúng.
- Không commit, revert hoặc ghi đè các thay đổi có sẵn nếu chưa được người dùng yêu cầu.

## Task List

### Phase 1: Chốt thay đổi đang dở

- [x] Task 1: Xác lập baseline bằng analyze và các test liên quan tới cart, main shell, product detail.
- [x] Task 2: Chốt hành vi giỏ hàng: chọn sản phẩm, tăng/giảm, vuốt xóa, hoàn tác, xóa toàn bộ và chuyển checkout.
- [x] Task 3: Chốt điều hướng tab giỏ hàng và lựa chọn biến thể ở chi tiết sản phẩm.

### Checkpoint: Current changes

- [x] Focused tests đều pass.
- [x] Không có Flutter analyzer issue mới.
- [x] Năm file thay đổi ban đầu được bảo toàn và chỉ chỉnh khi có lỗi đã xác định.

### Phase 2: Luồng mua hàng không gồm thanh toán

- [x] Task 4: Bổ sung kiểm thử checkout cho tải dữ liệu, chọn chi nhánh/địa chỉ, pickup/delivery và voucher.
- [x] Task 5: Bổ sung kiểm thử lịch sử và chi tiết đơn hàng, gồm loading/error/empty/status.

### Checkpoint: Ordering

- [x] Luồng cart -> checkout -> tạo đơn có bằng chứng kiểm thử.
- [x] Lịch sử và chi tiết đơn hàng hiển thị ổn định.

### Phase 3: Booking

- [x] Task 6: Kiểm thử chọn chi nhánh, sân, ngày, một hoặc nhiều slot liên tiếp.
- [x] Task 7: Kiểm thử lịch sử, chi tiết, hủy booking và luồng đánh giá sân.

### Phase 4: Tài khoản

- [x] Task 8: Kiểm thử đăng ký OTP, quên/đặt lại mật khẩu và đổi email.
- [x] Task 9: Kiểm thử hồ sơ, avatar, địa chỉ, hết phiên đăng nhập và đăng xuất.

### Phase 5: Tiện ích khách hàng

- [x] Task 10: Kiểm thử thông báo, yêu thích và tìm kiếm tổng hợp.
- [x] Task 11: Kiểm thử chi nhánh, tin tức, dịch vụ vợt, support, FAQ, liên hệ và chính sách.

### Checkpoint: Complete

- [x] `flutter analyze` sạch.
- [x] Toàn bộ `flutter test` pass, không skip test.
- [x] Runtime smoke test trên emulator (trang chủ và dịch vụ vợt nối backend thật) không có lỗi Flutter/framework nghiêm trọng.
- [x] Git diff chỉ chứa thay đổi trong phạm vi phần user; không có commit mới.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Working tree đang có thay đổi lớn | Cao | Đọc diff trước mỗi lát, không revert và chỉ sửa đúng file liên quan |
| Widget test phụ thuộc network/secure storage | Trung bình | Dùng fake API theo pattern test hiện có |
| OTP phụ thuộc SMTP | Trung bình | Widget test trạng thái UI; kiểm tra tích hợp thật riêng khi backend/SMTP sẵn sàng |
| Thanh toán mock chưa hoàn thiện | Thấp trong phạm vi này | Loại trừ tích hợp thanh toán thật khỏi tiêu chí hoàn thành |

## Open Questions

- Không có câu hỏi chặn; tiếp tục theo phạm vi đã được người dùng xác nhận.

## Extension: Redesign các trang con trong Tài khoản

### Design contract

- Giữ nguyên nhận diện hiện có: đỏ `AppColors.primary`, nền trắng hồng, Plus Jakarta Sans và icon Material nét thống nhất; không áp dụng bảng màu xanh do công cụ gợi ý vì không phù hợp thương hiệu hiện tại.
- Phong cách: clean sport-commerce, content-first, tương phản cao, card có bán kính phân cấp 10/16/20, khoảng cách theo nhịp 4/8dp và chuyển động tối giản.
- Mỗi trang phải có hierarchy rõ (header, mô tả ngắn, nội dung, CTA), touch target tối thiểu 48dp và đủ loading/error/empty/success state.
- Không sửa `PaymentHistoryPage` và luồng thanh toán; không thay đổi API contract hoặc business logic.

### Phase 6: Shared account UI foundation

- [x] Task 12: Tạo các widget trình bày dùng chung cho header, section surface và empty/error state.
  - Acceptance: dùng semantic color tokens; hỗ trợ nội dung dài và text scaling; không che safe area.
  - Verification: widget tests mới và `flutter analyze`.
  - Files: `lib/core/widgets/account_*`, `test/core/widgets/account_*`.

### Phase 7: High-priority utility pages

- [x] Task 13: Redesign Yêu thích, sửa cách resolve ảnh và bổ sung card sản phẩm có hierarchy rõ.
  - Acceptance: ảnh backend hiển thị đúng; card có tên, trạng thái và affordance mở chi tiết; đủ loading/error/empty.
  - Verification: focused widget tests và emulator.
- [x] Task 14: Redesign Help Center, liên hệ và trang chính sách.
  - Acceptance: FAQ/chính sách/liên hệ đồng bộ header và section; form có mô tả, validation và submit feedback rõ.
  - Verification: focused widget tests và emulator.

### Checkpoint: Utility pages

- [x] `flutter analyze` sạch và focused tests pass.
- [x] Kiểm tra trực tiếp Yêu thích và Help Center trên emulator.

### Phase 8: Forms and support

- [x] Task 15: Redesign danh sách, tạo và chi tiết support ticket.
  - Acceptance: trạng thái ticket dễ quét; form được phân nhóm; composer và CTA không bị bàn phím che.
  - Verification: support widget tests và emulator.
- [x] Task 16: Redesign form địa chỉ và sửa đánh giá.
  - Acceptance: input được nhóm theo ngữ nghĩa; CTA rõ; validation inline; giữ nguyên hành vi API.
  - Verification: address/review widget tests và emulator.

### Final checkpoint: Account redesign

- [x] `flutter analyze` sạch.
- [x] Toàn bộ `flutter test` pass.
- [x] Kiểm tra màn hình nhỏ, text scaling và runtime emulator.
- [x] Review diff; không commit, revert hoặc đụng vào phần thanh toán.

## Extension: Cohesion review với ChatGPT

- [x] Kết nối lại `Codex with ChatGPT · SanVaCau` và xác minh đúng workspace.
- [x] ChatGPT review độc lập giao diện Tài khoản, giữ nguyên hệ đỏ–trắng và phong cách sport-commerce.
- [x] Đồng bộ lịch sử đặt sân, lịch sử đơn hàng, danh sách địa chỉ và thông báo với shared account UI.
- [x] Giữ nguyên màu trạng thái nghiệp vụ, selection mode của địa chỉ và toàn bộ phạm vi thanh toán.
- [x] `flutter analyze` sạch, 252 test pass và smoke test emulator đạt.
- [x] ChatGPT review sau triển khai: PASS, không có lỗi chặn.
