# BB Draft Docker Setup

## Quick Start

```bash
git clone git@github.com:Zycroft/bb-draft.git
cd bb-draft
docker compose pull
docker compose up -d
```

## Prerequisites

1. Docker and Docker Compose installed
2. Access to the private container registry (one-time setup):

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
# Enter your GitHub PAT with read:packages scope
```

## Running the Development Server

```bash
# Enter the container
docker compose exec flutter-dev bash

# Get dependencies and start dev server
flutter pub get
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```

Access the app at http://localhost:8080

## Useful Commands

```bash
# Stop the container
docker compose down

# View container logs
docker compose logs -f

# Rebuild from Dockerfile (if needed)
docker compose build

# Run tests
docker compose exec flutter-dev flutter test

# Build for production
docker compose exec flutter-dev flutter build web --release
```
