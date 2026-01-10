# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

### Flutter Frontend
```bash
# Get dependencies
flutter pub get

# Run web app (local development)
flutter run -d chrome --web-port 8080

# Run inside Docker dev container
docker compose up -d
docker exec -it bb_draft_dev bash
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0

# Build for production
flutter build web --release --base-href /bb-draft/

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test.dart

# Analyze code (lint)
flutter analyze
```

### Node.js Backend
```bash
cd bb-draft-backend

# Install dependencies
npm install

# Run development server (hot reload)
npm run dev

# Build TypeScript
npm run build

# Run production server
npm start

# Run tests
npm test

# Run a single test file
npm test -- src/utils/dateUtils.test.ts
```

## Architecture Overview

### Monorepo Structure
- **Flutter web app** (root `lib/`) - Frontend using Provider for state management
- **Express backend** (`bb-draft-backend/`) - Node.js API with TypeScript
- **DynamoDB** - NoSQL database (local port 8001, uses AWS SDK v3)

### Frontend Architecture (Flutter)

**State Management:** Uses Provider pattern with ChangeNotifier
- `AuthProvider` - Firebase Auth state, Google Sign-In
- `StatusProvider` - Backend/database connectivity status

**Key patterns:**
- Screens in `lib/screens/{feature}/` (e.g., `auth/`, `home/`)
- Shared widgets in `lib/widgets/`
- API calls through `lib/services/api_service.dart`
- Routes defined in `lib/config/routes.dart`
- Environment config via `--dart-define` flags during build

### Backend Architecture (Express/TypeScript)

**API Structure:**
- Entry point: `src/index.ts`
- Routes: `src/routes/*.ts` (health, users, version)
- Models: `src/models/*.ts` - DynamoDB operations using AWS SDK v3
- Middleware: `src/middleware/auth.ts` - Firebase token verification
- Types: `src/types/index.ts`

**DynamoDB patterns:**
- Use `getDocClient()` from `config/database.ts` for operations
- Tables defined in `TABLES` constant in `config/database.ts`
- Models export functions like `getUser()`, `putUser()`, `upsertUser()`

### Authentication Flow
1. Frontend uses Firebase Auth (Google Sign-In or email/password)
2. Firebase ID token sent to backend in Authorization header
3. Backend verifies token via Firebase Admin SDK
4. User data stored in DynamoDB `bb_draft_users` table

## Infrastructure

### Production URLs
- Frontend: https://zycroft.duckdns.org/bb-draft/
- Backend API: https://zycroft.duckdns.org/bb-draft-api/
- Health Check: https://zycroft.duckdns.org/bb-draft-api/health

### Deployment
Push to `main` triggers GitHub Actions deployment:
1. Flutter builds with version from backend API
2. Frontend copies to `/var/www/html/bb-draft/`
3. Backend Docker container rebuilds on server

### Local Development URLs
- Frontend: http://localhost:8080
- Backend: http://localhost:3000
- DynamoDB Local: http://localhost:8001

## Configuration Files

| File | Purpose |
|------|---------|
| `lib/config/api_config.dart` | API base URL (auto-detects localhost vs production) |
| `lib/config/app_config.dart` | Feature flags (e.g., `showDevStatusIndicators`) |
| `bb-draft-backend/.env` | Backend environment variables |
| `bb-draft-backend/docker-compose.prod.yml` | Production Docker config |

## DynamoDB Tables
- `bb_draft_users` - User profiles (partition key: `userId`)
- `bb_draft_versions` - Version tracking (partition key: `date`)

## Plan Files
Implementation plans are stored in `docs/plans/`. Use `docs/plans/template.plan.md` as the template for new features.
