---
name: feature-orchestrator
phase: build
tags: [feature, multi-story, dependency-graph, orchestration, waves, topological-sort]
triggers:
  - Feature has more than one story (each with own SPEC/TC/PLAN)
  - After all story SPEC.md files are approved and TC.md + PLAN.md generated
related:
  - 3-shot-review
  - 3-shot-docs
  - incremental-implementation
description: Orchestrates the 3-shot delivery loop (/implf:full → /reviewf:full → /docsf:full) across a multi-story feature. Builds a dependency graph, determines wave-order execution, then delegates per-story implementation to /impl:full. Owns only orchestration — dep gating, FEATURE.md status tracking, commit format override. Use when a feature has multiple stories (subtasks) each with their own SPEC.md + TC.md + PLAN.md under stories/.
---

# Feature Orchestrator

## Overview

A feature consists of N stories, each a self-contained unit of work with its own SPEC.md, TC.md, and PLAN.md stored in `stories/<S##>-<slug>/`. Stories may depend on other stories (e.g., S02 needs S01's migration applied first). This skill builds the execution order from the dependency graph before touching any code, runs each story's impl loop in the correct sequence, and maintains progress in `FEATURE.md`.

This skill is used by three commands that map to the three shots:
- `/implf:full` — Shot 1 (this skill's main process)
- `/reviewf:full` — Shot 2 (delegates to `3-shot-review` skill at feature scope)
- `/docsf:full` — Shot 3 (delegates to `3-shot-docs` skill at feature scope)

## When to Use

- When a feature has more than one story and you want to implement, review, or document them as a cohesive unit
- After all story `SPEC.md` files are approved and `TC.md` + `PLAN.md` files are generated

**When NOT to use:**
- Single-story work — use `/impl:full`, `/review:full`, `/docs:full` directly
- Before all SPEC.md files are approved (Gate 1 must be cleared per story before the batch starts)

## Process — `/implf:full` (Shot 1)

### Step 1: Read FEATURE.md

Read `FEATURE.md` from the project root. Extract:
- `feature_slug`, `scope`
- The stories table: ID, title, dir, depends_on, status

If `FEATURE.md` is missing: stop — "FEATURE.md not found. Create it from `pod/templates/FEATURE.md` and populate the stories table."

### Step 2: Validate story directories

For each story in the table:
- Confirm `stories/<dir>/` exists
- Confirm `stories/<dir>/SPEC.md` exists and `status: approved`
- Confirm `stories/<dir>/TC.md` exists
- Confirm `stories/<dir>/PLAN.md` exists
- Run SC tag validator: `bash scripts/validate-sc-tags.sh --spec stories/<dir>/SPEC.md --tc stories/<dir>/TC.md --plan stories/<dir>/PLAN.md`

Collect all failures. If any story fails validation, list them all and stop:
```
Pre-flight failures:
  S02  stories/S02-user-profile/  SPEC.md status is draft (need approved)
  S03  stories/S03-user-list/     TC.md missing
Fix these before running /implf:full.
```

### Step 3: Dependency analysis

Build a directed acyclic graph from the `Depends On` column.

**Algorithm:**
1. Parse each story's `depends_on` list
2. Assign wave numbers via Kahn's algorithm (BFS topological sort):
   - Wave 1: stories with no dependencies
   - Wave 2: stories whose only deps are in Wave 1
   - Wave N+1: stories whose deps are all in Wave ≤ N
3. Detect cycles: if a story cannot be assigned a wave → hard stop with cycle report

> [!WARNING]
> Cycle detection is a hard stop. List the cycle explicitly and exit before touching any code. Never attempt to run stories in a cyclic graph — the dep gate will loop forever.

**Display the analysis before running anything:**

```
Dependency analysis
───────────────────
S01  user-login           deps: —              Wave 1  ← start here
S02  user-profile         deps: S01            Wave 2
S03  user-list            deps: S01            Wave 2
S04  admin-dashboard      deps: S02, S03       Wave 3

Execution plan (sequential within each wave):
  Wave 1:  S01
  Wave 2:  S02 → S03            (S01 must complete first)
  Wave 3:  S04                   (S02 + S03 must complete first)

Stories ready now:  S01
Stories pending deps:  S02, S03 (waiting on S01) · S04 (waiting on S02 + S03)
Already complete:   —
```

In `--auto` mode: display the plan and wait for unambiguous human approval ("approve" / "go" / "yes") before proceeding. Treat "looks good" or "I guess" as NOT approved.

In single-story mode (default): display the plan, then run only the next eligible story (lowest wave, lowest ID), then stop.

### Step 4: Per-story impl loop

For each story in execution order (skip `impl_complete`, `done`, `blocked`):

**Dependency gate:** before starting story S, verify all stories in its `depends_on` list have `status: impl_complete`. If any dep is `blocked` or `skipped`: mark this story `skipped` in FEATURE.md and continue to the next.

**Set status:** update story row to `in_progress` in FEATURE.md.

**Delegate to `/impl:full`** — all per-task work is handled by `/impl:full` (JIT context loading, RED→GREEN TDD loop, fix loop, TC.md verdicts, commits, PLAN.md updates). This skill owns only the orchestration wrapper.

Two overrides when calling `/impl:full` for a story:

1. **Working root**: `stories/<dir>/` is treated as the project root. `SPEC.md`, `TC.md`, `PLAN.md`, `BLOCKERS.md` are read from and written to this directory.
2. **Commit format**: `feat(<feature-slug>/<story-slug>): <task title> [SC-01]` — all other commit rules from `/impl:full` apply unchanged.

Run `/impl:full --auto` for this story (feature-level approval already obtained in Step 3).

**After `/impl:full` returns:**
- All PLAN.md tasks `complete` or partially `blocked` → set `status: impl_complete` in FEATURE.md
- Hard blocker requiring human input → set `status: blocked`
- Print: `S01 user-login ✓ impl_complete  3/3 tasks  3 commits`

### Step 5: Feature impl summary

After all eligible stories have been processed:

```
/implf:full summary
───────────────────
S01  user-login         ✓ impl_complete   4 tasks  4 commits
S02  user-profile       ✓ impl_complete   3 tasks  3 commits
S03  user-list          ✗ blocked         2/3 tasks complete → stories/S03-user-list/BLOCKERS.md
S04  admin-dashboard    ○ skipped         S03 dependency blocked

Feature impl_status: partial

Next steps:
• Resolve S03 blocker and re-run /implf:full (resumes from S03)
• Or run /reviewf:full to gate on S01 + S02 only (S03/S04 excluded from review scope)
```

Update `impl_status` in FEATURE.md frontmatter: `complete` if all stories are `impl_complete`; `partial` if any are `blocked` or `skipped`.

---

## Process — `/reviewf:full` (Shot 2)

Delegates to `pod/skills/3-shot-review/SKILL.md` with feature-wide scope.

### Step 1: Pre-flight

Read `FEATURE.md`. Require at least one story with `status: impl_complete`. Warn (do not stop) if any stories are `blocked` or `skipped` — they are excluded from the review scope.

Confirm review scope:
```
/reviewf:full scope
───────────────────
In scope (impl_complete):   S01 user-login · S02 user-profile
Excluded (blocked):         S03 user-list
Excluded (skipped):         S04 admin-dashboard
```

### Step 2: Aggregate SPEC and SC tags

Collect all SC tags across in-scope stories' SPEC.md files. Prefix each with its story ID to avoid collision: `S01-SC-01`, `S01-SC-02`, `S02-SC-01`, etc.

### Step 3: Feature-scope 4-dimension audit

Run the same parallel fan-out (code-reviewer + security-auditor + test-engineer) as `/review:full` but against the aggregate diff of all in-scope stories since the feature branch was cut.

Score each dimension across all stories. Per-story sub-scores appear in REVIEW.md for traceability.

### Step 4: Write feature REVIEW.md

Write `REVIEW.md` at project root. Sections:
- Feature summary (scope, in-scope stories, excluded stories)
- Per-story results table (story ID, score, verdict per dimension)
- Aggregate 4-dimension scorecard
- SC tag coverage table (all SC tags across all in-scope stories)
- P0 gate results (across all stories)
- Verdict + rework instructions

Update `review_verdict` in FEATURE.md frontmatter.

---

## Process — `/docsf:full` (Shot 3)

Delegates to `pod/skills/3-shot-docs/SKILL.md` with feature-wide scope.

### Step 1: Gates

- Gate A: `REVIEW.md` verdict must be `APPROVE` (or `MINOR` with confirmed fixes)
- Gate B: coverage ≥ 85% on all changed files across in-scope stories

### Step 2: Feature-scope docs

Generate a single coherent feature document — not N separate story docs:
- `README.md` — one feature section covering all stories from user perspective
- `ARCHITECTURE.md` — one ADR entry for the whole feature
- `API_SPEC.md` (BE) or `COMPONENT_SPEC.md` (FE) — complete interface spec from implemented code across all in-scope stories

Update all stories' status to `done` in FEATURE.md and set `impl_status: complete`.

---

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "S02 only has a small dep on S01, I can run them together" | The dependency graph exists to prevent data model mismatches. Always honour the declared order. |
| "S03 is blocked but the blocker is trivial, I'll skip it for review" | Mark it `blocked` and document it. `/reviewf:full` will exclude it cleanly. |
| "I'll combine all stories into one PLAN.md to simplify" | This breaks the per-story commit discipline and makes `blocked` status ambiguous. Keep stories isolated. |

## Red Flags

- Dependency analysis skipped and stories run in FEATURE.md table order (not wave order)
- Story started before its `depends_on` are `impl_complete`
- `skipped` story not documented in FEATURE.md
- Cycle in `depends_on` graph not detected before impl starts
- REVIEW.md written with blocked/skipped stories counted against the score

## Verification

- [ ] Dependency analysis displayed and approved before first story starts (in `--auto` mode)
- [ ] Stories run in wave order, not table order
- [ ] No story started until all its `depends_on` are `impl_complete`
- [ ] Blocked stories documented in their own `BLOCKERS.md` AND reflected in FEATURE.md status
- [ ] Skipped stories explicitly noted in the run summary
- [ ] REVIEW.md clearly states which stories are in-scope and which are excluded
- [ ] `impl_status` and `review_verdict` in FEATURE.md frontmatter kept current

## See Also

- [[3-shot-review]] — delegated to by `/reviewf:full`
- [[3-shot-docs]] — delegated to by `/docsf:full`
- [[3-shot-gates]] — gate rules including feature-scope additions
- [[3-shot-loop|pod/docs/3-shot-loop.md]] — full loop map
- `/impl:full` — single-story equivalent (delegated to per story)
- `pod/templates/FEATURE.md` — the manifest this skill reads and updates
