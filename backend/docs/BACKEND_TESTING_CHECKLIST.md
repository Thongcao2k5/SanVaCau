# SanVaCau Backend Testing Checklist

A quick checklist for manually verifying the backend API works correctly.

---

## Prerequisites

```bash
# 1. PostgreSQL is running on localhost:5432
# 2. Database "sanvacau" exists

# 3. Install dependencies
npm install

# 4. Push schema & generate client
npx prisma db push
npx prisma generate

# 5. Start dev server
npm run dev
# → http://localhost:3000

# 6. Create admin account
curl -X POST http://localhost:3000/api/auth/dev/create-admin \
  -H "Content-Type: application/json" \
  -d '{"password": "Admin123456"}'
```

**Admin credentials:** `admin@shopvacau.com` / `Admin123456`

---

## Import Postman Collection

1. Open Postman
2. Import `docs/SanVaCau.postman_collection.json`
3. The collection variables (`baseUrl`, `adminToken`, etc.) are pre-configured
4. Run requests in the suggested order below

---

## Testing Flow

### ✅ Phase 1: Health & Infrastructure

| # | Test | Expected |
|---|------|----------|
| 1 | `GET /api/health` | `200` — `{ success: true, message: "SanVaCau API is running" }` |
| 2 | `GET /api/health/db` | `200` — `{ success: true, database: "connected" }` |
| 3 | Send invalid JSON body (e.g., `{invalid}`) to any POST | `400` — `{ success: false, message: "Invalid JSON body" }` |

### ✅ Phase 2: Auth

| # | Test | Expected |
|---|------|----------|
| 4 | `POST /api/auth/dev/create-admin` | `201` — admin created, token returned |
| 5 | `POST /api/auth/login` (admin) | `200` — token returned, auto-saved |
| 6 | `POST /api/auth/login` (wrong password) | `401` — `{ success: false, message: "invalid email or password" }` |
| 7 | `POST /api/auth/register` (new customer) | `201` — customer created |
| 8 | `POST /api/auth/register` (duplicate email) | `409` — `email already exists` |
| 9 | `GET /api/auth/me` (with token) | `200` — current user info |
| 10 | `GET /api/auth/admin-check` (with adminToken) | `200` — admin access granted |
| 11 | `GET /api/auth/admin-check` (with customerToken) | `403` — forbidden |

### ✅ Phase 3: Public Data

| # | Test | Expected |
|---|------|----------|
| 12 | `GET /api/bootstrap` | `200` — settings, banners, categories, branches, news, products |
| 13 | `GET /api/home` | `200` — banners, featuredProducts, latestNews, branches |
| 14 | `GET /api/metadata` | `200` — all enum values |
| 15 | `GET /api/categories` | `200` — category list |
| 16 | `GET /api/brands` | `200` — brand list |
| 17 | `GET /api/products` | `200` — product list |
| 18 | `GET /api/branches` | `200` — branch list |
| 19 | `GET /api/courts` | `200` — court list |
| 20 | `GET /api/courts/time-slots` | `200` — time slot list |

### ✅ Phase 4: Customer Shopping Flow

| # | Test | Expected |
|---|------|----------|
| 21 | `GET /api/cart` (customerToken) | `200` — empty or existing cart |
| 22 | `POST /api/cart/items` (add item) | `200` — item added |
| 23 | `POST /api/orders` (from cart) | `201` — order created |
| 24 | `GET /api/orders/me` | `200` — customer's orders |

### ✅ Phase 5: Customer Booking Flow

| # | Test | Expected |
|---|------|----------|
| 25 | `GET /api/bookings/availability?courtId=1&date=2026-01-15` | `200` — slot availability |
| 26 | `POST /api/bookings` (with timeSlotIds) | `201` — booking created |
| 27 | `GET /api/bookings/me` | `200` — customer's bookings |

### ✅ Phase 6: Payment

| # | Test | Expected |
|---|------|----------|
| 28 | `POST /api/payments/mock` | `201` — payment created |
| 29 | `PATCH /api/payments/:id/mock-success` | `200` — payment marked paid |
| 30 | `GET /api/payments/me` | `200` — customer's payments |

### ✅ Phase 7: Support & Content

| # | Test | Expected |
|---|------|----------|
| 31 | `POST /api/contact` (public form) | `201` — message submitted |
| 32 | `POST /api/support/tickets` (customer) | `201` — ticket created |
| 33 | `GET /api/faqs` | `200` — published FAQs |
| 34 | `GET /api/pages` | `200` — published pages |
| 35 | `GET /api/news` | `200` — published news |

### ✅ Phase 8: Admin Operations

| # | Test | Expected |
|---|------|----------|
| 36 | `GET /api/bookings` (adminToken) | `200` — all bookings |
| 37 | `GET /api/orders` (adminToken) | `200` — all orders |
| 38 | `GET /api/dashboard/summary` (adminToken) | `200` — summary stats |
| 39 | `GET /api/audit-logs` (adminToken) | `200` — audit trail |
| 40 | `GET /api/auth/admin/users` (adminToken) | `200` — user list |

---

## Error Handling Tests

| Scenario | Method | Expected |
|----------|--------|----------|
| Invalid JSON body | POST any endpoint with `{bad json}` | `400` — `"Invalid JSON body"` |
| Missing auth token | GET protected endpoint | `401` — unauthorized |
| Wrong role | Customer calling admin endpoint | `403` — forbidden |
| Resource not found | GET `/api/products/99999` | `404` — not found |
| Duplicate resource | POST `/api/auth/register` with existing email | `409` — conflict |
| Rate limit exceeded | Spam `POST /api/auth/login` 20+ times in 15 min | `429` — `"Too many requests, please try again later"` |

---

## Rate Limiting Notes

⚠️ **Important:** During development testing, you may hit the **auth rate limit** (20 requests per 15 minutes per IP) if you repeatedly call login/register endpoints. If you get a `429` response:

1. **Wait 15 minutes** for the window to reset, OR
2. **Restart the dev server** to clear the in-memory rate limit store

The rate limits are:
- **General:** 300 requests / 15 min (all endpoints)
- **Auth:** 20 requests / 15 min (login, register, dev-admin)
- **Contact:** 30 requests / 15 min (public contact submit)

---

## Quality Check Commands

```bash
# TypeScript type check (no errors expected)
npm run typecheck

# Build production bundle (no errors expected)
npm run build

# Verify Postman collection is valid JSON
node -e "JSON.parse(require('fs').readFileSync('docs/SanVaCau.postman_collection.json', 'utf8')); console.log('Valid JSON')"
```

---

## Seeded Data Notes

- The **dev admin** is created via `POST /api/auth/dev/create-admin` and is NOT automatically seeded.
- All other data (branches, courts, products, categories, etc.) must be created by the admin after login.
- If you need sample data, use the admin token to create resources through the API or write a seed script.

---

## Pass/Fail Criteria

✅ **PASS** — All checklist items return expected status codes and response shapes.

❌ **FAIL** conditions:
- Any endpoint returns `500` for valid input
- Auth endpoints don't return tokens
- Protected endpoints are accessible without tokens
- Rate limit doesn't trigger after exceeding the limit
- Invalid JSON doesn't return `400`
