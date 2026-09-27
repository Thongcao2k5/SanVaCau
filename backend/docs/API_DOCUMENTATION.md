# SanVaCau Backend API Documentation

> **Base URL:** `http://localhost:3000/api`
> **Auth:** Bearer Token (JWT)
> **Content-Type:** `application/json`

---

## Table of Contents

1. [Overview](#overview)
2. [Local Setup](#local-setup)
3. [Roles & Authentication](#roles--authentication)
4. [Response Format](#response-format)
5. [Rate Limiting](#rate-limiting)
6. [API Modules](#api-modules)
   - [Health](#health)
   - [Auth](#auth)
   - [Bootstrap & Home](#bootstrap--home)
   - [Branches](#branches)
   - [Categories](#categories)
   - [Brands](#brands)
   - [Products](#products)
   - [Product Variants](#product-variants)
   - [Inventory](#inventory)
   - [Courts & Time Slots](#courts--time-slots)
   - [Bookings](#bookings)
   - [Cart](#cart)
   - [Orders](#orders)
   - [Fulfillments](#fulfillments)
   - [Payments](#payments)
   - [Reviews](#reviews)
   - [Favorites](#favorites)
   - [Search](#search)
   - [Addresses](#addresses)
   - [Vouchers](#vouchers)
   - [Notifications](#notifications)
   - [Support Tickets](#support-tickets)
   - [Contact](#contact)
   - [FAQs](#faqs)
   - [Static Pages](#static-pages)
   - [News](#news)
   - [Banners](#banners)
   - [Settings](#settings)
   - [App Status](#app-status)
   - [Metadata](#metadata)
   - [Reports & Dashboard](#reports--dashboard)
   - [Uploads](#uploads)
   - [Audit Logs](#audit-logs)
   - [Profile](#profile)
   - [Racket Services](#racket-services)
   - [Branch Services](#branch-services)
7. [Suggested Testing Flow](#suggested-testing-flow)

---

## Overview

SanVaCau is a badminton court booking & shop management platform. This backend provides APIs for:

- **Customers:** Browse products/courts, manage cart, place orders, book courts, make payments, submit reviews, manage favorites and addresses.
- **Staff/Branch Managers:** Manage bookings, orders, fulfillments and inventory for their branch.
- **Admin:** Full management of branches, products, courts, users, vouchers, content (news, banners, FAQs, pages), settings, and reports.

---

## Local Setup

```bash
# 1. Start PostgreSQL (make sure it's running on localhost:5432)

# 2. Copy .env from .env.example if needed

# 3. Install dependencies
npm install

# 4. Push schema to database
npx prisma db push

# 5. Generate Prisma client
npx prisma generate

# 6. Start dev server
npm run dev
# Server runs on http://localhost:3000
```

### Seed Admin Account

Use the dev endpoint to create an admin account:

```bash
curl -X POST http://localhost:3000/api/auth/dev/create-admin \
  -H "Content-Type: application/json" \
  -d '{"password": "Admin123456"}'
```

**Admin credentials:**
- Email: `admin@shopvacau.com`
- Password: `Admin123456`

---

## Roles & Authentication

| Role | Description |
|------|-------------|
| `ADMIN` | Full system access |
| `BRANCH_MANAGER` | Manage their assigned branch |
| `STAFF` | Basic branch operations |
| `CUSTOMER` | Shopping, booking, orders |

**Authentication:** Include the JWT token in the `Authorization` header:

```
Authorization: Bearer <token>
```

---

## Response Format

### Success

```json
{
  "success": true,
  "data": { ... }
}
```

### Success with message

```json
{
  "success": true,
  "message": "Resource created successfully",
  "data": { ... }
}
```

### Error

```json
{
  "success": false,
  "message": "Error description"
}
```

### Common HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 400 | Bad Request / Validation Error |
| 401 | Unauthorized (missing/invalid token) |
| 403 | Forbidden (wrong role) |
| 404 | Not Found |
| 409 | Conflict (duplicate) |
| 429 | Too Many Requests (rate limit) |
| 500 | Internal Server Error |

---

## Rate Limiting

| Limiter | Window | Max Requests | Applied To |
|---------|--------|--------------|------------|
| General | 15 min | 300/IP | All `/api` endpoints |
| Auth | 15 min | 20/IP | Login, Register, Dev Admin |
| Public Write | 15 min | 30/IP | Contact submit |

Rate-limited response (429):

```json
{
  "success": false,
  "message": "Too many requests, please try again later"
}
```

---

## API Modules

---

### Health

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/health` | Public | API health check |
| GET | `/health/db` | Public | Database connectivity check |

**Response:**

```json
{ "success": true, "message": "SanVaCau API is running" }
```

---

### Auth

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| POST | `/auth/register` | Public | Register customer account |
| POST | `/auth/login` | Public | Login and get JWT token |
| POST | `/auth/dev/create-admin` | Public | Create/reset admin (dev only) |
| GET | `/auth/me` | Authenticated | Get current user from token |
| GET | `/auth/profile` | Authenticated | Get full profile from DB |
| PATCH | `/auth/profile` | Authenticated | Update name/phone |
| POST | `/auth/change-password` | Authenticated | Change password |
| GET | `/auth/admin-check` | ADMIN | Verify admin access |
| POST | `/auth/admin/users` | ADMIN | Create staff/manager account |
| GET | `/auth/admin/users` | ADMIN | List all users (paginated) |
| PATCH | `/auth/admin/users/:id/status` | ADMIN | Lock/unlock user |
| PATCH | `/auth/admin/users/:id/password` | ADMIN | Reset user password |

**Register:**

```json
POST /auth/register
{
  "email": "test@example.com",
  "password": "Test123456",
  "fullName": "Nguyễn Văn Test",
  "phone": "0901234567"
}
```

**Login:**

```json
POST /auth/login
{
  "email": "admin@shopvacau.com",
  "password": "Admin123456"
}
```

**Response:**

```json
{
  "success": true,
  "data": {
    "user": {
      "id": "1",
      "email": "admin@shopvacau.com",
      "fullName": "Quản trị viên",
      "role": "ADMIN",
      "status": "ACTIVE",
      "branchId": null
    },
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

---

### Bootstrap & Home

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/bootstrap` | Public | All initial app data in one call |
| GET | `/home` | Public | Home page data (banners, featured, news, branches) |

**Bootstrap query:** `?branchId=1` (optional)

**Bootstrap returns:** `settings`, `banners`, `categories` (tree), `branches`, `latestNews`, `featuredProducts`

---

### Branches

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/branches` | Public | List active branches |
| GET | `/branches/:id` | Public | Branch detail |
| GET | `/branches/:id/availability` | Public | Court availability by date |
| GET | `/branches/:id/services` | Public | Branch racket services |
| POST | `/branches` | ADMIN | Create branch |
| PATCH | `/branches/:id` | ADMIN | Update branch |
| PATCH | `/branches/:id/inactivate` | ADMIN | Inactivate branch |

**Availability query:** `?date=2026-01-15` (YYYY-MM-DD, required)

**Create branch:**

```json
POST /branches
{
  "name": "Chi nhánh Quận 1",
  "address": "123 Nguyễn Huệ, Q1, TP.HCM",
  "phone": "0281234567",
  "openingTime": "06:00",
  "closingTime": "22:00"
}
```

---

### Categories

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/categories` | Public | List active categories (tree) |
| GET | `/categories/:id` | Public | Category detail |
| POST | `/categories` | ADMIN | Create category |
| PATCH | `/categories/:id` | ADMIN | Update category |
| PATCH | `/categories/:id/inactivate` | ADMIN | Inactivate category |

---

### Brands

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/brands` | Public | List active brands |
| GET | `/brands/:id` | Public | Brand detail |
| POST | `/brands` | ADMIN | Create brand |
| PATCH | `/brands/:id` | ADMIN | Update brand |
| PATCH | `/brands/:id/inactivate` | ADMIN | Inactivate brand |

---

### Products

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/products` | Public | List active products |
| GET | `/products/:id` | Public | Product detail |
| POST | `/products` | ADMIN | Create product |
| PATCH | `/products/:id` | ADMIN | Update product |
| PATCH | `/products/:id/inactivate` | ADMIN | Inactivate product |

**Query params:** `?categoryId=1&brandId=1&featured=true`

**Create product:**

```json
POST /products
{
  "categoryId": "1",
  "brandId": "1",
  "name": "Vợt cầu lông Yonex Astrox 88D",
  "description": "Vợt tấn công chuyên nghiệp",
  "imageUrl": "/uploads/products/yonex-88d.jpg",
  "isFeatured": true
}
```

---

### Product Variants

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/product-variants` | Public | List variants (filter by productId) |
| GET | `/product-variants/:id` | Public | Variant detail |
| POST | `/product-variants` | ADMIN | Create variant |
| PATCH | `/product-variants/:id` | ADMIN | Update variant |
| PATCH | `/product-variants/:id/inactivate` | ADMIN | Inactivate variant |

**Query params:** `?productId=1`

---

### Inventory

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/inventories` | ADMIN/BM/STAFF | List inventory |
| GET | `/inventories/:id` | ADMIN/BM/STAFF | Inventory detail |
| POST | `/inventories` | ADMIN/BM | Create/set inventory |
| PATCH | `/inventories/:id` | ADMIN/BM | Update quantity |

**Query params:** `?branchId=1&productVariantId=1`

---

### Courts & Time Slots

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/courts` | Public | List active courts |
| GET | `/courts/:id` | Public | Court detail |
| GET | `/courts/time-slots` | Public | List active time slots |
| GET | `/courts/:id/prices` | Public | Court prices per time slot |
| POST | `/courts` | ADMIN | Create court |
| PATCH | `/courts/:id` | ADMIN | Update court |
| PATCH | `/courts/:id/inactivate` | ADMIN | Inactivate court |
| POST | `/courts/time-slots` | ADMIN | Create time slot |
| PATCH | `/courts/time-slots/:id` | ADMIN | Update time slot |
| PUT | `/courts/:id/prices` | ADMIN | Set court prices |

**Query params for courts:** `?branchId=1`

**Set court prices:**

```json
PUT /courts/1/prices
{
  "prices": [
    { "timeSlotId": "1", "price": 100000 },
    { "timeSlotId": "2", "price": 120000 }
  ]
}
```

---

### Bookings

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/bookings/availability` | Public | Check slot availability |
| POST | `/bookings` | CUSTOMER | Create booking |
| GET | `/bookings/me` | Authenticated | My bookings |
| PATCH | `/bookings/:id/cancel` | Authenticated | Cancel own booking |
| GET | `/bookings` | ADMIN/BM/STAFF | List all bookings |
| PATCH | `/bookings/:id/status` | ADMIN/BM/STAFF | Update booking status |

**Check availability query:** `?courtId=1&date=2026-01-15`

**Create booking:**

```json
POST /bookings
{
  "courtId": "1",
  "bookingDate": "2026-01-15",
  "timeSlotIds": ["1", "2"],
  "paymentMethod": "CASH"
}
```

**Booking statuses:** `BOOKED` → `CHECKED_IN` → `COMPLETED` or `CANCELLED`

---

### Cart

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/cart` | CUSTOMER | View my cart |
| POST | `/cart/items` | CUSTOMER | Add item to cart |
| PATCH | `/cart/items/:id` | CUSTOMER | Update item quantity |
| DELETE | `/cart/items/:id` | CUSTOMER | Remove item from cart |
| DELETE | `/cart` | CUSTOMER | Clear cart |

**Add to cart:**

```json
POST /cart/items
{
  "productVariantId": "1",
  "quantity": 2
}
```

---

### Orders

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| POST | `/orders` | CUSTOMER | Create order from cart |
| GET | `/orders/me` | CUSTOMER | My orders |
| GET | `/orders/me/:id` | CUSTOMER | My order detail |
| GET | `/orders` | ADMIN/BM/STAFF | List all orders |
| GET | `/orders/:id` | ADMIN/BM/STAFF | Order detail |
| PATCH | `/orders/:id/status` | ADMIN/BM/STAFF | Update order status |

**Create order:**

```json
POST /orders
{
  "branchId": "1"
}
```

**Order statuses:** `PENDING` → `READY_FOR_PICKUP` → `COMPLETED` or `CANCELLED`

---

### Fulfillments

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| POST | `/fulfillments/orders/:orderId` | CUSTOMER | Create fulfillment for order |
| GET | `/fulfillments/orders/:orderId` | Authenticated | Get order fulfillment |
| GET | `/fulfillments/me` | CUSTOMER | My fulfillments |
| GET | `/fulfillments` | ADMIN/BM/STAFF | All fulfillments |
| PATCH | `/fulfillments/:id/status` | ADMIN/BM/STAFF | Update fulfillment status |

---

### Payments

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| POST | `/payments/mock` | Authenticated | Create mock payment |
| PATCH | `/payments/:id/mock-success` | Authenticated | Mark payment as paid |
| PATCH | `/payments/:id/mock-fail` | Authenticated | Mark payment as failed |
| GET | `/payments/me` | Authenticated | My payments |
| GET | `/payments` | ADMIN | All payments |

**Create mock payment:**

```json
POST /payments/mock
{
  "targetType": "BOOKING",
  "targetId": "1",
  "provider": "MOCK",
  "amount": 200000
}
```

**Target types:** `ORDER`, `BOOKING`
**Providers:** `CASH`, `MOCK`

---

### Reviews

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| POST | `/reviews` | CUSTOMER | Create review |
| PATCH | `/reviews/:id` | CUSTOMER | Update own review |
| GET | `/reviews/products/:productId` | Public | Product reviews |
| GET | `/reviews/courts/:courtId` | Public | Court reviews |
| GET | `/reviews/me` | Authenticated | My reviews |
| GET | `/reviews` | ADMIN | All reviews |
| PATCH | `/reviews/:id/status` | ADMIN | Moderate review |

**Create review:**

```json
POST /reviews
{
  "targetType": "PRODUCT",
  "targetId": "1",
  "rating": 5,
  "comment": "Vợt rất tốt!"
}
```

---

### Favorites

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| POST | `/favorites` | Authenticated | Add to favorites |
| DELETE | `/favorites` | Authenticated | Remove from favorites |
| GET | `/favorites` | Authenticated | My favorites |
| GET | `/favorites/check` | Authenticated | Check if favorited |

**Add favorite:**

```json
POST /favorites
{
  "targetType": "PRODUCT",
  "targetId": "1"
}
```

**Query for check:** `?targetType=PRODUCT&targetId=1`

---

### Search

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/search` | Public | Universal search |

**Query params:** `?q=yonex&type=PRODUCT&page=1&limit=20`

**Types:** `ALL`, `PRODUCT`, `COURT`, `BRANCH`, `NEWS`

---

### Addresses

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/addresses` | CUSTOMER | My addresses |
| POST | `/addresses` | CUSTOMER | Add address |
| PATCH | `/addresses/:id` | CUSTOMER | Update address |
| DELETE | `/addresses/:id` | CUSTOMER | Delete address |
| PATCH | `/addresses/:id/default` | CUSTOMER | Set as default |

**Add address:**

```json
POST /addresses
{
  "recipientName": "Nguyễn Văn A",
  "phone": "0901234567",
  "addressLine": "123 Lê Lợi",
  "ward": "Phường 1",
  "district": "Quận 1",
  "city": "TP.HCM",
  "isDefault": true
}
```

---

### Vouchers

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| POST | `/vouchers` | ADMIN | Create voucher |
| GET | `/vouchers` | ADMIN | List vouchers |
| PATCH | `/vouchers/:id` | ADMIN | Update voucher |
| PATCH | `/vouchers/:id/inactive` | ADMIN | Deactivate voucher |
| POST | `/vouchers/validate` | Authenticated | Validate voucher code |
| POST | `/vouchers/apply` | Authenticated | Apply voucher to target |

**Validate voucher:**

```json
POST /vouchers/validate
{
  "code": "SALE10",
  "targetType": "ORDER",
  "targetId": "1"
}
```

---

### Notifications

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/notifications` | Authenticated | My notifications |
| GET | `/notifications/unread-count` | Authenticated | Unread count |
| PATCH | `/notifications/read-all` | Authenticated | Mark all read |
| PATCH | `/notifications/:id/read` | Authenticated | Mark one read |
| POST | `/notifications/admin` | ADMIN | Send notification to user |

---

### Support Tickets

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| POST | `/support/tickets` | CUSTOMER | Create ticket |
| GET | `/support/tickets/me` | CUSTOMER | My tickets |
| GET | `/support/tickets/:id` | Authenticated | Ticket detail |
| POST | `/support/tickets/:id/messages` | Authenticated | Add message |
| GET | `/support/tickets` | ADMIN/BM/STAFF | All tickets |
| PATCH | `/support/tickets/:id/status` | ADMIN/BM/STAFF | Update status |
| PATCH | `/support/tickets/:id/assign` | ADMIN | Assign staff |

**Create ticket:**

```json
POST /support/tickets
{
  "subject": "Không đặt được sân",
  "message": "Tôi không thể đặt sân ngày 15/1",
  "category": "BOOKING",
  "priority": "HIGH"
}
```

---

### Contact

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| POST | `/contact` | Public | Submit contact message |
| GET | `/contact` | ADMIN | List messages |
| GET | `/contact/:id` | ADMIN | Message detail |
| PATCH | `/contact/:id/status` | ADMIN | Update status |
| DELETE | `/contact/:id` | ADMIN | Delete message |

**Submit contact:**

```json
POST /contact
{
  "fullName": "Nguyễn Văn A",
  "email": "test@example.com",
  "phone": "0901234567",
  "type": "GENERAL",
  "subject": "Hỏi về dịch vụ",
  "message": "Tôi muốn hỏi về dịch vụ căng vợt"
}
```

**Contact types:** `GENERAL`, `BUG`, `FEATURE_REQUEST`, `COMPLAINT`, `PARTNERSHIP`
**Contact statuses:** `NEW`, `READ`, `IN_PROGRESS`, `RESOLVED`, `ARCHIVED`

---

### FAQs

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/faqs` | Public | Published FAQs (paginated) |
| GET | `/faqs/categories` | Public | FAQ categories with count |
| GET | `/faqs/:id` | Public | FAQ detail (increments views) |
| GET | `/faqs/admin` | ADMIN | All FAQs (paginated) |
| POST | `/faqs` | ADMIN | Create FAQ |
| PATCH | `/faqs/:id` | ADMIN | Update FAQ |
| DELETE | `/faqs/:id` | ADMIN | Delete FAQ |

**Query params:** `?category=GENERAL&search=keyword&page=1&limit=20`

---

### Static Pages

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/pages` | Public | Published pages (paginated) |
| GET | `/pages/:slug` | Public | Page by slug |
| GET | `/pages/admin` | ADMIN | All pages (admin) |
| POST | `/pages` | ADMIN | Create page |
| PATCH | `/pages/:id` | ADMIN | Update page |
| DELETE | `/pages/:id` | ADMIN | Delete page |

**Page types:** `TERMS`, `PRIVACY`, `RETURN_POLICY`, `PAYMENT_GUIDE`, `BOOKING_GUIDE`, `WARRANTY`, `ABOUT`, `OTHER`

**Create page:**

```json
POST /pages
{
  "slug": "chinh-sach-bao-mat",
  "title": "Chính sách bảo mật",
  "summary": "Quy định về bảo mật thông tin",
  "content": "<p>Nội dung chi tiết...</p>",
  "type": "PRIVACY",
  "status": "PUBLISHED",
  "sortOrder": 1
}
```

---

### News

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/news` | Public | Published news (paginated) |
| GET | `/news/:id` | Public | News detail |
| POST | `/news` | ADMIN | Create news |
| PATCH | `/news/:id` | ADMIN | Update news |
| PATCH | `/news/:id/publish` | ADMIN | Publish news |
| PATCH | `/news/:id/archive` | ADMIN | Archive news |

---

### Banners

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/banners` | Public | Active banners |
| POST | `/banners` | ADMIN | Create banner |
| PATCH | `/banners/:id` | ADMIN | Update banner |
| PATCH | `/banners/:id/inactivate` | ADMIN | Inactivate banner |

---

### Settings

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/settings/public` | Public | Public settings |
| GET | `/settings` | Authenticated | All settings (admin) |
| GET | `/settings/:key` | Authenticated | Get setting by key |
| PUT | `/settings/:key` | Authenticated | Create/update setting |
| DELETE | `/settings/:key` | Authenticated | Delete setting |

---

### App Status

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/app-status?platform=android&version=1.0.0` | Public | Get app maintenance/update status |
| PUT | `/app-status` | ADMIN | Update app status |

Required query for `GET /app-status`: `platform=android|ios`, `version=x.y.z`.

---

### Metadata

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/metadata` | Public | All enum/metadata values |
| GET | `/metadata/:group` | Public | Specific metadata group |

---

### Reports & Dashboard

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/dashboard/summary` | ADMIN/BM/STAFF | Dashboard summary |
| GET | `/reports/overview` | Public | Revenue overview |
| GET | `/reports/orders` | Public | Order statistics |
| GET | `/reports/bookings` | Public | Booking statistics |
| GET | `/reports/top-products` | Public | Top selling products |
| GET | `/reports/top-courts` | Public | Most booked courts |

**Query params for reports:** `?branchId=1&from=2026-01-01&to=2026-01-31`

---

### Uploads

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| POST | `/uploads` | Authenticated | Upload file (multipart) |

**Form data:** `file` (multipart/form-data)

---

### Audit Logs

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/audit-logs` | ADMIN | View audit trail |

---

### Profile

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/profile` | Authenticated | Get detailed profile |
| PATCH | `/profile` | Authenticated | Update profile |

---

### Racket Services

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/racket-services` | Public | List services |
| GET | `/racket-services/:id` | Public | Service detail |
| POST | `/racket-services` | ADMIN | Create service |
| PATCH | `/racket-services/:id` | ADMIN | Update service |
| PATCH | `/racket-services/:id/inactivate` | ADMIN | Inactivate service |

---

### Branch Services

| Method | Endpoint | Access | Purpose |
|--------|----------|--------|---------|
| GET | `/branch-services` | ADMIN/BM | List branch services |
| POST | `/branch-services` | ADMIN/BM | Assign service to branch |
| PATCH | `/branch-services/:id` | ADMIN/BM | Update branch service |
| PATCH | `/branch-services/:id/unavailable` | ADMIN/BM | Mark unavailable |

---

## Suggested Testing Flow

Here is a recommended step-by-step flow for testing the API with Postman:

### 1. Health Check
```
GET /api/health
GET /api/health/db
```

### 2. Create Admin & Login
```
POST /api/auth/dev/create-admin → { "password": "Admin123456" }
POST /api/auth/login → { "email": "admin@shopvacau.com", "password": "Admin123456" }
→ Save token as adminToken
```

### 3. Bootstrap / Home
```
GET /api/bootstrap
GET /api/home
GET /api/metadata
```

### 4. Browse Products
```
GET /api/categories
GET /api/brands
GET /api/products
GET /api/products/:id
GET /api/product-variants?productId=:id
```

### 5. Browse Courts
```
GET /api/branches
GET /api/courts?branchId=1
GET /api/courts/time-slots
GET /api/courts/:id/prices
GET /api/bookings/availability?courtId=1&date=2026-01-15
```

### 6. Register & Login Customer
```
POST /api/auth/register → create a customer account
POST /api/auth/login → login as customer, save customerToken
```

### 7. Customer: Cart & Order
```
GET /api/cart
POST /api/cart/items → add product variant
POST /api/orders → { "branchId": "1" }
GET /api/orders/me
```

### 8. Customer: Book a Court
```
POST /api/bookings → { "courtId": "1", "bookingDate": "2026-01-15", "timeSlotIds": ["1"] }
GET /api/bookings/me
```

### 9. Payment
```
POST /api/payments/mock → create payment for booking or order
PATCH /api/payments/:id/mock-success → simulate payment success
GET /api/payments/me
```

### 10. Support, Contact, FAQ, Pages
```
POST /api/contact → submit contact form
POST /api/support/tickets → create support ticket
GET /api/faqs → browse FAQs
GET /api/pages → browse published pages
```
