# Customer app configuration decision

Ngay quyet dinh: 2026-10-06.

## Quyet dinh

Flutter customer app tiep tuc dung cac endpoint chuyen biet thay vi goi them `/bootstrap`, `/settings/public` va `/metadata` khi khoi dong.

| Endpoint | Quyet dinh | Ly do |
|---|---|---|
| `GET /app-status` | Giu | La nguon duy nhat cho maintenance va force update truoc khi vao app. |
| `GET /home` | Giu | Tra dung banner, tin tuc, san pham va san noi bat can cho HomePage. |
| `GET /bootstrap` | Khong noi Flutter | Trung nhieu du lieu voi `/home`, `/categories` va `/branches`; goi them lam tang thoi gian khoi dong. |
| `GET /settings/public` | Khong noi Flutter | UI hien tai khong co setting public nao ngoai maintenance/update da duoc `/app-status` xu ly. |
| `GET /metadata[/:group]` | Khong noi Flutter | Chu yeu phuc vu nhan enum/admin; app khach hang chi dung mot tap nho va da co mapping gan voi tung workflow. |

## Nguyen tac mo rong

Chi them caller cho mot endpoint tren khi co man hinh cu the can du lieu do. Khong tai dong thoi `/home` va `/bootstrap` cho cung mot lan khoi dong. Neu nhan enum can thay doi dong tu backend, chi tai nhom metadata lien quan thay vi tai toan bo metadata.

## Cach kiem chung

- Backend integration test giu contract public cho `/bootstrap`, `/settings/public` va `/metadata/:group`.
- Flutter startup tiep tuc duoc bao ve boi `AppStatusGuard`, sau do `HomePage` tai `/home`.
- Khong them network request moi vao qua trinh khoi dong.
