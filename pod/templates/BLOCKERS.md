# BLOCKERS — {{project}}

> Written by `/impl:full` when the fix loop (max 3 iterations) cannot resolve a failure.
> **Append-only** across runs. Mark resolved entries `[RESOLVED]` — do not delete them.
> Surface at end of each `/impl:full` run if non-empty.

---

<!-- Template for one entry. Copy and fill for each new blocker. -->

### BLOCKER: {{task-title}} — {{YYYY-MM-DD HH:MM}}

**Story:** {{feature_slug}}
**Task:** T{{N}}
**SC refs:** SC-01, SC-02
**Run status:** PARTIAL

**What failed:**
```
{{test name or build step that failed}}
```

**Structured error:**
```
{{paste the exact error — not prose, the actual error output}}
```

**What the fix loop attempted ({{N}}/3 iterations):**
1. {{attempt 1 description}}
2. {{attempt 2 description}}
3. {{attempt 3 description}}

**Decision needed from human:**
> {{Specific question — e.g. "Is it correct that this endpoint requires admin role? Guard is rejecting test user.", or "Migration fails because column X has existing nulls — should we backfill or make it nullable?"}}

**Status:** [ ] OPEN  [ ] RESOLVED

**Resolution:** *(fill when resolved)*
> {{What was decided and done}}

---

<!-- Additional entries appended below by subsequent /impl:full runs -->
