# BB Draft - Project Context

## Overview
BaseBall Draft is a Flutter web application with a Node.js/Express backend, using Firebase for authentication and DynamoDB for data storage.

## Infrastructure

### Production URLs
- **Frontend**: https://zycroft.duckdns.org/bb-draft/
- **Backend API**: https://zycroft.duckdns.org/bb-draft-api/
- **Health Check**: https://zycroft.duckdns.org/bb-draft-api/health
- **DB Health Check**: https://zycroft.duckdns.org/bb-draft-api/health/db

### Server
- **Host**: 172.251.19.6 (zycroft.duckdns.org)
- **Web Server**: nginx
- **Backend**: Docker container on port 3000
- **DynamoDB**: Running on port 8001

## Project Structure

```
bb_draft/
├── lib/                      # Flutter source code
│   ├── config/               # Configuration (api_config, app_config, routes)
│   ├── providers/            # State management (auth_provider, status_provider)
│   ├── screens/              # UI screens (auth/, home/)
│   ├── services/             # API services
│   ├── widgets/              # Reusable widgets
│   └── main.dart             # App entry point
├── bb-draft-backend/         # Node.js backend
│   ├── src/
│   │   ├── config/           # Firebase, database config
│   │   ├── middleware/       # Auth middleware
│   │   ├── models/           # DynamoDB models
│   │   ├── routes/           # API routes (health, users)
│   │   └── index.ts          # Server entry point
│   ├── docker-compose.prod.yml
│   └── Dockerfile
├── docs/plans/               # Implementation plans
├── .github/workflows/        # GitHub Actions (deploy.yml)
└── web/                      # Flutter web assets
```

## Key Configuration Files

| File | Purpose |
|------|---------|
| `lib/config/api_config.dart` | API base URL configuration |
| `lib/config/app_config.dart` | App settings (e.g., showDevStatusIndicators) |
| `bb-draft-backend/docker-compose.prod.yml` | Production Docker config |
| `.github/workflows/deploy.yml` | Auto-deploy on push to main |

## Deployment

Deployment is automated via GitHub Actions:
1. Push to `main` branch triggers deploy
2. Flutter web app builds and copies to `/var/www/html/bb-draft/`
3. Backend copies to `~/bb-draft-backend/` and rebuilds Docker container
4. nginx proxies `/bb-draft-api/` to backend on port 3000

## Development

### Flutter Docker Development Container

A pre-built Docker container is available for Flutter development:

- **Image**: `ghcr.io/zycroft/bb-draft-dev:latest`
- **Container name**: `bb_draft_dev`
- **Base**: Ubuntu 22.04 with Flutter 3.38.5 and Chrome

#### Start the container
```bash
docker compose up -d
docker exec -it bb_draft_dev bash
```

#### Run Flutter app inside container
```bash
# Inside the container
cd /workspace
flutter pub get
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

#### Container ports
- `8080` - Flutter web dev server
- `5001` - Alternative port

#### Volume mounts
- Project directory → `/workspace`
- Pub cache persisted between sessions

### Run Flutter locally (without Docker)
```bash
flutter run -d chrome --web-port 8080
```

### Run backend locally
```bash
cd bb-draft-backend
npm run dev
```

### Local URLs
- Frontend: http://localhost:8080
- Backend: http://localhost:3000

## Current State

The app is currently minimal with:
- Firebase Authentication (Google Sign-In)
- User profile display on home screen
- Dev status indicators showing backend/database connectivity

## DynamoDB Tables
- `bb_draft_users` - User profiles
