# BB Draft

A Flutter application for baseball draft management.

## Getting Started

### Option 1: Docker Development Environment (Recommended)

This project includes a Docker setup for consistent development across teams.

**Prerequisites:**
- Docker and Docker Compose installed

**Quick Start:**

```bash
# Build the development container
docker compose build

# Start the container
docker compose up -d

# Enter the container
docker compose exec flutter-dev bash

# Inside the container, get dependencies and run
flutter pub get
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```

Access the app at `http://localhost:8080`

**Useful Commands (inside container):**

```bash
# Run tests
flutter test

# Build for web
flutter build web --release

# Check Flutter setup
flutter doctor
```

### Option 2: Local Flutter Installation

**Prerequisites:**
- Flutter SDK 3.38.5 or later
- Dart SDK ^3.10.4

```bash
flutter pub get
flutter run -d chrome
```

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
