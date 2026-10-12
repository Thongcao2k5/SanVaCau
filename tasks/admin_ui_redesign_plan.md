# Kế hoạch tiếp tục: Hoàn thiện giao diện quản trị SanVaCau

## 1. Mục đích của tài liệu

Tài liệu này là điểm bàn giao để có thể tiếp tục công việc ở một phiên Codex/Antigravity khác mà không cần suy đoán lại phạm vi, trạng thái Git hoặc định hướng thiết kế.

Phạm vi hiện tại là **thiết kế lại giao diện quản trị sau khi các luồng chức năng đã hoàn thiện**. Không mở rộng sang quản lý nhân sự nội bộ, voucher, thanh toán admin hoặc dịch vụ vợt.

## 2. Trạng thái Git tại thời điểm lập kế hoạch

- Repository: `F:\AndroidProjects\SanVaCau`
- Nhánh làm việc: `main`
- Remote đã push: `origin/main`
- Commit chức năng admin mới nhất: `62ce028 feat: hoàn thiện luồng quản trị hệ thống`
- Commit trước đó: `c1b5bf8 feat: hoàn thiện luồng chi nhánh và giao diện người dùng`
- Đã push thành công commit `62ce028` lên `https://github.com/Thongcao2k5/SanVaCau.git`.
- Hai file sau có thay đổi tồn tại từ trước và **không được revert, ghi đè, stage hoặc commit nếu người dùng chưa yêu cầu**:
  - `tasks/plan.md`
  - `tasks/todo.md`
- File kế hoạch này là file riêng để không xung đột với hai file trên.

## 3. Trạng thái chức năng đã hoàn thành

### 3.1. Điều hướng và phân quyền

- `CUSTOMER` vào giao diện người dùng.
- `ADMIN`, `BRANCH_MANAGER`, `STAFF` vào `AdminShell`.
- Tài khoản buộc đổi mật khẩu được chặn đúng luồng.
- Hết phiên đăng nhập, lỗi tải phiên, đăng xuất và đăng nhập lại đều đã có xử lý.
- Admin shell có 4 tab bottom navigation màu graphite:
  - Tổng quan
  - Vận hành
  - Quản lý
  - Tài khoản
- Admin có thể mở giao diện người dùng như một route con và quay lại giao diện quản trị.

### 3.2. Các module quản trị đã nối thật

- Lịch đặt sân: danh sách, lọc, chi tiết, cập nhật trạng thái, xác nhận thao tác.
- Đơn hàng: danh sách, lọc, chi tiết, cập nhật trạng thái, thông tin giao hàng/nhận tại chi nhánh.
- Tồn kho: xem theo quyền và cập nhật khi backend cho phép.
- Sản phẩm: danh sách, tìm kiếm, lọc, sản phẩm nổi bật, tạo/sửa/ngừng hoạt động, biến thể.
- Chi nhánh:
  - Tạo chi nhánh.
  - Sửa thông tin, địa chỉ, điện thoại, mô tả và giờ hoạt động.
  - Đổi ảnh.
  - Chọn chi nhánh nổi bật và thứ tự trên trang chủ.
  - Ngừng hoạt động có xác nhận.
- Sân và bảng giá:
  - Tạo/sửa/ngừng hoạt động sân.
  - Quản lý khung giờ.
  - Thiết lập giá theo từng khung giờ.
- Nội dung trang chủ:
  - Tin tức.
  - Banner.
  - Thông báo.
  - Sản phẩm nổi bật.
  - Chi nhánh nổi bật.
- Dashboard đã chạy embedded trong AdminShell, không lồng Scaffold/AppBar.
- Đã loại mục quản lý nhân sự khỏi lối vào admin theo yêu cầu.
- Không thêm voucher, thanh toán admin hoặc dịch vụ vợt.

### 3.3. Trạng thái kiểm thử trước redesign

- `flutter analyze`: **No issues found**.
- `flutter test`: **284/284 tests passed**.
- `git diff --check`: sạch.

## 4. Định hướng thiết kế đã chốt

### 4.1. Tính cách giao diện

- Chuyên nghiệp, hiện đại, mềm mại và gọn như một ứng dụng vận hành thực tế.
- Khác biệt rõ với giao diện user nhưng vẫn thuộc cùng thương hiệu SanVaCau.
- Không biến toàn bộ màn hình thành màu đen nặng nề.
- Bottom navigation graphite là dấu hiệu nhận diện khu vực admin.
- Nội dung dùng nền sáng trung tính để giữ khả năng đọc tốt trong ca làm việc dài.
- Màu đỏ SanVaCau chỉ dùng cho CTA chính, trạng thái chọn và điểm nhấn quan trọng.

### 4.2. Token hình ảnh đề xuất

Không hard-code rải rác trong từng trang. Tạo một bộ token admin dùng chung.

| Vai trò | Giá trị đề xuất |
|---|---|
| Graphite nền đậm | `#17191D` |
| Graphite surface | `#202329` |
| Nền nội dung | `#F6F7F9` |
| Surface/card | `#FFFFFF` |
| Text chính | `#17191D` |
| Text phụ | `#667085` |
| Border nhẹ | `#E6E8EC` |
| Primary SanVaCau | dùng `AppColors.primary` hiện có |
| Success | dùng `AppColors.success` |
| Warning | dùng `AppColors.warning` |
| Info | dùng `AppColors.info` |

### 4.3. Quy tắc component

- Spacing theo nhịp 4/8dp; gutter điện thoại 16–20dp.
- Card chính bo 18–20dp; card nhỏ bo 14–16dp.
- Viền mảnh, hạn chế shadow đậm.
- Icon dùng Material Symbols/Icons biến thể `*_rounded` nhất quán.
- Icon chức năng đặt trong container nền tint nhẹ 40–48dp.
- Touch target tối thiểu 48dp.
- CTA chính cao 52–56dp, bo 14–16dp.
- Không dùng emoji làm icon.
- Không dùng glassmorphism/blur mạnh vì giảm độ rõ và tốn hiệu năng trên Android; chỉ giữ cảm giác phân lớp bằng surface và border.
- Animation chỉ là chuyển trạng thái nhẹ 150–250ms; không làm animation trang trí phức tạp.
- Mọi trạng thái loading/error/empty phải giữ cùng ngôn ngữ hình ảnh.
- Không để nội dung bị bottom navigation hoặc bàn phím che.
- Phải kiểm tra màn hình hẹp 320–375dp và text scale 1.5.

## 5. Kiến trúc triển khai

```text
Admin design tokens/theme
        |
        +-- Admin shared components
        |       +-- page header
        |       +-- section header
        |       +-- metric card
        |       +-- module/action card
        |       +-- status badge
        |       +-- empty/error/loading state
        |
        +-- AdminShell + Dashboard
        |
        +-- Operation pages
        |       +-- booking
        |       +-- order
        |       +-- inventory
        |
        +-- Management pages
        |       +-- product
        |       +-- branch/court/pricing
        |       +-- home content
        |
        +-- Responsive/accessibility regression tests
```

Không tạo state manager, router service hoặc dependency mới chỉ để redesign. Giữ nguyên API, model và business logic hiện có.

## 6. Kế hoạch triển khai theo lát cắt

## Task 1: Tạo nền tảng giao diện admin dùng chung

**Mô tả:** Tạo token màu/khoảng cách/radius và các component nhỏ thực sự lặp lại. Không di chuyển business logic.

**Acceptance criteria:**

- [ ] Có một nguồn token admin duy nhất; không rải thêm mã màu graphite mới ở các trang.
- [ ] Có component dùng chung cho header, card module, status badge và state view khi ít nhất hai trang sử dụng.
- [ ] Component hỗ trợ text scale 1.5 và touch target tối thiểu 48dp.

**Verification:**

- [ ] `flutter analyze`
- [ ] Widget test cho component mới.
- [ ] Không thay đổi kết quả test chức năng hiện có.

**Files dự kiến:**

- `frontend/san_va_cau_app/lib/features/admin/theme/admin_theme.dart`
- `frontend/san_va_cau_app/lib/features/admin/widgets/...`
- `frontend/san_va_cau_app/test/features/admin/admin_components_test.dart`

**Phụ thuộc:** Không.

## Task 2: Redesign AdminShell và các trang hub

**Mô tả:** Đồng bộ bottom navigation, header, module cards và trang tài khoản quản trị bằng token mới.

**Acceptance criteria:**

- [ ] Bottom navigation graphite giữ nguyên 4 tab và hành vi `IndexedStack`.
- [ ] Tab Vận hành và Quản lý có phân cấp thị giác rõ, card mềm, icon rounded và phản hồi chạm.
- [ ] Tài khoản admin thể hiện rõ vai trò, nút xem app user và đăng xuất.
- [ ] Không thay đổi phân quyền hoặc navigation hiện có.

**Verification:**

- [ ] `flutter test test/features/admin/admin_shell_test.dart`
- [ ] Test màn hình 320dp và text scale 1.5.

**Files dự kiến:**

- `frontend/san_va_cau_app/lib/features/admin/admin_shell.dart`
- `frontend/san_va_cau_app/test/features/admin/admin_shell_test.dart`

**Phụ thuộc:** Task 1.

## Task 3: Redesign Dashboard

**Mô tả:** Làm Dashboard thành màn hình vận hành dễ quét: header chào theo vai trò, ngày/phạm vi, metric cards, cảnh báo tồn kho và hoạt động gần đây.

**Acceptance criteria:**

- [ ] Metric cards không overflow ở 320dp/text scale 1.5.
- [ ] Trạng thái không chỉ được biểu thị bằng màu; có label/icon rõ ràng.
- [ ] Các card có hành động vẫn mở đúng module và refresh khi quay lại.
- [ ] Loại bỏ các card điều hướng trùng lặp nếu đã có trong tab Quản lý, nhưng không làm mất đường dẫn quan trọng.

**Verification:**

- [ ] `flutter test test/features/admin/admin_dashboard_page_test.dart`
- [ ] Test loading/error/empty/success.
- [ ] Manual check portrait và landscape.

**Files dự kiến:**

- `frontend/san_va_cau_app/lib/features/admin/pages/admin_dashboard_page.dart`
- `frontend/san_va_cau_app/test/features/admin/admin_dashboard_page_test.dart`

**Phụ thuộc:** Task 1, Task 2.

### Checkpoint A: Nền tảng và màn hình chính

- [ ] `flutter analyze` sạch.
- [ ] Test AdminShell + Dashboard qua hết.
- [ ] Người dùng xem ảnh/chạy máy thật và duyệt hướng thiết kế trước khi áp dụng rộng.
- [ ] Tạo commit riêng cho checkpoint nếu người dùng yêu cầu.

## Task 4: Redesign nhóm Vận hành

**Mô tả:** Áp dụng cùng design language cho lịch đặt sân, đơn hàng và tồn kho nhưng giữ nguyên form/filter/API.

**Chia thành ba lát cắt độc lập:**

- [ ] 4A — Lịch đặt sân: filter chips, booking card, detail và action tray.
- [ ] 4B — Đơn hàng: status filters, order card, fulfillment info và action tray.
- [ ] 4C — Tồn kho: branch scope, low-stock warning, quantity editor và state views.

**Acceptance criteria:**

- [ ] Filter cuộn ngang không gây overflow.
- [ ] Hành động nguy hiểm vẫn có confirm dialog.
- [ ] Submit được khóa khi đang xử lý để tránh double-submit.
- [ ] STAFF/BRANCH_MANAGER/ADMIN vẫn thấy đúng quyền.

**Verification:**

- [ ] `flutter test test/features/admin/admin_booking_page_test.dart`
- [ ] `flutter test test/features/admin/admin_order_page_test.dart`
- [ ] `flutter test test/features/admin/admin_inventory_page_test.dart`

**Phụ thuộc:** Checkpoint A.

## Task 5: Redesign quản lý Sản phẩm

**Mô tả:** Đồng bộ danh sách, tìm kiếm, bộ lọc, sản phẩm nổi bật, detail, form sản phẩm và biến thể.

**Acceptance criteria:**

- [ ] Search/filter hiện rõ trạng thái đang áp dụng.
- [ ] Badge nổi bật/hoạt động không chỉ dựa vào màu.
- [ ] Form giữ label, validation gần field và trạng thái lưu rõ ràng.
- [ ] Không thay đổi contract `ProductApi`.

**Verification:**

- [ ] `flutter test test/features/admin/admin_product_page_test.dart`
- [ ] Test form với bàn phím mở và màn hình hẹp.

**Phụ thuộc:** Task 1.

## Task 6: Redesign Chi nhánh, Sân và Bảng giá

**Mô tả:** Làm luồng quản lý cơ sở trực quan hơn, ưu tiên thông tin chi nhánh, sân đang hoạt động, khung giờ và giá.

**Acceptance criteria:**

- [ ] Danh sách chi nhánh hiển thị ảnh, trạng thái nổi bật, địa chỉ và affordance rõ.
- [ ] Form tạo/sửa chi nhánh dễ dùng, không mất dữ liệu khi validation fail.
- [ ] Sân, khung giờ và bảng giá có phân cấp rõ; giá tiền dễ quét.
- [ ] Ngừng hoạt động vẫn yêu cầu xác nhận và không biến thành xóa dữ liệu.

**Verification:**

- [ ] `flutter test test/features/admin/admin_branch_settings_test.dart`
- [ ] `flutter test test/features/admin/admin_court_page_test.dart`
- [ ] Test 320dp và text scale 1.5.

**Phụ thuộc:** Task 1.

### Checkpoint B: Luồng vận hành và dữ liệu

- [ ] Toàn bộ test admin qua hết.
- [ ] Không có overflow trong log widget test.
- [ ] Manual test các confirm dialog và double-submit.
- [ ] Người dùng duyệt trước khi làm nhóm nội dung.

## Task 7: Redesign Nội dung trang chủ

**Mô tả:** Đồng bộ hub nội dung, tin tức, banner và thông báo. Giữ logic sản phẩm/chi nhánh nổi bật ở module tương ứng.

**Acceptance criteria:**

- [ ] Hub giải thích rõ nội dung nào xuất hiện ở đâu trong app user.
- [ ] News draft/publish/archive thể hiện rõ trạng thái.
- [ ] Banner có preview, thứ tự và trạng thái hoạt động rõ ràng.
- [ ] Gửi thông báo có cảnh báo phạm vi người nhận và khóa double-submit.
- [ ] Không tạo module voucher hoặc dịch vụ vợt.

**Verification:**

- [ ] `flutter test test/features/admin/admin_content_page_test.dart`
- [ ] Manual test dữ liệu xuất hiện đúng ở Home user.

**Phụ thuộc:** Task 1, Checkpoint B.

## Task 8: Kiểm tra responsive, accessibility và regression

**Mô tả:** Chốt chất lượng sau khi mọi trang đã dùng cùng design language.

**Acceptance criteria:**

- [ ] Không overflow ở 320dp, 375dp, landscape và text scale 1.5.
- [ ] Touch target tối thiểu 48dp.
- [ ] Icon-only button có tooltip/semantic label.
- [ ] Contrast text/surface đủ đọc; disabled state rõ.
- [ ] Bottom navigation/safe area không che nội dung.
- [ ] Không thay đổi luồng user.

**Verification bắt buộc:**

```powershell
cd F:\AndroidProjects\SanVaCau\frontend\san_va_cau_app
dart format lib test
flutter analyze
flutter test
```

Kỳ vọng tối thiểu: toàn bộ **284 test hiện có** cộng các test mới đều qua.

**Phụ thuộc:** Task 2–7.

### Checkpoint C: Hoàn thành redesign

- [ ] `flutter analyze` không có issue.
- [ ] Toàn bộ test qua.
- [ ] `git diff --check` sạch.
- [ ] Chạy trên thiết bị thật và chụp ảnh các tab chính.
- [ ] Chỉ commit/push khi người dùng yêu cầu.

## 7. Thứ tự khuyến nghị cho phiên tiếp theo

1. Đọc toàn bộ file này.
2. Chạy `git status --short`, `git log -1 --oneline` và `git diff --check`.
3. Không chạm `tasks/plan.md`, `tasks/todo.md`.
4. Bắt đầu Task 1.
5. Hoàn thành Task 2 và Task 3.
6. Chạy Checkpoint A và đưa ảnh/máy thật cho người dùng xem.
7. Chỉ sau khi hướng thiết kế được duyệt mới áp dụng sang Task 4–7.

## 8. Rủi ro và cách giảm thiểu

| Rủi ro | Mức độ | Cách xử lý |
|---|---:|---|
| Redesign làm thay đổi business logic | Cao | Chỉ sửa presentation; giữ API/model/navigation, chạy focused test sau mỗi trang |
| Màu tối làm admin nặng nề | Trung bình | Graphite chỉ ở navigation/header có chủ đích; content dùng nền sáng |
| Tạo quá nhiều component trừu tượng | Trung bình | Chỉ extract khi có ít nhất hai nơi dùng và API component ngắn, rõ |
| Text scale gây overflow | Cao | Thêm widget test 320dp + text scale 1.5 ngay từ Task 1–3 |
| Form dài bị bàn phím che | Cao | ListView/scroll padding, SafeArea và test khi keyboard mở |
| Lẫn thay đổi của người dùng | Cao | Không stage/revert `tasks/plan.md`, `tasks/todo.md`; kiểm tra staged diff trước commit |
| Sai phân quyền sau khi đổi UI | Cao | Giữ điều kiện role hiện có và chạy test ADMIN/BRANCH_MANAGER/STAFF |

## 9. Những phần cố ý không làm

- Quản lý nhân sự nội bộ.
- Voucher.
- Thanh toán admin.
- Dịch vụ vợt.
- Backend/schema/API mới nếu redesign không thực sự cần.
- Router/state manager mới.
- Dependency UI mới chỉ để tạo hiệu ứng.
- Thay đổi giao diện user ngoài regression fix có bằng chứng.

## 10. Prompt tiếp tục nhanh cho phiên mới

```text
Đọc toàn bộ F:\AndroidProjects\SanVaCau\PROJECT_CONTEXT_HANDOFF.md và
F:\AndroidProjects\SanVaCau\tasks\admin_ui_redesign_plan.md. Sau đó kiểm tra
git status, commit hiện tại và diff chưa commit. Tiếp tục đúng task chưa hoàn thành
trong kế hoạch, bắt đầu từ Task 1 hoặc checkpoint gần nhất. Không revert, ghi đè,
stage hay commit tasks/plan.md và tasks/todo.md. Không commit/push nếu tôi chưa yêu cầu.
Giữ nguyên business logic, API và phân quyền; mỗi lát cắt phải chạy focused test,
cuối checkpoint chạy flutter analyze và toàn bộ flutter test.
```

## 11. Nhật ký tiến độ redesign

Cập nhật mục này sau mỗi lát cắt để phiên sau biết chính xác nơi tiếp tục.

- [x] Hoàn thiện và push toàn bộ luồng chức năng admin — commit `62ce028`.
- [x] Chốt hướng thiết kế graphite + nền sáng + điểm nhấn đỏ SanVaCau.
- [x] Task 1 — Nền tảng giao diện admin: thêm token, surface, header, icon box, status badge và state view dùng chung.
- [x] Task 2 — AdminShell và hub: graphite navigation/header ngắn, content nền sáng, module cards và account tab đồng bộ.
- [x] Task 3 — Dashboard: metric responsive, badge có text/icon, bỏ shortcut quản lý/báo cáo trùng lặp.
- [ ] Checkpoint A — Chờ người dùng duyệt hình ảnh.
- [ ] Task 4 — Nhóm Vận hành.
- [ ] Task 5 — Sản phẩm.
- [ ] Task 6 — Chi nhánh/sân/bảng giá.
- [ ] Checkpoint B.
- [ ] Task 7 — Nội dung trang chủ.
- [ ] Task 8 — Responsive/accessibility/regression.
- [ ] Checkpoint C — Chạy máy thật, chụp ảnh, chờ yêu cầu commit/push.

### Kết quả kiểm tra gần nhất — 2026-10-12

- `flutter analyze`: No issues found.
- `flutter test`: 287/287 tests passed.
- Focused tests cho component, AdminShell và Dashboard: 13/13 passed.
- Đã kiểm tra widget ở 320dp và text scale 1.5.
- Thay đổi redesign hiện nằm trong working tree, chưa commit hoặc push.
