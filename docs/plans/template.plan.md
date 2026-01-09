
## AI Coding Agent Execution Plan Template

> **Purpose:** This template structures tasks for autonomous AI agent execution. Write plans as explicit, unambiguous instructions that require no human clarification during execution.

---

### 0) Metadata

| Field | Value |
|-------|-------|
| **Project / Repo** | |
| **Task Title** | |
| **Owner / Requester** | |
| **Target Branch** | |
| **Priority** | P0 (Critical) / P1 (High) / P2 (Medium) / P3 (Low) |
| **Estimated Complexity** | Small (1-3 files) / Medium (4-10 files) / Large (10+ files) |
| **Related tickets / docs** | |

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

- [ ] **Autonomous** — Execute all steps without user confirmation
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
> When this task is complete, the system will be able to: ___

**Success Criteria (must be verifiable by agent):**

- [ ] SC1: [Specific, measurable outcome]
- [ ] SC2: [Specific, measurable outcome]
- [ ] SC3: [Specific, measurable outcome]

**Non-goals / Out of Scope:**

- Explicitly list what should NOT be changed
- List related features to avoid touching

**User-Facing Impact:**

- [ ] No user-facing changes
- [ ] UI changes: [describe]
- [ ] API changes: [describe]
- [ ] Behavior changes: [describe]

---

### 3) Context & Constraints

#### Codebase Context

| Aspect | Details |
|--------|---------|
| **Primary files to modify** | `path/to/file.ts`, `path/to/other.ts` |
| **Files to read (context only)** | `path/to/reference.ts` |
| **Test files** | `path/to/file.test.ts` |
| **Config files** | `path/to/config.ts` |

#### Existing Patterns to Follow

```
Example pattern from codebase:
- Services use dependency injection via constructor
- All API responses follow { data, error, meta } shape
- Use `camelCase` for variables, `PascalCase` for types
```

#### Constraints

| Constraint Type | Requirement |
|----------------|-------------|
| **Backward compatibility** | [Required/Not required] |
| **Performance** | [Targets if any] |
| **Security** | [Requirements] |
| **Dependencies** | [Allowed/Forbidden packages] |

---

### 4) Requirements

#### Functional Requirements

| ID | Requirement | Priority | Verification Method |
|----|-------------|----------|---------------------|
| R1 | | Must | Unit test |
| R2 | | Must | Integration test |
| R3 | | Should | Manual verification |

#### Non-Functional Requirements

| ID | Requirement | Target | Verification |
|----|-------------|--------|--------------|
| NFR1 | Response time | <200ms | Load test |
| NFR2 | Error handling | All errors logged | Log inspection |

#### Acceptance Criteria

```gherkin
AC1: [Feature name]
  Given [precondition]
  When [action]
  Then [expected outcome]
  And [additional outcome]

AC2: [Feature name]
  Given [precondition]
  When [action]
  Then [expected outcome]
```

---

### 5) Technical Design

#### Architecture Decision

**Approach:** [Brief description of chosen approach]

**Alternatives Considered:**

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| Option A | | | Chosen / Rejected |
| Option B | | | Chosen / Rejected |

**Rationale:** [Why this approach was selected]

#### Data / API Changes

**New Endpoints:**

```
METHOD /api/path
  Request:  { field: type }
  Response: { data: type }
  Errors:   400 (validation), 404 (not found), 500 (server)
```

**Schema Changes:**

```
Table: table_name
  + new_column: type (nullable: yes/no, default: value)
  - removed_column
  ~ modified_column: old_type -> new_type
```

**Migration Strategy:**

- [ ] No migration needed
- [ ] Forward-only migration
- [ ] Reversible migration with rollback script

#### Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| | Low/Med/High | Low/Med/High | |

---

### 6) Implementation Steps

> **Agent Instructions:** Execute steps in order. Each step should be atomic and independently verifiable. Mark steps complete as you go.

#### Phase 1: Setup

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 1.1 | [Action verb] [what] | `file.ts` | [How to verify] |
| 1.2 | | | |

**Checkpoint 1:** [What should be true before proceeding]

#### Phase 2: Core Implementation

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 2.1 | | | |
| 2.2 | | | |

**Checkpoint 2:** [What should be true before proceeding]

#### Phase 3: Integration

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 3.1 | | | |
| 3.2 | | | |

**Checkpoint 3:** [What should be true before proceeding]

#### Phase 4: Implement Test Specification

> **Agent Instructions:** Implement ALL tests defined in Section 8 (Test Specification). Tests are required, not optional. Do not skip this phase.

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 4.1 | Create test file(s) for new functionality | `path/to/feature.test.ts` | File exists |
| 4.2 | Implement tests from Test Matrix (Section 8) | `path/to/feature.test.ts` | All scenarios covered |
| 4.3 | Implement happy path tests | `path/to/feature.test.ts` | Tests pass |
| 4.4 | Implement error/edge case tests | `path/to/feature.test.ts` | Tests pass |
| 4.5 | Run all tests and verify pass | — | `npm run test` exits 0 |
| 4.6 | Verify coverage meets requirements | — | Coverage >= target |

**Checkpoint 4:** All tests from Test Specification implemented and passing

#### Phase 5: Validation & Cleanup

| Step | Action | Files | Verification |
|------|--------|-------|--------------|
| 5.1 | Run linter | — | No errors |
| 5.2 | Run type checker | — | No errors |
| 5.3 | Update docs if needed | `README.md` | Accurate |
| 5.4 | Manual smoke test | — | Feature works as expected |

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

> **Agent Instructions:** If you encounter these situations, follow the specified action.

| Situation | Action |
|-----------|--------|
| Existing function does X | Extend it, don't duplicate |
| Type doesn't exist | Create in `types/` directory |
| Test is flaky | Skip and note in output |
| Dependency conflict | Ask user before resolving |

---

### 7) Validation Protocol

> **Agent Instructions:** Execute these validations after implementation. All must pass before marking complete.

#### Build & Lint

```bash
# Commands to run (execute in order)
npm run build        # Expected: Exit 0, no errors
npm run lint         # Expected: Exit 0, no warnings
npm run typecheck    # Expected: Exit 0, no errors
```

#### Test Execution

```bash
# Unit tests
npm run test:unit -- --coverage    # Expected: All pass, coverage >= X%

# Integration tests
npm run test:integration           # Expected: All pass

# E2E tests (if applicable)
npm run test:e2e                   # Expected: All pass
```

#### Smoke Test Checklist

| Test | Command / Action | Expected Result |
|------|------------------|-----------------|
| API health | `curl localhost:3000/health` | `{"status":"ok"}` |
| Feature works | [Specific action] | [Specific result] |
| No regressions | [Existing flow] | [Still works] |

#### Evidence to Capture

- [ ] Test output showing all tests pass
- [ ] Coverage report (if applicable)
- [ ] Example API request/response
- [ ] Screenshot (if UI change)
- [ ] Log output showing expected behavior

---

### 8) Test Specification

#### Test Matrix

| Scenario | Input | Expected Output | Test Type |
|----------|-------|-----------------|-----------|
| Happy path | Valid input | Success response | Unit |
| Empty input | `null`/`undefined` | Validation error | Unit |
| Invalid type | Wrong type | Type error | Unit |
| Boundary | Max/min values | Handled correctly | Unit |
| Dependency down | Service unavailable | Graceful failure | Integration |
| Auth failure | Invalid token | 401 response | Integration |

#### Test Code Templates

```typescript
// Unit test template
describe('[Feature]', () => {
  it('should [expected behavior] when [condition]', () => {
    // Arrange
    // Act
    // Assert
  });
});
```

#### Coverage Requirements

| Area | Minimum Coverage |
|------|------------------|
| New code | 80% |
| Modified code | Maintain existing |
| Critical paths | 100% |

---

### 9) Rollout Plan

#### Deployment Checklist

- [ ] All tests pass in CI
- [ ] PR approved by reviewer
- [ ] No breaking changes (or migration plan ready)
- [ ] Feature flag configured (if applicable)
- [ ] Monitoring/alerts configured

#### Rollback Plan

```bash
# If issues detected, execute:
git revert <commit-sha>
# Or restore from:
# - Previous deployment tag
# - Database backup (if schema change)
```

#### Post-Deployment Verification

| Check | Command / Method | Expected |
|-------|------------------|----------|
| Service healthy | Health endpoint | 200 OK |
| No error spike | Error dashboard | < baseline |
| Feature works | Manual test | As specified |

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
   - `npm run lint` — ✅ No errors
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
| Build | `npm run build` |
| Test | `npm run test` |
| Lint | `npm run lint` |
| Format | `npm run format` |
| Dev server | `npm run dev` |

#### File Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Component | `PascalCase.tsx` | `UserProfile.tsx` |
| Service | `camelCase.service.ts` | `user.service.ts` |
| Test | `*.test.ts` | `user.service.test.ts` |
| Types | `camelCase.types.ts` | `user.types.ts` |

#### Error Handling Pattern

```typescript
try {
  // operation
} catch (error) {
  logger.error('Context message', { error, metadata });
  throw new AppError('User-friendly message', { cause: error });
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
6. **REQUIRED:** Execute Phase 6 (Final Validation) before marking complete
7. Do not skip test implementation — tests are mandatory, not optional
8. Always provide the required outputs at completion
9. Verify ALL Success Criteria and Acceptance Criteria before completing
