## AI Coding Agent Execution Plan: Development Status Indicators

> **Purpose:** Implement visual status indicators showing connectivity to the Node.js backend and DynamoDB database at zycroft.duckdns.org.

---

### 0) Metadata

| Field | Value |
|-------|-------|
| **Project / Repo** | bb_draft |
| **Task Title** | Development Status Indicators |
| **Owner / Requester** | zycroft |
| **Target Branch** | main |
| **Priority** | P2 (Medium) |
| **Estimated Complexity** | Small (1-3 files backend, 4-6 files Flutter) |
| **Related tickets / docs** | `user.plan.md` |

---

### 1) Agent Configuration

**Role:** Expert software developer + code reviewer + test engineer.

**Operating Rules:**

1. Prefer simple, maintainable solutions over cleverness.
2. Follow existing repo patterns (structure, naming, linting, formatting).
3. Avoid breaking changes unless explicitly approved.
4. Make the smallest safe assumption when uncertain; document assumptions.
5. Every change must include: implementation, validation, and tests.

**Execution Mode:**

- [x] **Autonomous** — Execute all steps without user confirmation
- [ ] **Supervised** — Pause for user approval at each major step
- [ ] **Review-only** — Analyze and propose changes, do not modify files

**Stop Conditions (halt and ask user if any occur):**

- Changes to authentication or security middleware
- Changes that would expose sensitive database information
- Backend endpoint changes that could affect production stability

---

### 2) Objective

**Goal:**
> When this task is complete, the application will display two status icons at the bottom of the web page indicating real-time connectivity status to the Node.js backend and DynamoDB database at zycroft.duckdns.org.

**Success Criteria:**

- [ ] SC1: A status bar appears at the bottom of all screens showing two icons
- [ ] SC2: Backend icon shows green when `/health` endpoint returns 200, red otherwise
- [ ] SC3: DynamoDB icon shows green when `/health/db` endpoint returns 200, red otherwise
- [ ] SC4: Status updates automatically every 30 seconds
- [ ] SC5: Icons show loading state on initial check and during refresh
- [ ] SC6: Status indicators can be enabled/disabled via configuration file setting

**Non-goals / Out of Scope:**

- Detailed error messages or diagnostics
- Historical connectivity data or logging
- Alerts or notifications for status changes
- Status persistence across sessions

**User-Facing Impact:**

- [x] UI changes: New status bar at bottom of screen with two connectivity icons
- [x] API changes: New `/health/db` endpoint on backend
- [ ] Behavior changes: None to existing functionality

---

### 3) Context & Constraints

#### Codebase Context

| Aspect | Details |
|--------|---------|
| **Primary files to modify (Backend)** | `bb-draft-backend/src/index.ts`, `bb-draft-backend/src/routes/health.ts` (new) |
| **Primary files to modify (Flutter)** | `lib/main.dart`, `lib/widgets/status_bar.dart` (new), `lib/services/status_service.dart` (new) |
| **Files to read (context only)** | `lib/screens/home/home_screen.dart` |
| **Test files** | `test/widgets/status_bar_test.dart` (new) |
| **Config files** | `lib/config/api_config.dart` (recreate), `lib/config/app_config.dart` (new) |

#### Existing Patterns to Follow

```
Backend patterns:
- Express routes export default router
- Health endpoint returns { status: 'ok', timestamp: ISO string }
- Use try/catch for database operations

Flutter patterns:
- Widgets in lib/widgets/ directory
- Services in lib/services/ directory
- Use Provider for state management
- StatefulWidget for components with timers
```

#### Constraints

| Constraint Type | Requirement |
|----------------|-------------|
| **Backward compatibility** | Required - no changes to existing functionality |
| **Performance** | Status checks should not block UI, use async |
| **Security** | Health endpoints should not expose sensitive data |
| **Dependencies** | Use existing http package, no new dependencies |

---

### 4) Requirements

#### Functional Requirements

| ID | Requirement | Priority | Verification Method |
|----|-------------|----------|---------------------|
| R1 | Backend provides `/health` endpoint returning server status | Must | curl test |
| R2 | Backend provides `/health/db` endpoint returning DynamoDB connectivity | Must | curl test |
| R3 | Flutter displays status bar at bottom of screen | Must | Visual inspection |
| R4 | Status bar shows two distinct icons (Backend, Database) | Must | Visual inspection |
| R5 | Icons change color based on connectivity (green=connected, red=disconnected, grey=checking) | Must | Visual inspection |
| R6 | Status auto-refreshes every 30 seconds | Must | Timer verification |
| R7 | Status bar is visible on all screens after login | Should | Navigation test |
| R8 | Tapping an icon shows tooltip with status details | Should | Interaction test |
| R9 | Configuration file setting to enable/disable status indicators | Should | Config check |

#### Non-Functional Requirements

| ID | Requirement | Target | Verification |
|----|-------------|--------|--------------|
| NFR1 | Health check response time | < 500ms | Manual timing |
| NFR2 | Status check should not block UI | Async operation | Code review |
| NFR3 | Graceful handling of network errors | No crashes | Error injection test |

#### Acceptance Criteria

```gherkin
AC1: Backend Health Check
  Given the backend server is running at zycroft.duckdns.org
  When a GET request is made to /bb-draft-api/health
  Then the response status is 200
  And the body contains { "status": "ok" }

AC2: Database Health Check
  Given the backend server is running and connected to DynamoDB
  When a GET request is made to /bb-draft-api/health/db
  Then the response status is 200
  And the body contains { "status": "ok", "database": "connected" }

AC3: Database Disconnected
  Given the backend server is running but DynamoDB is unreachable
  When a GET request is made to /bb-draft-api/health/db
  Then the response status is 503
  And the body contains { "status": "error", "database": "disconnected" }

AC4: Status Bar Display
  Given the user is logged into the application
  When any screen is displayed
  Then a status bar appears at the bottom of the screen
  And two icons are visible (server icon, database icon)

AC5: Connected Status
  Given the backend and database are both reachable
  When the status check completes
  Then both icons display in green color

AC6: Disconnected Status
  Given the backend is unreachable
  When the status check fails
  Then the backend icon displays in red color
  And the database icon displays in grey (unknown) color

AC7: Auto-Refresh
  Given the user is on any screen
  When 30 seconds have elapsed since the last check
  Then a new status check is initiated automatically

AC8: Configuration Toggle - Disabled
  Given showDevStatusIndicators is set to false in app_config.dart
  When the application loads
  Then the status bar is not displayed
  And no health check requests are made

AC9: Configuration Toggle - Enabled
  Given showDevStatusIndicators is set to true in app_config.dart
  When the application loads
  Then the status bar is displayed at the bottom of the screen
  And health check requests are made every 30 seconds
```

---

### 5) Technical Design

#### Architecture Decision

**Approach:** Create a dedicated status service that periodically checks backend health endpoints, with a persistent status bar widget displayed via a Stack overlay in the app.

**Alternatives Considered:**

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Scaffold bottomNavigationBar | Simple, built-in | May conflict with future nav bar | Rejected |
| Stack overlay in MaterialApp | Persistent across all routes | More complex setup | Chosen |
| Individual screen integration | Full control per screen | Repetitive, hard to maintain | Rejected |

**Rationale:** Using a Stack overlay in the main MaterialApp builder ensures the status bar persists across all navigation without modifying each screen. This is cleaner and more maintainable.

#### Data / API Changes

**New Endpoints:**

```
GET /health
  Request:  (none)
  Response: { "status": "ok", "timestamp": "2024-01-09T12:00:00Z" }
  Errors:   500 (server error)

GET /health/db
  Request:  (none)
  Response: { "status": "ok", "database": "connected", "timestamp": "2024-01-09T12:00:00Z" }
  Errors:   503 (database unavailable)
```

**Schema Changes:**

```
No schema changes required
```

**Migration Strategy:**

- [x] No migration needed

#### Component Design

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Current Screen                         │   │
│  │                   (Home, etc.)                           │   │
│  │                                                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Status Bar                            │   │
│  │  ┌──────────────┐              ┌──────────────┐         │   │
│  │  │ 🟢 Backend   │              │ 🟢 Database  │         │   │
│  │  └──────────────┘              └──────────────┘         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

#### Status Service Flow

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│StatusProvider│────▶│ HTTP GET /health │────▶│ Backend Server  │
│   (Timer)   │     └──────────────────┘     └─────────────────┘
│             │                                      │
│             │     ┌──────────────────┐            │
│             │────▶│ HTTP GET         │            ▼
│             │     │ /health/db       │     ┌─────────────────┐
│             │     └──────────────────┘     │   DynamoDB      │
└─────────────┘                              └─────────────────┘
       │
       ▼
┌─────────────────┐
│  StatusProvider │ ◀── ChangeNotifier
│  - backendStatus│
│  - dbStatus     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   StatusBar     │
│    Widget       │
└─────────────────┘
```

#### Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Status checks slow down app | Low | Medium | Use async, don't await in UI thread |
| Backend unreachable on startup | Medium | Low | Show "checking" state, retry logic |
| Too many requests to backend | Low | Low | 30-second interval, debounce |
| CORS issues with health endpoints | Medium | High | Ensure CORS configured for health routes |

---

### 6) Implementation Steps

> **Agent Instructions:** Execute steps in order. Each step should be atomic and independently verifiable.

#### Phase 1: Backend Health Endpoints

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 1.1 | Create health routes file with `/health` and `/health/db` endpoints | `bb-draft-backend/src/routes/health.ts` | File exists |
| 1.2 | Add DynamoDB connectivity check function | `bb-draft-backend/src/routes/health.ts` | Function exists |
| 1.3 | Register health routes in main index (move existing /health to router) | `bb-draft-backend/src/index.ts` | Routes imported and used |
| 1.4 | Deploy and test endpoints with curl | — | Both endpoints return expected responses |

**Checkpoint 1:** `curl https://zycroft.duckdns.org/bb-draft-api/health` returns `{"status":"ok"}` and `curl https://zycroft.duckdns.org/bb-draft-api/health/db` returns database status

#### Phase 2: Flutter Configuration

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 2.1 | Recreate API config with base URL pointing to zycroft.duckdns.org | `lib/config/api_config.dart` | File exists with baseUrl |
| 2.2 | Create app configuration file with showDevStatusIndicators setting | `lib/config/app_config.dart` | File exists with boolean setting |
| 2.3 | Create API service for HTTP calls with timeout handling | `lib/services/api_service.dart` | File exists |

**Checkpoint 2:** API service can be instantiated, app_config.dart has showDevStatusIndicators = true (default)

#### Phase 3: Flutter Status Provider

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 3.1 | Create ConnectionStatus enum (connected, disconnected, checking) | `lib/providers/status_provider.dart` | Enum defined |
| 3.2 | Create StatusProvider extending ChangeNotifier | `lib/providers/status_provider.dart` | Class with backendStatus and dbStatus |
| 3.3 | Implement checkBackendStatus method | `lib/providers/status_provider.dart` | Method calls /health endpoint |
| 3.4 | Implement checkDbStatus method | `lib/providers/status_provider.dart` | Method calls /health/db endpoint |
| 3.5 | Implement checkAllStatus method calling both | `lib/providers/status_provider.dart` | Method updates both statuses |
| 3.6 | Add 30-second Timer for auto-refresh | `lib/providers/status_provider.dart` | Timer created in constructor |
| 3.7 | Cancel timer in dispose method | `lib/providers/status_provider.dart` | Timer cancelled |

**Checkpoint 3:** StatusProvider can be instantiated and checkAllStatus updates state

#### Phase 4: Flutter Status Bar Widget

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 4.1 | Create StatusIndicator widget showing icon with color | `lib/widgets/status_indicator.dart` | Widget renders icon |
| 4.2 | Add color logic based on ConnectionStatus | `lib/widgets/status_indicator.dart` | Green/red/grey colors |
| 4.3 | Add Tooltip wrapper for status details | `lib/widgets/status_indicator.dart` | Tooltip on long press |
| 4.4 | Create StatusBar widget with Row of two StatusIndicators | `lib/widgets/status_bar.dart` | Widget shows both icons |
| 4.5 | Style StatusBar with dark background and padding | `lib/widgets/status_bar.dart` | Styled container |

**Checkpoint 4:** StatusBar widget renders correctly with mock data

#### Phase 5: Integration

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 5.1 | Add StatusProvider to MultiProvider in main.dart (only if config enabled) | `lib/main.dart` | Provider registered conditionally |
| 5.2 | Create wrapper widget that shows StatusBar only when authenticated AND config enabled | `lib/main.dart` | StatusBar conditional |
| 5.3 | Use Stack in MaterialApp builder to overlay StatusBar | `lib/main.dart` | StatusBar at bottom |
| 5.4 | Position StatusBar at bottom of screen | `lib/main.dart` | Positioned widget |
| 5.5 | Add check for AppConfig.showDevStatusIndicators before rendering StatusBar | `lib/main.dart` | Status bar respects config |

**Checkpoint 5:** App shows status bar on home screen with live status from zycroft.duckdns.org when showDevStatusIndicators is true; status bar hidden when false

#### Phase 6: Implement Test Specification

> **Agent Instructions:** Implement ALL tests defined in Section 8 (Test Specification). Tests are required, not optional. Do not skip this phase.

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 6.1 | Create test directory structure | `test/widgets/` | Directory exists |
| 6.2 | Implement StatusIndicator tests from Test Matrix | `test/widgets/status_indicator_test.dart` | All scenarios covered |
| 6.3 | Implement StatusBar tests from Test Matrix | `test/widgets/status_bar_test.dart` | All scenarios covered |
| 6.4 | Run all tests and verify pass | — | `flutter test` exits 0 |
| 6.5 | Verify coverage meets requirements (70%+ for widgets) | — | Coverage >= target |

**Checkpoint 6:** All tests from Test Specification implemented and passing

#### Phase 7: Validation & Cleanup

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 7.1 | Run flutter analyze | — | No errors |
| 7.2 | Run backend build | — | No errors |
| 7.3 | Test with backend running at zycroft.duckdns.org | — | Both icons green |
| 7.4 | Test with incorrect URL | — | Both icons red |
| 7.5 | Verify auto-refresh works | — | Icons update after 30 seconds |

#### Phase 8: Final Validation

> **Agent Instructions:** Execute the complete Validation Protocol (Section 7) before marking the task complete. All checks must pass.

| Step | Action | Verification |
|------|--------|--------------|
| 8.1 | Execute Build & Lint commands from Section 7 | All commands exit 0 |
| 8.2 | Execute Test Execution commands from Section 7 | All tests pass |
| 8.3 | Complete Smoke Test Checklist from Section 7 | All checks pass |
| 8.4 | Capture Evidence listed in Section 7 | Evidence documented |
| 8.5 | Verify all Success Criteria (Section 2) are met | All SC items checked |
| 8.6 | Verify all Acceptance Criteria (Section 4) pass | All AC scenarios pass |

**Checkpoint 8:** Feature complete, all tests pass, all validations pass

#### Decision Points

| Situation | Action |
|-----------|--------|
| CORS error on health endpoints | Add health routes with CORS headers |
| Timer doesn't stop on dispose | Verify timer.cancel() called |
| Status bar overlaps content | Add bottom padding to screens or adjust positioning |
| Network timeout too long | Set 5-second timeout on HTTP requests |

---

### 7) Validation Protocol

#### Build & Lint

```bash
# Backend
cd bb-draft-backend
npm run build        # Expected: Exit 0, no errors

# Frontend
cd ..
flutter analyze      # Expected: No issues found
```

#### Test Execution

```bash
# Backend health check
curl -s https://zycroft.duckdns.org/bb-draft-api/health
# Expected: {"status":"ok","timestamp":"..."}

curl -s https://zycroft.duckdns.org/bb-draft-api/health/db
# Expected: {"status":"ok","database":"connected","timestamp":"..."}

# Flutter
flutter test         # Expected: All pass
```

#### Smoke Test Checklist

| Test | Command / Action | Expected Result |
|------|------------------|-----------------|
| Backend health | `curl .../health` | `{"status":"ok"}` |
| DB health | `curl .../health/db` | `{"status":"ok","database":"connected"}` |
| Status bar visible | Load app after login | Two icons at bottom |
| Icons green | Both services running | Green icons |
| Auto-refresh | Wait 30 seconds | Icons refresh |

#### Evidence to Capture

- [ ] Screenshot of status bar with both icons green
- [ ] Screenshot of status bar with backend icon red (wrong URL test)
- [ ] curl output from both health endpoints
- [ ] Flutter analyze output showing no issues

---

### 8) Test Specification

#### Test Matrix

| Scenario | Input | Expected Output | Test Type |
|----------|-------|-----------------|-----------|
| Backend healthy | GET /health | 200, status: ok | Integration |
| DB healthy | GET /health/db | 200, database: connected | Integration |
| DB unreachable | DynamoDB down | 503, database: disconnected | Integration |
| Status bar renders | Widget test | Two icons visible | Unit |
| Connected shows green | status = connected | Green icon | Unit |
| Disconnected shows red | status = disconnected | Red icon | Unit |
| Checking shows grey | status = checking | Grey icon | Unit |
| Config enabled | showDevStatusIndicators = true | Status bar visible | Unit |
| Config disabled | showDevStatusIndicators = false | Status bar hidden | Unit |

#### Test Code Template

```dart
// Widget test template
import 'package:flutter_test/flutter_test.dart';
import 'package:bb_draft/widgets/status_bar.dart';
import 'package:bb_draft/widgets/status_indicator.dart';

void main() {
  testWidgets('StatusBar displays two indicators', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusBar(),
        ),
      ),
    );

    expect(find.byType(StatusIndicator), findsNWidgets(2));
  });
}
```

#### Coverage Requirements

| Area | Minimum Coverage |
|------|------------------|
| StatusProvider | 80% |
| StatusBar widget | 70% |
| StatusIndicator widget | 70% |

---

### 9) Rollout Plan

#### Deployment Checklist

- [ ] Backend health routes tested locally
- [ ] Backend deployed to zycroft.duckdns.org
- [ ] Health endpoints accessible via curl
- [ ] Flutter app builds successfully
- [ ] Status bar visible in running app
- [ ] Auto-refresh working

#### Rollback Plan

```bash
# If issues detected:
git revert <commit-sha>
# Redeploy backend without health/db route if causing issues
```

#### Post-Deployment Verification

| Check | Command / Method | Expected |
|-------|------------------|----------|
| Health endpoint | curl /health | 200 OK |
| DB health endpoint | curl /health/db | 200 OK |
| Status bar visible | Run app | Icons at bottom |
| No console errors | Browser dev tools | Clean console |

---

### 10) Agent Output Requirements

#### Required Outputs

1. **Change Summary**
   ```
   ## Summary
   Added development status indicators showing backend and database connectivity.

   ## Files Changed
   - `bb-draft-backend/src/routes/health.ts` — New health routes
   - `bb-draft-backend/src/index.ts` — Register health routes
   - `lib/config/api_config.dart` — Recreated with base URL
   - `lib/services/api_service.dart` — HTTP service
   - `lib/providers/status_provider.dart` — Status management
   - `lib/widgets/status_indicator.dart` — Single status icon
   - `lib/widgets/status_bar.dart` — Status bar with two icons
   - `lib/main.dart` — Integration with overlay
   ```

2. **Commands Executed** - Build and test commands with results

3. **Validation Evidence** - curl outputs, screenshots

4. **Status Report** - Checklist of requirements completed

5. **Follow-up Items** - Any deferred work

---

### 11) Quick Reference

#### Common Commands

| Action | Command |
|--------|---------|
| Backend build | `cd bb-draft-backend && npm run build` |
| Backend dev | `cd bb-draft-backend && npm run dev` |
| Flutter analyze | `flutter analyze` |
| Flutter run | `flutter run -d chrome --web-port 8080` |
| Test health | `curl https://zycroft.duckdns.org/bb-draft-api/health` |
| Test DB health | `curl https://zycroft.duckdns.org/bb-draft-api/health/db` |

#### File Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Flutter widget | `snake_case.dart` | `status_bar.dart` |
| Flutter provider | `snake_case.dart` | `status_provider.dart` |
| Backend route | `camelCase.ts` | `health.ts` |

#### Icon Design

| Status | Color | Icon | Hex |
|--------|-------|------|-----|
| Connected | Green | `Icons.cloud_done` / `Icons.storage` | `#4CAF50` |
| Disconnected | Red | `Icons.cloud_off` / `Icons.storage` | `#F44336` |
| Checking | Grey | `Icons.cloud_queue` / `Icons.storage` | `#9E9E9E` |

#### API Endpoints

| Environment | Base URL |
|-------------|----------|
| Production | `https://zycroft.duckdns.org/bb-draft-api` |
| Development | `http://localhost:3000` |

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Backend server status |
| `/health/db` | GET | DynamoDB connectivity status |

#### Configuration File

**File:** `lib/config/app_config.dart`

```dart
/// Application configuration settings
class AppConfig {
  /// Enable/disable development status indicators at bottom of screen
  /// Set to true to show backend and database connectivity status
  /// Set to false to hide the status bar (recommended for production)
  static const bool showDevStatusIndicators = true;

  /// Status check interval in seconds
  static const int statusCheckIntervalSeconds = 30;
}
```

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `showDevStatusIndicators` | bool | `true` | Show/hide the status bar with connectivity indicators |
| `statusCheckIntervalSeconds` | int | `30` | Interval between automatic status checks |

**Usage in code:**
```dart
import 'package:bb_draft/config/app_config.dart';

// Check if status indicators should be shown
if (AppConfig.showDevStatusIndicators) {
  // Render StatusBar
}
```
