# Sân&Cầu

Ứng dụng cầu lông Sân&Cầu.

## Architecture

```text
Flutter
    ↓ REST/JSON
Node.js + TypeScript + Express
    ↓ Prisma
PostgreSQL
```

## Frontend

```bash
cd frontend/san_va_cau_app
flutter pub get
flutter analyze
```

## Backend

```bash
cd backend
npm install
npm run dev
npm run build
npm start
```

Backend health check:

```text
GET http://localhost:3000/health
```
