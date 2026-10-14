# N106 — Product image fixes and read-only native QA

Date: 2026-10-14. Branch main, HEAD 2a6a5be. Existing dirty work preserved; no stage/commit/push.

## Implemented in this turn

- admin_product_list_page.dart: replace network-only thumbnail with existing AppImage.
- admin_product_detail_page.dart: use AppImage for product and variant images. Keep sizes, clipping, BoxFit.cover and empty/error fallbacks.
- admin_product_form_page.dart / admin_variant_form_page.dart: accept bundled assets, root-relative paths and HTTP(S) URLs with a host. Keep trim/null payload and API unchanged. Reject unsupported schemes, malformed/empty paths, whitespace/backslashes, protocol-relative URLs and raw dot-segments.
- admin_product_page_test.dart: add image source matrix and edit/invalid-source regressions. RED reproduced both defects before fixes. No assertions removed.

## Verification

- Final focused product + AppImage: 40/40 passed.
- Final full Flutter suite: 401/401 passed.
- Final flutter analyze --no-pub: No issues found.
- git diff --check: exit 0 (existing CRLF warnings only).
- Final debug APK built with emulator API override, installed and launched on emulator-5554; logged-in ADMIN retained.
- ChatGPT approved image rendering iteration 2 and form validation iteration 3 through Codex with ChatGPT.
- ChatGPT approved scoped read-only native closeout iteration 4, explicitly leaving full R1 unaccepted.
- Sampled native logcat after navigation: no matching E/flutter, FlutterError, RenderFlex, setState-after-dispose or FATAL EXCEPTION. This is not a guarantee about every historical log or untested flow.

## Native coverage in this turn

- Product list/detail/variant: real bundled images now display. Evidence n106-products-fixed.png and n106-product-detail-fixed.png.
- Create product/variant forms: asset path accepted; required name/category or SKU/name/price still block invalid submit. No API mutation. Evidence n106-product-asset-validation.png, n106-variant-asset-validation.png, n106-variant-required-validation.png.
- Four admin tabs render. Booking list/status filter and date picker open/cancel work; current response empty, so booking detail/check-in/cancel not tested natively. Evidence n106-bookings-empty.png.
- Orders: status filter, existing delivery detail and Back navigation inspected. No status/cancel action. No pickup record available in inspected list. Product-items area was empty in that existing detail; cause not diagnosed, not accepted as verified order-items rendering.
- Inventory: low-stock list, existing form, numeric IME and required quantity validation. Back discards blank unsaved quantity; list still shows original 0. No save. Evidence n106-inventory-list.png, n106-inventory-ime.png and n106-inventory-validation.png.
- Admin account -> user Home -> Android Back returns to admin account and selected account tab. Evidence n106-user-return-home.png and n106-admin-return-account.png.

## Earlier native evidence preserved

News/banner/notification read-only UI and invalid validation; branch time fix and gallery open/cancel; court/slot/price invalid validation and navigation. Details in tasks/admin_ui_next_steps.md. No real notification, upload, seed/reset or business state mutation.

## Still not accepted

- Real save/create/upload/crop/permission-success flows; order/booking state mutations.
- Other-role login, logout/session expiration, physical device.
- Native booking detail and pickup-order detail with real records; order item rendering/data integrity.
- Demo data maps some apparel/grip products to racket images. Existing mapping left unchanged; renderer fix does not correct data.

Emulator/backend remain running. This report does not mark full R1/device acceptance complete.
