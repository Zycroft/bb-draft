
## AI Coding Agent Execution Plan Template

> **Purpose:** This template structures tasks for autonomous AI agent execution. Write plans as explicit, unambiguous instructions that require no human clarification during execution.

---

### 0) Metadata

| Field | Value |
|-------|-------|
| **Project / Repo** | bb_draft |
| **Task Title** | Auto-Incrementing Version Number System |
| **Owner / Requester** | User |
| **Target Branch** | main |
| **Priority** | P2 (Medium) |
| **Estimated Complexity** | Medium (4-10 files) |
| **Related tickets / docs** | CLAUDE.md, deploy.yml |

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

- Ambiguous requirement with multiple valid interpretations
- Change would affect >20 files (unless pre-approved)
- Security-sensitive code (auth, crypto, PII handling)
- Breaking change to public API/interface
- Test failures that cannot be resolved
- Missing dependency or access permissions

---

### 2) Objective

**Goal (complete this sentence):**
> When this task is complete, the system will be able to: display an auto-incrementing version number in the format `X.X.X-yyyymmdd-####` in the bottom right corner of the status bar, where the version auto-increments on each deployment to production.

**Success Criteria (must be verifiable by agent):**

- [ ] SC1: Version number displays in bottom right corner of status bar
- [ ] SC2: Version format follows `X.X.X-yyyymmdd-####` pattern
- [ ] SC3: Major.Minor.Patch (X.X.X) is configurable in app_config.dart (default 0.0.0)
- [ ] SC4: Date portion (yyyymmdd) reflects deployment date in PST timezone
- [ ] SC5: Daily counter (####) auto-increments and resets at midnight PST
- [ ] SC6: Backend API endpoint returns next version number on deployment
- [ ] SC7: GitHub Actions workflow generates and embeds version on deploy

**Non-goals / Out of Scope:**

- Manual version bumping UI
- Version history tracking/changelog
- Rollback version handling
- Version comparison logic

**User-Facing Impact:**

- [ ] No user-facing changes
- [x] UI changes: Version number displayed in bottom right of status bar
- [x] API changes: New `/version/next` endpoint for deployment automation
- [ ] Behavior changes:

---

### 3) Context & Constraints

#### Codebase Context

| Aspect | Details |
|--------|---------|
| **Primary files to modify** | `lib/config/app_config.dart`, `lib/widgets/status_bar.dart`, `bb-draft-backend/src/routes/version.ts`, `.github/workflows/deploy.yml` |
| **Files to read (context only)** | `lib/widgets/status_indicator.dart`, `bb-draft-backend/src/index.ts` |
| **Test files** | `test/widgets/status_bar_test.dart`, `bb-draft-backend/src/routes/version.test.ts` |
| **Config files** | `lib/config/app_config.dart`, `bb-draft-backend/src/config/database.ts` |

#### Existing Patterns to Follow

```
Example pattern from codebase:
- Flutter widgets use StatelessWidget with const constructors
- Provider pattern for state management
- Backend routes exported from src/routes/ directory
- DynamoDB models in src/models/ directory
- Status bar uses Row with MainAxisAlignment.center for indicators
```

#### Constraints

| Constraint Type | Requirement |
|----------------|-------------|
| **Backward compatibility** | Required - existing status bar must continue to work |
| **Performance** | Version fetch should not block app startup |
| **Security** | Version increment endpoint should be protected (GitHub Actions only) |
| **Dependencies** | No new Flutter packages; backend uses existing DynamoDB |

---

### 4) Requirements

#### Functional Requirements

| ID | Requirement | Priority | Verification Method |
|----|-------------|----------|---------------------|
| R1 | Store version counter in DynamoDB with date-based key | Must | Integration test |
| R2 | Reset counter to 0001 at midnight PST each day | Must | Unit test |
| R3 | Backend endpoint `/version/next` returns and increments version | Must | API test |
| R4 | Backend endpoint `/version/current` returns current version without incrementing | Must | API test |
| R5 | Flutter app displays version in status bar bottom right | Must | Widget test |
| R6 | Version embedded at build time via --dart-define | Must | Build verification |
| R7 | Major.Minor.Patch configurable in app_config.dart | Must | Code inspection |

#### Non-Functional Requirements

| ID | Requirement | Target | Verification |
|----|-------------|--------|--------------|
| NFR1 | Version endpoint response time | <100ms | Load test |
| NFR2 | Version display should not shift layout | No jitter | Visual inspection |

#### Acceptance Criteria

```gherkin
AC1: Version display on status bar
  Given the app is loaded
  When the user views the status bar
  Then the version number appears in the bottom right corner
  And the format matches X.X.X-yyyymmdd-####

AC2: Version auto-increment on deploy
  Given it is January 9, 2026 PST
  And the current version counter for today is 0003
  When a deployment is triggered
  Then the new version is 0.0.0-20260109-0004

AC3: Daily counter reset
  Given the previous deployment was 2026-01-08 with counter 0015
  When a deployment occurs on 2026-01-09
  Then the new version counter starts at 0001
  And the version is 0.0.0-20260109-0001

AC4: Current version endpoint
  Given the current version is 0.0.0-20260109-0003
  When GET /version/current is called
  Then it returns {"version": "0.0.0-20260109-0003"}
  And the counter is NOT incremented

AC5: Next version endpoint
  Given the current version is 0.0.0-20260109-0003
  When POST /version/next is called
  Then it returns {"version": "0.0.0-20260109-0004"}
  And the counter IS incremented to 4
```

---

### 5) Technical Design

#### Architecture Decision

**Approach:** Store version state in DynamoDB with a single record per day. The backend provides endpoints to get current version and increment to next version. GitHub Actions calls the increment endpoint during deploy and passes the version to Flutter build via `--dart-define`.

**Alternatives Considered:**

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Store counter in DynamoDB | Persistent, survives restarts | Requires DB call | Chosen |
| Store counter in file on server | Simple, no DB | Lost on container rebuild | Rejected |
| Git tag-based versioning | Native to Git | Doesn't support daily counter format | Rejected |
| Store in environment variable | Fast | Lost on restart, no persistence | Rejected |

**Rationale:** DynamoDB is already in use for the project and provides reliable persistence. A single table with date as partition key is simple and efficient.

#### Data / API Changes

**New Endpoints:**

```
GET /version/current
  Request:  (none)
  Response: { "version": "0.0.0-20260109-0003", "date": "20260109", "counter": 3 }
  Errors:   500 (server error)

POST /version/next
  Request:  { "majorMinorPatch": "0.0.0" } (optional, defaults to "0.0.0")
  Response: { "version": "0.0.0-20260109-0004", "date": "20260109", "counter": 4 }
  Errors:   500 (server error)
```

**Schema Changes:**

```
Table: bb_draft_versions (NEW)
  + date: String (partition key) - format "yyyymmdd"
  + counter: Number - current counter for that day (1-9999)
  + lastUpdated: String - ISO timestamp of last increment
```

**Migration Strategy:**

- [x] No migration needed (new table)
- [ ] Forward-only migration
- [ ] Reversible migration with rollback script

#### Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Race condition on concurrent deploys | Low | Med | Use DynamoDB atomic counter update |
| Version endpoint called outside deploy | Med | Low | Log warnings, version still works |
| Timezone calculation error | Low | Med | Use established library (date-fns-tz) |

---

### 6) Implementation Steps

> **Agent Instructions:** Execute steps in order. Each step should be atomic and independently verifiable. Mark steps complete as you go.

#### Phase 1: Backend - DynamoDB Setup

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 1.1 | Create DynamoDB table `bb_draft_versions` with `date` as partition key (String) | DynamoDB console/script | Table exists with correct schema |
| 1.2 | Create version model with TypeScript types | `bb-draft-backend/src/models/Version.ts` | File compiles |
| 1.3 | Add helper function to get current PST date as `yyyymmdd` | `bb-draft-backend/src/utils/dateUtils.ts` | Unit test passes |

**Checkpoint 1:** DynamoDB table exists, model and date utility are ready

#### Phase 2: Backend - Version API

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 2.1 | Create version routes file with GET `/current` endpoint | `bb-draft-backend/src/routes/version.ts` | Endpoint returns mock data |
| 2.2 | Implement GET `/current` to fetch from DynamoDB | `bb-draft-backend/src/routes/version.ts` | Returns actual data |
| 2.3 | Implement POST `/next` with atomic counter increment | `bb-draft-backend/src/routes/version.ts` | Counter increments correctly |
| 2.4 | Add version routes to Express app | `bb-draft-backend/src/index.ts` | Routes accessible at /version/* |
| 2.5 | Handle day rollover logic (reset counter if new day) | `bb-draft-backend/src/routes/version.ts` | New day starts at 0001 |

**Checkpoint 2:** Both API endpoints work correctly, counter increments and resets

#### Phase 3: Flutter - Version Display

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 3.1 | Add `appVersion` constant to AppConfig with default and dart-define override | `lib/config/app_config.dart` | Compiles with and without --dart-define |
| 3.2 | Add `majorMinorPatch` constant to AppConfig (default "0.0.0") | `lib/config/app_config.dart` | Value accessible |
| 3.3 | Modify StatusBar to display version in bottom right using Expanded and Align | `lib/widgets/status_bar.dart` | Version visible in corner |
| 3.4 | Style version text to match status bar theme (small, muted) | `lib/widgets/status_bar.dart` | Visually consistent |

**Checkpoint 3:** Version displays correctly in status bar

#### Phase 4: GitHub Actions - Deploy Integration

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 4.1 | Add step to call POST `/version/next` and capture version | `.github/workflows/deploy.yml` | Version retrieved |
| 4.2 | Pass version to Flutter build via `--dart-define=APP_VERSION=...` | `.github/workflows/deploy.yml` | Build succeeds |
| 4.3 | Add version to deployment log output | `.github/workflows/deploy.yml` | Version visible in logs |

**Checkpoint 4:** Deployment generates and embeds version correctly

#### Phase 5: Implement Test Specification

> **Agent Instructions:** Implement ALL tests defined in Section 8 (Test Specification). Tests are required, not optional. Do not skip this phase.

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 5.1 | Create Flutter widget test for version display in status bar | `test/widgets/status_bar_test.dart` | Tests pass |
| 5.2 | Create backend unit tests for date utility functions | `bb-draft-backend/src/utils/dateUtils.test.ts` | Tests pass |
| 5.3 | Create backend integration tests for version endpoints | `bb-draft-backend/src/routes/version.test.ts` | Tests pass |
| 5.4 | Run all tests and verify pass | — | All tests pass |

**Checkpoint 5:** All tests from Test Specification implemented and passing

#### Phase 6: Validation & Cleanup

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 6.1 | Run Flutter analyze | — | No errors |
| 6.2 | Run backend linter/typecheck | — | No errors |
| 6.3 | Test locally with mock version | — | Version displays |
| 6.4 | Verify status bar layout unchanged (indicators still centered) | — | Visual check |

#### Phase 7: Final Validation

> **Agent Instructions:** Execute the complete Validation Protocol (Section 7) before marking the task complete. All checks must pass.

| Step | Action | Verification |
|------|--------|--------------|
| 7.1 | Execute Build & Lint commands from Section 7 | All commands exit 0 |
| 7.2 | Execute Test Execution commands from Section 7 | All tests pass |
| 7.3 | Complete Smoke Test Checklist from Section 7 | All checks pass |
| 7.4 | Capture Evidence listed in Section 7 | Evidence documented |
| 7.5 | Verify all Success Criteria (Section 2) are met | All SC items checked |
| 7.6 | Verify all Acceptance Criteria (Section 4) pass | All AC scenarios pass |

**Checkpoint 7:** Feature complete, all tests pass, all validations pass

#### Decision Points

> **Agent Instructions:** If you encounter these situations, follow the specified action.

| Situation | Action |
|-----------|--------|
| DynamoDB table doesn't exist | Create it using MCP tools or AWS CLI |
| date-fns-tz not installed | Install it: `npm install date-fns-tz` |
| Counter exceeds 9999 | Log warning, continue incrementing (unlikely scenario) |
| Version endpoint fails during deploy | Use fallback version "0.0.0-unknown-0000" |

---

### 7) Validation Protocol

> **Agent Instructions:** Execute these validations after implementation. All must pass before marking complete.

#### Build & Lint

```bash
# Flutter
cd /path/to/bb_draft
flutter analyze              # Expected: No issues found
flutter build web --release  # Expected: Exit 0

# Backend
cd bb-draft-backend
npm run build               # Expected: Exit 0, no errors
npm run lint                # Expected: Exit 0, no warnings (if lint script exists)
```

#### Test Execution

```bash
# Flutter tests
flutter test                 # Expected: All pass

# Backend tests
cd bb-draft-backend
npm run test                 # Expected: All pass
```

#### Smoke Test Checklist

| Test | Command / Action | Expected Result |
|------|------------------|-----------------|
| Version API health | `curl localhost:3000/version/current` | `{"version":"...","date":"...","counter":...}` |
| Version increment | `curl -X POST localhost:3000/version/next` | Counter increments |
| Flutter displays version | Run app, check status bar | Version in bottom right |
| Status indicators still work | Check backend/DB indicators | Green when connected |

#### Evidence to Capture

- [ ] Test output showing all tests pass
- [ ] Screenshot of status bar with version displayed
- [ ] API response from /version/current
- [ ] API response from /version/next showing increment
- [ ] Flutter analyze output

---

### 8) Test Specification

#### Test Matrix

| Scenario | Input | Expected Output | Test Type |
|----------|-------|-----------------|-----------|
| Get current version (none exists) | GET /version/current | Counter 1, today's date | Integration |
| Get current version (exists) | GET /version/current | Current counter, today's date | Integration |
| Increment version | POST /version/next | Counter + 1 | Integration |
| Day rollover | POST /version/next on new day | Counter resets to 1 | Unit |
| PST date calculation | Various UTC times | Correct PST date | Unit |
| Version format | Counter 42, date 20260109 | "0.0.0-20260109-0042" | Unit |
| Counter padding | Counter 1 | "0001" (4 digits) | Unit |
| StatusBar displays version | Render widget | Version text visible | Widget |
| StatusBar layout preserved | Render widget | Indicators centered, version right | Widget |

#### Test Code Templates

```typescript
// Backend unit test - dateUtils.test.ts
describe('getPSTDate', () => {
  it('should return correct PST date at midnight UTC', () => {
    // Midnight UTC on Jan 10 = 4pm PST on Jan 9
    const date = new Date('2026-01-10T00:00:00Z');
    expect(getPSTDate(date)).toBe('20260109');
  });

  it('should return correct PST date at noon UTC', () => {
    // Noon UTC on Jan 10 = 4am PST on Jan 10
    const date = new Date('2026-01-10T12:00:00Z');
    expect(getPSTDate(date)).toBe('20260110');
  });
});

describe('formatVersion', () => {
  it('should format version with padded counter', () => {
    expect(formatVersion('0.0.0', '20260109', 42)).toBe('0.0.0-20260109-0042');
  });

  it('should handle counter of 1', () => {
    expect(formatVersion('1.2.3', '20260109', 1)).toBe('1.2.3-20260109-0001');
  });
});
```

```dart
// Flutter widget test - status_bar_test.dart
testWidgets('StatusBar displays version in bottom right', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatusBar(),
      ),
    ),
  );

  // Find version text (format: X.X.X-yyyymmdd-####)
  final versionFinder = find.textContaining(RegExp(r'\d+\.\d+\.\d+-\d{8}-\d{4}'));
  expect(versionFinder, findsOneWidget);
});
```

#### Coverage Requirements

| Area | Minimum Coverage |
|------|------------------|
| New backend code | 80% |
| Date utility functions | 100% |
| Version formatting | 100% |
| Flutter version display | Widget test coverage |

---

### 9) Rollout Plan

#### Deployment Checklist

- [ ] All tests pass in CI
- [ ] DynamoDB table `bb_draft_versions` created on server
- [ ] Backend deployed with version endpoints
- [ ] GitHub Actions workflow updated
- [ ] First deploy generates version correctly

#### Rollback Plan

```bash
# If version system fails, deploy still works with fallback
# The --dart-define defaults to empty, which triggers fallback in app

# To fully rollback:
git revert <commit-sha>
# Status bar will show without version (existing behavior)
```

#### Post-Deployment Verification

| Check | Command / Method | Expected |
|-------|------------------|----------|
| Version endpoint | curl /bb-draft-api/version/current | Returns version JSON |
| App shows version | Load https://zycroft.duckdns.org/bb-draft/ | Version in status bar |
| Counter increments | Deploy again | Counter increases by 1 |

---

### 10) Agent Output Requirements

> **Agent Instructions:** Include ALL of the following in your final response.

#### Required Outputs

1. **Change Summary**
   ```
   ## Summary
   [2-3 sentence description of what was done and why]

   ## Files Changed
   - `path/file.ts` — [what changed]
   - `path/file.test.ts` — [tests added]
   ```

2. **Commands Executed**
   ```
   ## Commands Run
   - `npm run build` — ✅ Success
   - `npm run test` — ✅ All 15 tests pass
   - `flutter analyze` — ✅ No issues
   ```

3. **Validation Evidence**
   ```
   ## Validation
   [Paste relevant logs, test output, or screenshots]
   ```

4. **Status Report**
   ```
   ## Status
   - [x] All requirements implemented
   - [x] All tests from Test Specification implemented
   - [x] All tests pass (X tests)
   - [x] Linting passes
   - [x] All Success Criteria verified
   - [x] All Acceptance Criteria pass
   - [ ] Known limitation: [if any]
   ```

5. **Follow-up Items** (if any)
   ```
   ## Follow-ups
   - [ ] Optional improvement: [description]
   - [ ] Tech debt: [description]
   ```

---

### 11) Quick Reference

#### Common Commands

| Action | Command |
|--------|---------|
| Flutter build | `flutter build web --release` |
| Flutter test | `flutter test` |
| Flutter analyze | `flutter analyze` |
| Backend build | `npm run build` |
| Backend test | `npm run test` |
| Backend dev | `npm run dev` |

#### File Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Flutter widget | `snake_case.dart` | `status_bar.dart` |
| Flutter config | `snake_case.dart` | `app_config.dart` |
| Backend route | `camelCase.ts` | `version.ts` |
| Backend model | `PascalCase.ts` | `Version.ts` |
| Test file | `*.test.ts` / `*_test.dart` | `version.test.ts` |

#### Version Format Reference

```
Format: X.X.X-yyyymmdd-####

Examples:
  0.0.0-20260109-0001  (first deploy on Jan 9, 2026)
  0.0.0-20260109-0002  (second deploy same day)
  0.0.0-20260110-0001  (first deploy on Jan 10, resets)
  1.0.0-20260110-0001  (after major version bump in config)
```

#### DynamoDB Table Schema

```
Table: bb_draft_versions
Partition Key: date (String) - "yyyymmdd"

Item structure:
{
  "date": "20260109",
  "counter": 3,
  "lastUpdated": "2026-01-09T15:30:00Z"
}
```

---

### Template Usage Notes

**For Plan Authors:**

1. Fill in ALL sections before handing to agent
2. Be explicit — agents cannot read minds
3. Include actual file paths, not placeholders
4. Provide code examples from the actual codebase
5. Specify exact commands with expected outputs
6. Define complete Test Matrix in Section 8 — these WILL be implemented

**For AI Agents:**

1. Read entire plan before starting
2. Execute steps in order unless dependencies allow parallelization
3. Stop at checkpoints and verify before continuing
4. If blocked, report what's blocking and ask for guidance
5. **REQUIRED:** Implement ALL tests from Section 8 (Test Specification)
6. **REQUIRED:** Execute Phase 7 (Final Validation) before marking complete
7. Do not skip test implementation — tests are mandatory, not optional
8. Always provide the required outputs at completion
9. Verify ALL Success Criteria and Acceptance Criteria before completing
