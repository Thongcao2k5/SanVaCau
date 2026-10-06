# Ke hoach hoan thien lien ket Flutter - Backend

## Tong quan

Trang thai da xac minh ngay 2026-10-06:

- Backend typecheck thanh cong va `62/62` test hien co pass.
- Flutter `analyze` sach, `10/10` test pass va build APK debug thanh cong.
- Ho tro khach hang, dich vu vot theo chi nhanh va dieu huong tu thong bao da duoc commit.
- So thong bao chua doc da hoan thanh o commit `8b8dc0d`; day khong con la task dang do.
- Khoang trong da xac nhan tiep theo la quan ly danh gia ca nhan. Backend co `GET /api/reviews/me` va `PATCH /api/reviews/:id`, nhung Flutter chua goi hai endpoint nay va chua co man hinh "Danh gia cua toi".

## Quyet dinh kien truc

- Lam theo tung vertical slice va commit rieng sau khi test xanh.
- Khong dua endpoint admin nhu dashboard, inventory, report va audit log vao app khach hang.
- Giu `ReviewApi` la noi duy nhat goi review endpoints; UI khong goi `ApiClient` truc tiep.
- Tai lai danh sach sau khi sua danh gia thanh cong, khong cap nhat UI bang du lieu doan.
- Loi cua tinh nang phu khong duoc lam hong trang Tai khoan hoac cac luong khach hang khac.
- Mo rong `GET /reviews/me` theo huong backward-compatible: giu `targetType`/`targetId` va them `target: { type, id, name }` de UI hien ten san pham/san ma khong tao N+1 request.

## Do thi phu thuoc

```text
Review contract + backend tests
        |
        v
Flutter ReviewApi + model tests
        |
        v
Danh sach danh gia ca nhan
        |
        v
Sua danh gia + reload danh sach
        |
        v
Endpoint audit khach hang
        |
        v
Full verification + device acceptance + screenshots
```

## Danh sach task

### Phase 1: Quan ly danh gia ca nhan

#### Task 1: Khoa contract review ca nhan bang integration test

**Mo ta:** Them test backend cho `GET /reviews/me` va `PATCH /reviews/:id` truoc khi noi Flutter.

**Acceptance criteria:**

- User chi xem va sua duoc danh gia cua chinh minh.
- Filter/pagination va validation rating `1..5`, comment toi da 1000 ky tu duoc test.
- User khac sua review nhan `403`; review khong ton tai nhan `404`.

**Verification:**

- `npm run typecheck`
- `npm test -- review`
- `npm test`

**Dependencies:** Khong.

**Files likely touched:**

- `backend/tests/integration/review.test.ts`
- `backend/src/routes/review.routes.ts` chi khi test phat hien loi contract.

**Estimated scope:** Medium, 1-2 files.

#### Task 2: Them Flutter API cho danh gia cua toi va cap nhat danh gia

**Mo ta:** Mo rong `ReviewApi` bang typed methods cho `GET /reviews/me` va `PATCH /reviews/:id`.

**Acceptance criteria:**

- Request gui JWT va parse dung danh sach/pagination.
- Update chi gui rating/comment da chuan hoa va parse review tra ve.
- Thieu token, response hop le va response loi deu co unit test.

**Verification:**

- `flutter test test/features/reviews/review_api_test.dart`
- `flutter analyze`

**Dependencies:** Task 1.

**Files likely touched:**

- `frontend/san_va_cau_app/lib/features/reviews/data/review_api.dart`
- `frontend/san_va_cau_app/lib/features/reviews/models/review.dart`
- `frontend/san_va_cau_app/test/features/reviews/review_api_test.dart`

**Estimated scope:** Medium, 2-3 files.

#### Task 3: Xay man hinh Danh gia cua toi

**Mo ta:** Them entry tu trang Tai khoan va man hinh liet ke review cua user.

**Acceptance criteria:**

- Co loading, empty, error/retry va pull-to-refresh states.
- Moi item hien rating, comment, status, ngay cap nhat va target da duoc chot o decision gate.
- Man hinh truy cap duoc tu muc "Danh gia cua toi" tren AccountPage.

**Verification:**

- Widget test cho loading/data/empty/error.
- `flutter analyze`
- Kiem tra tren emulator voi user co va khong co review.

**Dependencies:** Task 2 va quyet dinh cach hien thi target.

**Files likely touched:**

- `frontend/san_va_cau_app/lib/features/reviews/pages/my_reviews_page.dart`
- `frontend/san_va_cau_app/lib/features/auth/pages/account_page.dart`
- `frontend/san_va_cau_app/test/features/reviews/my_reviews_page_test.dart`

**Estimated scope:** Medium, 3 files.

#### Task 4: Sua danh gia da gui

**Mo ta:** Cho phep mo review cua minh, sua so sao/comment, gui PATCH va tai lai danh sach.

**Acceptance criteria:**

- Form nap gia tri hien tai va validate rating/comment giong backend.
- Save co loading guard; thanh cong cap nhat du lieu that, that bai hien message va giu du lieu nhap.
- Khong cho sua review cua user khac; backend van la lop bao ve cuoi.

**Verification:**

- Widget test cho edit success, validation va API error.
- `flutter analyze`
- `flutter test`
- Kiem tra truc tiep: sua review, thoat/vao lai van thay du lieu moi.

**Dependencies:** Task 3.

**Files likely touched:**

- `frontend/san_va_cau_app/lib/features/reviews/pages/my_reviews_page.dart`
- `frontend/san_va_cau_app/lib/features/reviews/widgets/review_form.dart`
- `frontend/san_va_cau_app/test/features/reviews/my_reviews_page_test.dart`

**Estimated scope:** Medium, 2-3 files.

### Checkpoint: Review management

- Backend full test pass.
- Flutter analyze va full test pass.
- Create review cu khong bi regression.
- List va edit review chay that tren emulator/dien thoai.
- Moi task co commit rieng, khong gom file untracked ngoai pham vi.

### Phase 2: Audit endpoint khach hang

#### Task 5: Tao ma tran endpoint khach hang va Flutter coverage

**Mo ta:** Liet ke endpoint public/customer, role, Flutter API caller, UI entry point, automated test va runtime evidence.

**Acceptance criteria:**

- Moi endpoint duoc danh dau `covered`, `partial`, `missing` hoac `admin-only`.
- Khong danh dau covered neu chi co class API ma khong co UI entry point.
- Moi gap co muc do uu tien va cach verify cu the.

**Verification:**

- Doi chieu `backend/src/routes/index.ts`, tung route file va `frontend/lib/features`.
- Review ma tran voi nguoi dung truoc khi sua gap.

**Dependencies:** Checkpoint review management.

**Files likely touched:**

- `tasks/customer-endpoint-audit.md`

**Estimated scope:** Small, 1 file.

#### Task 6+: Sua tung gap da duoc phe duyet

**Mo ta:** Moi gap trong audit thanh mot vertical slice rieng; khong gom nhieu domain vao mot commit.

**Acceptance criteria:**

- Moi slice co API/model/UI/test neu can.
- Khong dua admin-only endpoint vao app customer.
- Test focused pass truoc khi chuyen gap tiep theo.

**Verification:** Theo endpoint cu the, sau moi 2-3 slice chay full backend va Flutter suites.

**Dependencies:** Task 5 va nguoi dung duyet danh sach gap.

**Estimated scope:** Small/Medium cho moi gap.

### Checkpoint: Customer endpoint coverage

- Khong con gap `missing` muc do cao trong ma tran.
- Tat ca gap `partial` co quyet dinh ro rang: hoan thien hoac chap nhan.
- Full backend va Flutter test pass.

### Phase 3: Nghiem thu cuoi

#### Task 7: Full automated verification

**Acceptance criteria:**

- `npm run typecheck`, `npm test` pass.
- `flutter analyze`, `flutter test`, `flutter build apk --debug` pass.
- `git diff --check` sach; khong co secret/build output duoc stage.

**Dependencies:** Checkpoint endpoint coverage.

**Estimated scope:** Small.

#### Task 8: Device acceptance va anh nghiem thu

**Acceptance criteria:**

- Kiem tra tren dien thoai/emulator: auth, san pham, cart/order/payment, booking, reviews, support, notifications, profile.
- Kiem tra ca loading, empty, API error va session het han o cac man hinh quan trong.
- Chup anh cac luong chinh sau khi du lieu da duoc xac nhan khong nhay cam.

**Dependencies:** Task 7.

**Estimated scope:** Medium.

#### Task 9: Commit hoan thien lien ket Flutter - Backend

**Acceptance criteria:**

- Chi stage file thuoc cac task da nghiem thu.
- Commit message ro pham vi va verification duoc ghi trong handoff.
- Working tree khong con tracked change chua giai thich.

**Dependencies:** Task 8 va nguoi dung nghiem thu anh.

**Estimated scope:** Small.

## Rui ro va cach giam thieu

| Rui ro | Muc do | Giam thieu |
|---|---|---|
| `GET /reviews/me` phai resolve target polymorphic | Trung binh | Batch query product/court theo trang, khong query tung review. |
| Backend co route nhung khong co test integration | Cao | Task 1 va audit phai them evidence truoc khi goi la covered. |
| UI co API class nhung khong co entry point | Trung binh | Ma tran Task 5 tach API caller va UI entry point. |
| Test pass nhung device flow loi do network/session | Cao | Device acceptance bat buoc sau automated gates. |
| File untracked lan vao commit | Trung binh | Stage theo path cu the va review staged diff truoc moi commit. |

## Cau hoi mo

- Anh nghiem thu se luu trong repo hay chi xuat ra thu muc ngoai repo de ban xem?
