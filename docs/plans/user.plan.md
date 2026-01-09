
## AI Coding Agent Execution Plan: User Management

> **Purpose:** Define user lifecycle from authentication through league participation, establishing the foundation for role-based features.

---

### 0) Metadata

| Field | Value |
|-------|-------|
| **Project / Repo** | bb_draft |
| **Task Title** | User Management & League Participation |
| **Owner / Requester** | zycroft |
| **Target Branch** | main |
| **Priority** | P1 (High) |
| **Estimated Complexity** | Medium (4-10 files) |
| **Related tickets / docs** | `commissioner.plan.md`, `team-owner.plan.md` |

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

- Changes to Firebase authentication configuration
- Modifications to existing user data schema that affect production data
- Changes to CORS or security middleware
- Any operation that would delete user data

---

### 2) Objective

**Goal:**
> When this task is complete, users will be able to authenticate via Google Sign-In, manage their profile, create new leagues (becoming commissioners), join existing leagues via invite code (becoming team owners), and leave leagues they no longer wish to participate in.

**Success Criteria:**

- [ ] SC1: User can sign in with Google and profile syncs to DynamoDB
- [ ] SC2: User can create a league and is assigned commissioner role
- [ ] SC3: User can join a league via invite code and is assigned team owner role
- [ ] SC4: User can leave a league (with restrictions during active draft)
- [ ] SC5: User can view all leagues they participate in with their role

**Non-goals / Out of Scope:**

- Commissioner-specific features (see `commissioner.plan.md`)
- Team owner-specific features (see `team-owner.plan.md`)
- Draft participation mechanics
- Trade functionality
- In-season roster management

**User-Facing Impact:**

- [x] UI changes: League creation/join/leave screens
- [x] API changes: New endpoints for league participation
- [x] Behavior changes: Role assignment on league actions

---

### 3) Context & Constraints

#### Codebase Context

| Aspect | Details |
|--------|---------|
| **Primary files to modify** | `src/routes/users.ts`, `src/routes/leagues.ts`, `src/models/User.ts` |
| **Files to read (context only)** | `src/types/index.ts`, `src/middleware/auth.ts` |
| **Test files** | `src/routes/users.test.ts`, `src/routes/leagues.test.ts` |
| **Config files** | `src/config/firebase.ts`, `src/config/database.ts` |
| **Flutter files** | `lib/services/league_service.dart`, `lib/screens/leagues/` |

#### Existing Patterns to Follow

```
Backend patterns:
- Routes use Express Router with authMiddleware for protected endpoints
- Models use DynamoDB DocumentClient with GetCommand/PutCommand/ScanCommand
- All responses follow { data } or { error, message } shape
- IDs use format: `prefix_${uuidv4().slice(0, 8)}` (e.g., lg_abc12345)

Flutter patterns:
- Services use ApiService for HTTP calls
- Providers extend ChangeNotifier for state management
- Screens follow StatefulWidget pattern with loading states
```

#### Constraints

| Constraint Type | Requirement |
|----------------|-------------|
| **Backward compatibility** | Required - existing users must not be affected |
| **Performance** | League list queries < 500ms |
| **Security** | All league operations require authentication |
| **Dependencies** | No new packages required |

---

### 4) Requirements

#### Functional Requirements

| ID | Requirement | Priority | Verification Method |
|----|-------------|----------|---------------------|
| R1 | User authenticates via Firebase Google Sign-In | Must | Integration test |
| R2 | User profile syncs to DynamoDB on first login | Must | Unit test |
| R3 | User can create a league with name and settings | Must | API test |
| R4 | Creating a league assigns user as commissioner | Must | Unit test |
| R5 | User can join league via 6-character invite code | Must | API test |
| R6 | Joining a league creates team and assigns team owner role | Must | Unit test |
| R7 | User cannot join same league twice | Must | API test |
| R8 | User cannot join full league | Must | API test |
| R9 | User can leave a league (pre-draft only) | Must | API test |
| R10 | User can view all leagues with role indicator | Must | API test |

#### Non-Functional Requirements

| ID | Requirement | Target | Verification |
|----|-------------|--------|--------------|
| NFR1 | API response time | < 500ms | Manual timing |
| NFR2 | Error messages | User-friendly, actionable | Code review |
| NFR3 | Audit logging | All league join/leave actions logged | Log inspection |

#### Acceptance Criteria

```gherkin
AC1: User Creates League
  Given an authenticated user
  When they POST to /api/leagues with { name: "My League" }
  Then a new league is created with status "pre_draft"
  And the user is set as commissionerId
  And an invite code is generated
  And the response includes the full league object

AC2: User Joins League
  Given an authenticated user
  And a league exists with invite code "ABC123"
  When they POST to /api/leagues/join with { inviteCode: "ABC123", teamName: "My Team" }
  Then a new team is created in that league
  And the user is set as ownerId on the team
  And the response includes both league and team objects

AC3: User Leaves League
  Given an authenticated user who owns a team in a league
  And the league status is "pre_draft"
  When they DELETE to /api/leagues/{leagueId}/leave
  Then their team is deleted from the league
  And they no longer appear in league membership
  And the response confirms successful departure

AC4: User Cannot Leave During Draft
  Given an authenticated user who owns a team in a league
  And the league status is "drafting"
  When they DELETE to /api/leagues/{leagueId}/leave
  Then a 400 error is returned
  And the message explains they cannot leave during an active draft

AC5: Commissioner Cannot Leave Own League
  Given an authenticated user who is commissioner of a league
  When they DELETE to /api/leagues/{leagueId}/leave
  Then a 400 error is returned
  And the message explains commissioners must delete or transfer the league
```

---

### 5) Technical Design

#### Architecture Decision

**Approach:** Extend existing routes with league participation endpoints. User roles are derived from league/team ownership rather than stored explicitly on user record.

**Alternatives Considered:**

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Store roles on User record | Fast lookup | Data duplication, sync issues | Rejected |
| Derive roles from league/team data | Single source of truth | Slightly more queries | Chosen |
| Separate membership table | Flexible permissions | Over-engineering for MVP | Rejected |

**Rationale:** Role derivation keeps data normalized and avoids sync issues. Performance impact is minimal since league queries already fetch related teams.

#### Data / API Changes

**Existing Endpoints (no changes needed):**

```
POST /api/users/sync
  - Already syncs Firebase user to DynamoDB

GET /api/users/me
  - Already returns user profile

POST /api/leagues
  - Already creates league with commissioner

POST /api/leagues/join
  - Already joins via invite code
```

**New Endpoint:**

```
DELETE /api/leagues/:leagueId/leave
  Request:  (none - uses auth token)
  Response: { message: "Successfully left league" }
  Errors:
    400 - Cannot leave during active draft
    400 - Commissioners cannot leave (must delete or transfer)
    404 - League not found
    404 - You are not a member of this league
```

**Enhanced Endpoint:**

```
GET /api/leagues
  Response: {
    leagues: [
      {
        leagueId: string,
        name: string,
        role: "commissioner" | "team_owner",
        teamId?: string,
        teamName?: string,
        status: LeagueStatus,
        teamCount: number,
        maxTeams: number
      }
    ]
  }
```

**Schema Changes:**

```
No schema changes required - using existing tables:
- bb_draft_users (userId, email, displayName, photoUrl, preferences)
- bb_draft_leagues (leagueId, name, commissionerId, inviteCode, status, settings)
- bb_draft_teams (teamId, leagueId, ownerId, name, roster, draftQueue)
```

**Migration Strategy:**

- [x] No migration needed

#### Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| User leaves mid-draft | Low | High | Block leave during drafting status |
| Orphaned teams | Low | Medium | Delete team when user leaves |
| Commissioner abandonment | Medium | High | Require transfer before leave |

---

## User Roles and Permissions

### Role Definitions

| Role | How Acquired | Scope | Description |
|------|--------------|-------|-------------|
| **Commissioner** | Create a league | League-wide | Full control over league settings, draft, teams |
| **Deputy Commissioner** | Assigned by commissioner | League-wide | Delegated commissioner powers (future) |
| **Team Owner** | Join a league | Team-specific | Manage own team, participate in draft/trades |
| **Spectator** | Invited to view | Read-only | View league activity without participation (future) |

### Permission Matrix

| Action | Commissioner | Deputy | Team Owner | Spectator |
|--------|:------------:|:------:|:----------:|:---------:|
| View league | ✅ | ✅ | ✅ | ✅ |
| View all teams | ✅ | ✅ | ✅ | ✅ |
| Edit league settings | ✅ | ✅ | ❌ | ❌ |
| Manage draft order | ✅ | ✅ | ❌ | ❌ |
| Start/pause draft | ✅ | ✅ | ❌ | ❌ |
| Remove teams | ✅ | ✅ | ❌ | ❌ |
| Transfer ownership | ✅ | ❌ | ❌ | ❌ |
| Delete league | ✅ | ❌ | ❌ | ❌ |
| Regenerate invite code | ✅ | ✅ | ❌ | ❌ |
| Make draft picks | ✅ (own team) | ✅ (own team) | ✅ | ❌ |
| Manage own roster | ✅ | ✅ | ✅ | ❌ |
| Propose trades | ✅ | ✅ | ✅ | ❌ |
| Approve trades | ✅ | ✅ | ❌ | ❌ |
| Leave league | ❌ (must transfer) | ✅ | ✅ | ✅ |

### Role Transitions

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Journey                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   [Authenticated User]                                          │
│         │                                                        │
│         ├──── Creates League ────► [Commissioner]               │
│         │                               │                        │
│         │                               ├── Transfers league ──► │
│         │                               │   (becomes Team Owner) │
│         │                               │                        │
│         │                               └── Deletes league ────► │
│         │                                   (no role)            │
│         │                                                        │
│         └──── Joins League ─────► [Team Owner]                  │
│                                        │                         │
│                                        ├── Leaves league ──────► │
│                                        │   (no role)             │
│                                        │                         │
│                                        └── Promoted by commish ─►│
│                                            [Deputy Commissioner] │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Role-Based Feature Routing

After league participation, users are routed to role-specific features:

| User Action | Resulting Role | Next Steps | Plan Document |
|-------------|----------------|------------|---------------|
| Creates league | Commissioner | Configure league, invite members, set draft | `commissioner.plan.md` |
| Joins league | Team Owner | Set team name, prepare draft queue, wait for draft | `team-owner.plan.md` |

---

### 6) Implementation Steps

> **Agent Instructions:** Execute steps in order. Each step should be atomic and independently verifiable.

#### Phase 1: Backend - Leave League Endpoint

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 1.1 | Add DELETE /:leagueId/leave route | `src/routes/leagues.ts` | Route exists |
| 1.2 | Implement leave logic with validations | `src/routes/leagues.ts` | Unit tests pass |
| 1.3 | Add team deletion on leave | `src/routes/leagues.ts` | Team removed from DB |

**Checkpoint 1:** `curl -X DELETE .../api/leagues/{id}/leave` returns success for valid case

#### Phase 2: Backend - Enhanced League List

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 2.1 | Enhance GET /leagues to include role | `src/routes/leagues.ts` | Response includes role |
| 2.2 | Include team info for team owners | `src/routes/leagues.ts` | Response includes teamId/teamName |

**Checkpoint 2:** GET /api/leagues returns leagues with role field populated

#### Phase 3: Flutter - League Participation UI

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 3.1 | Add leaveLeague method to service | `lib/services/league_service.dart` | Method callable |
| 3.2 | Add leave button to league detail screen | `lib/screens/leagues/league_detail_screen.dart` | Button visible |
| 3.3 | Add confirmation dialog for leave | `lib/screens/leagues/league_detail_screen.dart` | Dialog shows |
| 3.4 | Display role badge on league list | `lib/screens/leagues/leagues_screen.dart` | Badge visible |

**Checkpoint 3:** User can tap leave, confirm, and be removed from league

#### Phase 4: Implement Test Specification

> **Agent Instructions:** Implement ALL tests defined in Section 8 (Test Specification). Tests are required, not optional. Do not skip this phase.

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 4.1 | Create test file for leave endpoint | `src/routes/leagues.test.ts` | File exists |
| 4.2 | Implement "Leave league success" test | `src/routes/leagues.test.ts` | Test passes |
| 4.3 | Implement "Leave as commissioner" test | `src/routes/leagues.test.ts` | Test passes |
| 4.4 | Implement "Leave during draft" test | `src/routes/leagues.test.ts` | Test passes |
| 4.5 | Implement "Leave non-member" test | `src/routes/leagues.test.ts` | Test passes |
| 4.6 | Implement "Leave nonexistent league" test | `src/routes/leagues.test.ts` | Test passes |
| 4.7 | Implement "List leagues with roles" test | `src/routes/leagues.test.ts` | Test passes |
| 4.8 | Add Flutter widget tests for leave UI | `test/screens/league_detail_test.dart` | Tests pass |
| 4.9 | Run all tests and verify pass | — | `npm test` and `flutter test` exit 0 |

**Checkpoint 4:** All tests from Test Specification implemented and passing

#### Phase 5: Validation & Cleanup

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 5.1 | Run backend linter | — | No errors |
| 5.2 | Run flutter analyze | — | No errors |
| 5.3 | Manual smoke test of leave functionality | — | Feature works as expected |

#### Phase 6: Final Validation

> **Agent Instructions:** Execute the complete Validation Protocol (Section 7) before marking the task complete. All checks must pass.

| Step | Action | Verification |
|------|--------|--------------|
| 6.1 | Execute Build & Lint commands from Section 7 | All commands exit 0 |
| 6.2 | Execute Test Execution commands from Section 7 | All tests pass |
| 6.3 | Complete Smoke Test Checklist from Section 7 | All checks pass |
| 6.4 | Capture Evidence listed in Section 7 | Evidence documented |
| 6.5 | Verify all Success Criteria (Section 2) are met | All SC items checked |
| 6.6 | Verify all Acceptance Criteria (Section 4) pass | All AC scenarios pass |

**Checkpoint 6:** Feature complete, all tests pass, all validations pass

#### Decision Points

| Situation | Action |
|-----------|--------|
| User is commissioner trying to leave | Return 400 with message to transfer or delete |
| League is in drafting status | Return 400 with message to wait for draft completion |
| User has no team in league | Return 404 "not a member" |
| Team has drafted players | Still allow leave in pre_draft, delete team and players |

---

### 7) Validation Protocol

#### Build & Lint

```bash
# Backend
cd bb-draft-backend
npm run build        # Expected: Exit 0
npm run lint         # Expected: Exit 0

# Frontend
cd ..
flutter analyze      # Expected: No issues
```

#### Test Execution

```bash
# Backend tests
cd bb-draft-backend
npm run test         # Expected: All pass

# Flutter tests
cd ..
flutter test         # Expected: All pass
```

#### Smoke Test Checklist

| Test | Command / Action | Expected Result |
|------|------------------|-----------------|
| API health | `curl https://zycroft.duckdns.org/bb-draft-api/health` | `{"status":"ok"}` |
| Create league | POST /api/leagues | Returns league with commissionerId = user |
| Join league | POST /api/leagues/join | Returns league + team |
| Leave league | DELETE /api/leagues/{id}/leave | Returns success message |
| List leagues | GET /api/leagues | Returns leagues with role field |

#### Evidence to Capture

- [ ] Test output showing all tests pass
- [ ] API response examples for each endpoint
- [ ] Screenshot of league list with role badges

---

### 8) Test Specification

#### Test Matrix

| Scenario | Input | Expected Output | Test Type |
|----------|-------|-----------------|-----------|
| Leave league success | Valid leagueId, user is team owner | 200, team deleted | Integration |
| Leave as commissioner | Valid leagueId, user is commissioner | 400, error message | Integration |
| Leave during draft | League status = "drafting" | 400, error message | Integration |
| Leave non-member | User has no team in league | 404, error message | Integration |
| Leave nonexistent league | Invalid leagueId | 404, error message | Integration |
| List leagues with roles | User in multiple leagues | 200, role per league | Integration |

#### Test Code Template

```typescript
describe('DELETE /api/leagues/:leagueId/leave', () => {
  it('should allow team owner to leave pre-draft league', async () => {
    // Arrange: Create league, join as different user
    // Act: DELETE /api/leagues/{id}/leave
    // Assert: 200, team no longer exists
  });

  it('should prevent commissioner from leaving', async () => {
    // Arrange: Create league as commissioner
    // Act: DELETE /api/leagues/{id}/leave
    // Assert: 400, appropriate error message
  });

  it('should prevent leaving during active draft', async () => {
    // Arrange: Create league, set status to "drafting"
    // Act: DELETE /api/leagues/{id}/leave
    // Assert: 400, appropriate error message
  });
});
```

---

### 9) Rollout Plan

#### Deployment Checklist

- [ ] All backend tests pass
- [ ] All Flutter tests pass
- [ ] Manual smoke test on staging
- [ ] No breaking changes to existing endpoints

#### Rollback Plan

```bash
# If issues detected:
git revert <commit-sha>
# Redeploy previous version
```

#### Post-Deployment Verification

| Check | Command / Method | Expected |
|-------|------------------|----------|
| API health | Health endpoint | 200 OK |
| Existing leagues accessible | GET /api/leagues | Returns user's leagues |
| Leave functionality works | Manual test | Success for team owner |

---

### 10) Agent Output Requirements

#### Required Outputs

1. **Change Summary** - List all files modified with brief description
2. **Commands Executed** - All npm/flutter commands with results
3. **Validation Evidence** - Test output, API responses
4. **Status Report** - Checklist of requirements completed
5. **Follow-up Items** - Any deferred work or tech debt

---

### 11) Quick Reference

#### Common Commands

| Action | Command |
|--------|---------|
| Backend build | `cd bb-draft-backend && npm run build` |
| Backend test | `cd bb-draft-backend && npm test` |
| Backend dev | `cd bb-draft-backend && npm run dev` |
| Flutter analyze | `flutter analyze` |
| Flutter test | `flutter test` |
| Flutter run | `flutter run -d chrome` |

#### File Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Backend route | `*.ts` | `leagues.ts` |
| Backend model | `*.ts` (PascalCase) | `League.ts` |
| Flutter service | `*_service.dart` | `league_service.dart` |
| Flutter screen | `*_screen.dart` | `leagues_screen.dart` |
| Flutter provider | `*_provider.dart` | `league_provider.dart` |

#### API Base URLs

| Environment | URL |
|-------------|-----|
| Production | `https://zycroft.duckdns.org/bb-draft-api/api` |
| Development | `http://localhost:3000/api` |

---

### Related Plan Documents

| Document | Description |
|----------|-------------|
| `commissioner.plan.md` | Features available after creating a league |
| `team-owner.plan.md` | Features available after joining a league |
| `draft.plan.md` | Draft participation mechanics |
| `league.plan.md` | League configuration and settings |
