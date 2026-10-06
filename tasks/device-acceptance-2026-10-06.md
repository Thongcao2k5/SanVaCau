# Device acceptance - 2026-10-06

Thiet bi: Android Emulator `Pixel_6_Pro`, do phan giai 1440x3120.

## Ket qua

| Luong | Ket qua | Bang chung |
|---|---|---|
| Khoi dong va Home | Pass; app goi backend local va hien thi Home. | `SanVaCau_product_list_verified.png` |
| Loc san pham | Pass sau khi sua; `Vot cau long + Yonex` tra san pham trong danh muc con `Vot Yonex`. | `SanVaCau_product_filter.png`, `SanVaCau_product_parent_filter_fixed.png` |
| Xoa toan bo gio hang | Pass; nut chi hien khi co item, dialog xac nhan hien dung, xoa xong ve empty state va co SnackBar. | `SanVaCau_clear_cart_dialog.png`, `SanVaCau_cart_cleared.png` |
| Loc FAQ | Pass; chon `Dat san` chi hien cau hoi thuoc danh muc dat san. | `SanVaCau_help_center.png`, `SanVaCau_help_booking_filter.png` |
| Danh gia cua toi | Pass entry point va empty state tren tai khoan demo. | `SanVaCau_my_reviews.png` |

Anh duoc luu tai `C:/Users/thong/Downloads/` de nguoi dung xem truc tiep.

## Gioi han

Tai khoan demo khong co review du dieu kien, nen khong sua review that tren emulator trong luot nay. Luong list/edit/error da duoc bao phu boi Flutter widget/API tests va backend integration tests.

## Loi phat hien khi nghiem thu

Loc theo category cha ban dau chi query chinh ID cha, lam san pham trong category con bi bo sot. Da sua backend de gom toan bo category con dang active va them integration test chong tai phat.
