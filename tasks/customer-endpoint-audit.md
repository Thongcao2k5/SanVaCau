# Customer endpoint audit

Ngay doi chieu: 2026-10-06.

Pham vi: endpoint public, authenticated va `CUSTOMER` trong `backend/src/routes`, doi chieu voi API caller, entry point UI va automated test cua Flutter. Endpoint van hanh noi bo duoc liet ke rieng, khong duoc xem la gap cua app khach hang.

## Quy uoc

- `covered`: co Flutter API caller va co entry point/workflow UI thuc te.
- `partial`: chi mot phan capability duoc dung, hoac workflow co nhung thieu automated evidence.
- `missing`: backend co capability phu hop cho khach hang nhung Flutter chua co caller/UI.
- `redundant`: endpoint khong duoc goi truc tiep vi workflow dang dung endpoint tong hop tuong duong.
- Test evidence: `B` = backend integration test, `F` = Flutter unit/widget test, `manual` = moi co code path de kiem tra tren thiet bi.

## Ma tran endpoint

| Domain | Backend endpoint public/customer | Flutter caller | UI entry point | Tests | Status | Ghi chu |
|---|---|---|---|---|---|---|
| App lifecycle | `GET /app-status` | `AppStatusApi` | `AppStatusGuard` | manual | covered | Maintenance va version gate duoc chay khi app khoi dong. |
| Auth | `POST /auth/register`, `POST /auth/login` | `AuthApi` | Account auth form | B: auth core | covered | Dang ky/dang nhap cung mot entry point. |
| Profile | `GET/PATCH /auth/profile`, `POST /auth/change-password` | `AuthApi` | Account, ProfileEdit, ChangePassword | manual | covered | Endpoint `/auth/me` va `/profile` la contract trung, khong can caller thu hai. |
| Home | `GET /home` | `HomeApi` | HomePage | manual | covered | Du lieu tong hop da mang banners/news/products/courts can cho trang chu. |
| Product catalog | `GET /products`, `GET /products/:id`, `GET /product-variants?productId=` | `ProductApi` | ProductList, ProductDetail | B: validation only | covered | List/detail/variant mua hang deu co. |
| Product filters | `GET /categories`, `GET /brands` | `ProductApi` | ProductList filter sheet | B, F | covered | Ho tro loc ket hop danh muc/thuong hieu, dat lai bo loc va empty state. |
| Product detail helpers | `GET /categories/:id`, `GET /brands/:id`, `GET /product-variants/:id` | Khong co | Khong co | Khong | redundant | Product va variant list da tra du lieu can cho UI hien tai. |
| Search | `GET /search` | `SearchApi` | SearchPage | manual | covered | Tim product/court/news theo type. |
| Branches | `GET /branches` | `BranchApi` | BranchList, Booking, Checkout, RacketService | manual | covered | List tra du thong tin dang hien thi. |
| Branch detail | `GET /branches/:id` | Khong co | Khong co trang detail | Khong | redundant | Chua co noi dung detail vuot qua branch card. |
| Branch availability | `GET /branches/:id/availability` | Khong co | Booking dung court + availability rieng | B: booking workflow | redundant | Workflow hien tai dung `GET /courts?branchId=` va `GET /bookings/availability`. |
| Racket services | `GET /branches/:id/services` | `RacketServiceApi` | BranchList, RacketServicePage | F: model | covered | `GET /racket-services` va `/:id` la catalog goc, endpoint branch da tong hop gia/trang thai thuc te. |
| Courts | `GET /courts`, `GET /courts/:id/prices` | `BookingApi` | BookingPage, CourtDetailPage | B: booking fixtures | covered | Court detail nhan object tu list va tai bang gia. |
| Court helpers | `GET /courts/:id`, `GET /courts/time-slots` | Khong co | Khong co caller rieng | Khong | redundant | Court list va prices/availability da cung cap contract can dung. |
| Booking | `GET /bookings/availability`, `POST /bookings`, `GET /bookings/me`, `PATCH /bookings/:id/cancel` | `BookingApi` | Booking, history, detail | B | covered | Co tao, xem lich su va huy. |
| Cart | `GET /cart`, `POST /cart/items`, `PATCH/DELETE /cart/items/:id` | `CartApi` | ProductDetail, CartPage | B | covered | Them, sua so luong, xoa tung dong. |
| Clear cart | `DELETE /cart` | `CartApi` | CartPage | B, F | covered | Co xac nhan truoc khi xoa, xu ly loading/error va cap nhat gio rong ngay sau khi thanh cong. |
| Orders | `POST /orders`, `GET /orders/me`, `GET /orders/me/:id` | `OrderApi` | Checkout, history, detail | B | covered | Khong co endpoint customer cancel order trong backend. |
| Fulfillment | `POST/GET /fulfillments/orders/:orderId` | `FulfillmentApi` | Checkout, OrderDetail | manual | covered | Tao pickup/delivery va xem theo order. |
| Fulfillment list | `GET /fulfillments/me` | Khong co | Order history la entry chinh | Khong | redundant | Du lieu fulfillment duoc tai theo tung order khi can. |
| Voucher | `POST /vouchers/validate`, `POST /vouchers/apply` | `VoucherApi` | CheckoutPage | B | covered | Validate truoc, apply sau khi co order id. |
| Payment | `POST /payments/mock`, `PATCH /payments/:id/mock-success`, `PATCH /payments/:id/mock-fail`, `GET /payments/me` | `PaymentApi` | Checkout, MockPayment, PaymentHistory | B | covered | Provider hien tai la mock/cash theo backend. |
| Reviews | `GET /reviews/products/:id`, `GET /reviews/courts/:id`, `POST /reviews`, `GET /reviews/me`, `PATCH /reviews/:id` | `ReviewApi` | Product/Court detail, MyReviews, EditReview | B: personal, F: personal/API | covered | List/edit ca nhan hoan thanh trong cac commit `2f04dd4` den `e1bb684`; public/create con manual. |
| Favorites | `GET/POST/DELETE /favorites`, `GET /favorites/check` | `FavoriteApi` | ProductDetail, FavoritesPage | manual | covered | Product detail toggle va danh sach yeu thich co entry point. |
| Notifications | `GET /notifications`, `GET /notifications/unread-count`, `PATCH /notifications/read-all`, `PATCH /notifications/:id/read` | `NotificationApi` | Account, NotificationsPage | F | covered | Badge, read/read-all va deep-link order/booking/support. |
| Addresses | `GET/POST /addresses`, `PATCH/DELETE /addresses/:id`, `PATCH /addresses/:id/default` | `AddressApi` | Account, AddressList/Form, Checkout | manual | covered | CRUD va default address co UI. |
| Support | `POST /support/tickets`, `GET /support/tickets/me`, `GET /support/tickets/:id`, `POST /support/tickets/:id/messages` | `SupportApi` | Account, ticket list/form/detail | F: model | covered | Toan bo customer ticket workflow co entry point. |
| News | `GET /news`, `GET /news/:id` | `NewsApi` | Home, NewsList/Detail | B: validation only | covered | List/detail public. |
| FAQ/pages/contact | `GET /faqs`, `GET /pages`, `GET /pages/:slug`, `POST /contact` | `HelpApi` | HelpCenter, StaticPageDetail, ContactPage | manual | covered | FAQ category hien chua can endpoint rieng. |
| FAQ categories | `GET /faqs/categories` | Khong co | HelpCenter hien tat ca FAQ | Khong | missing | Gap loc FAQ muc `low`; chi can khi du lieu FAQ tang. |
| Public config | `GET /settings/public`, `GET /bootstrap`, `GET /metadata[/:group]` | Khong co | App dung `/home`, `/app-status` va label noi bo | B: bootstrap only | partial | Day la cac endpoint tong hop/config; can quyet dinh kien truc truoc khi noi, khong tu dong them UI. |

## Gap can quyet dinh

| Uu tien | Gap | De xuat | Cach verify neu lam |
|---|---|---|---|
| Low | Loc FAQ theo category | Chi lam khi du lieu FAQ du nhieu; hien tai danh sach tong hop van day du. | HelpApi/widget test. |
| Architecture | Bootstrap/public settings/metadata | Chon mot chien luoc config duy nhat; khong goi ca `/home`, `/bootstrap` va `/settings/public` neu du lieu trung. | Contract test + startup/network inspection. |

## Test debt khong phai functional gap

Nhung domain co UI va caller nhung chua co Flutter API/widget test day du: product, branch, booking, cart, order, fulfillment, payment, voucher, favorite, address, news, search, help va app-status. Backend integration suite cung chua co file rieng cho notification, support, favorite, address, fulfillment, news/help va app-status.

De nghi khong mo rong feature hang loat trong Task 6. Uu tien them test khi cham vao tung domain, va giu device acceptance o Phase 3 de xac nhan cac luong chinh.

## Endpoint khong thuoc app khach hang

Khong xem la gap: admin user management, banner/category/brand/product/product-variant/court/time-slot CRUD, inventory, dashboard, branch-service management, uploads, audit logs, review moderation, reports, settings admin, contact/FAQ/static-page admin, notification broadcast, order/booking/fulfillment staff status va toan bo route yeu cau `ADMIN`, `BRANCH_MANAGER` hoac `STAFF`.
