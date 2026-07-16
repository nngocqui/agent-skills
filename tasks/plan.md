# Implementation Plan: Custom AI-SDLC Harness for skeleton-be & skeleton-fe

## Overview

Fork and extend `addyosmani/agent-skills` with a custom overlay that implements the **3-Shot Delivery Loop** (`/impl:full` → `/review:full` → `/docs:full`) and the **ticket-first workflow** (ClickUp/Jira ticket → SPEC.md → PLAN.md → TC.md → impl loop) from *TMA AI-Native Development v19*.

Every SC tag is carried unchanged from the originating ticket to the review sign-off — mechanically enforced by a validator script, not by convention.

---

## Tech Stacks (resolved)

### skeleton-be
| Concern | Tool |
|---|---|
| Language / Framework | TypeScript + NestJS 11 (Express) |
| ORM / DB | Prisma 7 + PostgreSQL |
| Architecture | CQRS (`@nestjs/cqrs`), Modular (`src/modules/*`) |
| Auth | Passport JWT + RBAC guards/decorators |
| Tests | Jest 30 + ts-jest + Supertest |
| API Docs | Swagger (`@nestjs/swagger`) |
| Logging | nestjs-pino (structured JSON) |
| Lint / Format | ESLint 9 + Prettier 3 |
| Build | NestJS CLI (`nest build`) |
| Commands | `npx nest build` · `npx jest` · `npx jest --coverage` · `npx eslint src/` · `npx prisma migrate dev` |

### skeleton-fe
| Concern | Tool |
|---|---|
| Framework | React 19 + TypeScript 5.7 + Vite 6 |
| UI / Styling | shadcn/ui + Tailwind CSS 4 + Base UI |
| State | Zustand 5 (UI) + TanStack Query 5 (server) |
| Routing / Forms | React Router 7 + React Hook Form 7 + Zod 4 |
| Auth | OIDC (react-oidc-context) |
| Tests | Vitest 3 + Testing Library + Playwright + MSW 2 + Storybook 10 |
| i18n | i18next 25 |
| Error Tracking | Sentry |
| Commands | `npm run dev` · `npx vitest run` · `npx vitest run --coverage` · `npx playwright test` · `npm run build` · `npx eslint src/` |

---

## Architecture Decisions

### 1. Fork overlay — `pod/` directory for all custom work

All custom content lives in `pod/`. Upstream files in `skills/`, `agents/`, `.claude/commands/`, `hooks/`, `references/`, `docs/`, and `scripts/` are **never modified**. `git merge upstream/main` produces zero conflicts.

```
agent-skills/ (forked)
├── skills/               ← upstream — never touch
├── agents/               ← upstream — never touch
├── .claude/
│   ├── commands/         ← upstream flat .md files — never touch
│   │   ├── spec.md       ← upstream /spec (still works)
│   │   ├── plan.md       ← upstream /plan
│   │   ├── build.md      ← upstream /build
│   │   ├── review.md     ← upstream /review
│   │   ├── test.md       ← upstream /test
│   │   ├── ship.md       ← upstream /ship
│   │   ├── webperf.md    ← upstream /webperf
│   │   └── code-simplify.md
│   │
│   │   ── NEW (no upstream equiv, no conflict) ──
│   │   ├── ticket.md     → /ticket     (flat, new)
│   │   ├── tc.md         → /tc         (flat, new)
│   │   ├── spec/full.md  → /spec:full  (subfolder, new)
│   │   ├── plan/full.md  → /plan:full  (subfolder, new)
│   │   ├── impl/full.md  → /impl:full  (subfolder, new) ← Shot 1
│   │   ├── review/full.md→ /review:full(subfolder, new) ← Shot 2
│   │   └── docs/full.md  → /docs:full  (subfolder, new) ← Shot 3
│   │
│   ├── rules/            ← upstream rules
│   └── settings.json     ← updated with pod hooks (minimal delta)
│
├── hooks/                ← upstream hooks — never touch
├── references/           ← upstream references — never touch
├── docs/                 ← upstream docs — never touch
├── scripts/              ← upstream scripts — never touch (add new files only)
│   ├── run-evals.js      ← upstream
│   ├── validate-commands.js ← upstream
│   ├── validate-skills.js   ← upstream
│   └── validate-sc-tags.sh  ← NEW (safe alongside upstream files)
│
└── pod/                  ← ALL custom source lives here
    ├── skills/           ← custom SKILL.md files
    │   ├── ticket-intake/SKILL.md
    │   ├── test-case-engineering/SKILL.md
    │   ├── 3-shot-review/SKILL.md
    │   └── 3-shot-docs/SKILL.md
    ├── agents/           ← custom agent overrides (if any)
    ├── rules/            ← custom CLAUDE.md rule fragments
    │   ├── traceability.md
    │   └── 3-shot-gates.md
    ├── templates/        ← canonical artifact templates
    │   ├── SPEC.md
    │   ├── TC.md
    │   ├── PLAN.md
    │   ├── REVIEW.md
    │   └── BLOCKERS.md
    ├── docs/             ← custom docs (sc-tag-system, harness-install, 3-shot-loop)
    │   ├── sc-tag-system.md
    │   ├── harness-install.md
    │   └── 3-shot-loop.md
    └── MANIFEST.md       ← lists every custom file + upstream merge guide
```

**Merge guide (in MANIFEST.md):** When pulling upstream, only `pod/`, `.claude/commands/ticket.md`, `.claude/commands/tc.md`, `.claude/commands/spec/`, `.claude/commands/plan/`, `.claude/commands/impl/`, `.claude/commands/review/`, `.claude/commands/docs/`, `scripts/validate-sc-tags.sh`, and `.claude/settings.json` belong to us. Everything else comes from upstream.

### 2. Commands reuse upstream skills, `pod/` adds new ones

Command files in `.claude/commands/` invoke skills by name. Custom commands in subfolders reference both upstream skills (`agent-skills:incremental-implementation`, `agent-skills:code-review-and-quality`, etc.) **and** pod skills (`pod/skills/ticket-intake/SKILL.md`). No duplication — skills are referenced, not copied.

### 3. Three fresh sessions, one ticket

- `/impl:full` — Session 1. Reads SPEC+TC+PLAN, implements + commits per story.
- `/review:full` — Session 2. Fresh context; reads code + SPEC; scores /100; writes REVIEW.md.
- `/docs:full` — Session 3. Fresh context; gated on review ≥ 90 + coverage ≥ 85%.

Context rot (slide 54) is prevented by design, not by hope.

### 4. ClickUp + Jira unified intake

`/ticket` auto-detects ticket source from ID format:
- ClickUp: numeric string or URL containing `/t/` → uses `mcp__claude_ai_ClickUp__clickup_get_task`
- Jira: `PROJECT-NNN` key format → uses Atlassian MCP (requires `mcp__claude_ai_Atlassian__authenticate` first session)

### 5. Per-project review weighting

| Dimension | skeleton-be weight | skeleton-fe weight |
|---|---|---|
| Fidelity (SC tags met) | 25 | 25 |
| Type Health | 25 | 25 |
| Coverage | 25 | 25 |
| **BE: Security** / **FE: A11y+Perf** | 25 | 25 |

BE Shot 2 checks OWASP, Passport guards, Prisma parameterized queries, input validation (class-validator).
FE Shot 2 checks WCAG 2.1 AA, unnecessary re-renders, Zod schema ↔ props alignment, TanStack Query cache hygiene.

### 6. BLOCKERS.md accumulates across runs

Each `/impl:full` run appends entries (with timestamp + story ID) rather than resetting. This gives a history of what got blocked and the decisions taken. Resolved entries are marked `[RESOLVED]` manually.

### 7. Gate 1 is always human

SPEC.md `status: draft → approved` requires an unambiguous human affirmative. This is enforced in `/spec:full`, not just documented.

---

## Dependency Graph

```
T01 pod/ structure + MANIFEST
  │
  ├─→ T02 4 artifact templates + SC tag system
  │         │
  │         ├─→ T03 ticket-intake skill + /ticket command
  │         │         │
  │         │         └─→ T04 /spec:full command (9-section SPEC + Gate 1)
  │         │                   │
  │         │                   ├─→ T05 test-case-engineering + /tc
  │         │                   └─→ T06 /plan:full (sc_refs in tasks)
  │         │                             │
  │         │          ┌──────────────────┘
  │         │          ↓
  │         │     CHECKPOINT A ← pipeline: ticket→spec→tc→plan
  │         │          │
  │         │          ├─→ T07 /impl:full — Shot 1 orchestrator
  │         │          │         └─→ T08 fix loop + BLOCKERS.md
  │         │          │
  │         │          ├─→ T09 3-shot-review skill + /review:full — Shot 2
  │         │          │
  │         │          └─→ T10 3-shot-docs skill + /docs:full — Shot 3
  │         │
  │         └─→ T11 SC tag validator (scripts/validate-sc-tags.sh + hook)
  │
  │    CHECKPOINT B ← 3-shot loop end-to-end
  │
  ├─→ T12 skeleton-be CLAUDE.md + .claude/settings.json
  ├─→ T13 skeleton-fe CLAUDE.md + .claude/settings.json
  └─→ T14 Discovery map templates + context-engineering doc

  CHECKPOINT C ← harness installed in both target projects
```

---

## Phase 0: Repo Overlay

### Task T01 — `pod/` Directory Structure + MANIFEST

**Description:** Create the `pod/` directory with all subdirectories and a MANIFEST that documents every custom file and the upstream merge strategy. This is the structural foundation — nothing else is built until this is agreed.

**Acceptance criteria:**
- [ ] `pod/` directory created with subdirs: `skills/`, `agents/`, `rules/`, `templates/`, `docs/`
- [ ] `pod/MANIFEST.md` exists with: list of all custom files (by path), upstream files that must not be modified, and the merge procedure (`git fetch upstream && git merge upstream/main` — expected zero conflicts)
- [ ] `.claude/commands/` new subfolders created (empty, with `.gitkeep`): `spec/`, `plan/`, `impl/`, `review/`, `docs/`
- [ ] `pod/README.md` explains the overlay pattern in 1 page

**Verification:**
- [ ] `git status` on a clean clone shows only new directories/files, no modifications to upstream files
- [ ] Manual review: MANIFEST correctly lists all custom locations

**Dependencies:** None  
**Files:** `pod/MANIFEST.md`, `pod/README.md`, `.claude/commands/spec/.gitkeep`, `.claude/commands/plan/.gitkeep`, `.claude/commands/impl/.gitkeep`, `.claude/commands/review/.gitkeep`, `.claude/commands/docs/.gitkeep`  
**Size:** XS

---

### Task T02 — 4 Artifact Templates + SC Tag System

**Description:** Create the four canonical artifact templates and the SC tag convention doc. These are the shared contracts that all subsequent tasks build on.

**SC tag convention:**
- Format: `SC-NN` (zero-padded two digits: SC-01 … SC-99)
- Assigned once at ticket intake; never renumbered
- Must appear verbatim in SPEC.md §1+§7, TC.md headings, PLAN.md `sc_refs`, REVIEW.md fidelity table

**SPEC.md frontmatter fields** (slide 53):
```yaml
schema_version: 2
artifact_kind: story
clickup_task: ""        # or jira_issue: ""
feature_slug: ""
status: draft           # draft | approved | in_progress | complete
scope: FULL_STACK       # FULL_STACK | BE_ONLY | FE_ONLY
traits: []              # WORKFLOW_DRIVEN | ACCESS_CONTROLLED | ...
approved_mode: manual   # Gate 1 is always manual
```

**SPEC.md body sections §0–§9:**
- §0 Dependencies (models owned/inherited, endpoints)
- §1 Story Summary (required / optional / conditional, SC tags on ACs)
- §2 Prototype Analysis (keep / discard / build fresh)
- §3 Data Model (new fields, Prisma migrations)
- §4 API Contract (FE↔BE binding, `{ success, data }` envelope)
- §5 FE Component Tree (files, props, Zod schema)
- §6 State & Data Flow
- §7 Test Scope (one entry per SC tag, FE/BE unit + e2e)
- §8 Open Questions (each stamped Resolved)
- §9 Docs Found (reused patterns with file:line)

**Acceptance criteria:**
- [ ] `pod/templates/SPEC.md` exists with the YAML frontmatter block and §0–§9 sections, all placeholders marked `{{...}}`
- [ ] `pod/templates/TC.md` exists: `## SC-NN: <AC text>` heading per tag, Given/When/Then blocks, `Verdict: [ ] PASS / [ ] FAIL`
- [ ] `pod/templates/PLAN.md` exists: task blocks with `sc_refs: [SC-NN]`, AC, verification, dependencies, files, size
- [ ] `pod/templates/REVIEW.md` exists: 4-dimension scorecard table (Fidelity/Type Health/Coverage/Security-or-A11y each /25), P0 gate section, SC tag coverage table, verdict block with thresholds
- [ ] `pod/templates/BLOCKERS.md` exists: entry format with timestamp, story ID, SC refs, failure detail, what was attempted, decision needed; `[RESOLVED]` tag convention documented
- [ ] `pod/docs/sc-tag-system.md` documents: format, assignment rules, traceability chain, what happens if a tag is missing

**Verification:**
- [ ] Manual review: SPEC→TC→PLAN→REVIEW cross-references are consistent (same SC tag appears in the right field in each template)
- [ ] REVIEW.md includes separate dimension-4 rubrics for BE (Security) vs FE (A11y+Perf)

**Dependencies:** T01  
**Files:** `pod/templates/SPEC.md`, `pod/templates/TC.md`, `pod/templates/PLAN.md`, `pod/templates/REVIEW.md`, `pod/templates/BLOCKERS.md`, `pod/docs/sc-tag-system.md`  
**Size:** M

---

### Checkpoint: Phase 0

- [ ] `pod/` structure exists with all subdirs
- [ ] All 5 templates exist and are internally consistent
- [ ] SC tag system documented

---

## Phase 1: Ticket Intake

### Task T03 — `ticket-intake` Skill + `/ticket` Command

**Description:** Create the skill and command that reads a ClickUp or Jira ticket, validates AC completeness, enriches sparse tickets, and assigns SC tags. The command auto-detects ticket source from the ID format.

**Source detection:**
- ClickUp: numeric ID, URL containing `/t/`, or `#XXXXXXXX` format → `mcp__claude_ai_ClickUp__clickup_get_task`
- Jira: `PROJECT-NNN` key format → Atlassian MCP (notes if auth required)

**Sparse ticket rule:** AC count < 2, or any AC has no measurable condition → STOP and list which ACs need enrichment. Never derive a spec from a sparse ticket.

**Structured output block** (feeds directly into `/spec:full`):
```markdown
## Ticket: <ID> — <Title>
**Source:** ClickUp | Jira
**Scope:** FE_ONLY | BE_ONLY | FULL_STACK   (from tags)
**Batch:** <batch-tag>

### Acceptance Criteria
- SC-01: <AC text>
- SC-02: <AC text>

### API Spec (if present)
### Data Model (if present)
### Attachments / Wireframes
```

**Acceptance criteria:**
- [ ] `pod/skills/ticket-intake/SKILL.md` exists: Overview, When to Use, Process (detect source → fetch → validate → enrich → assign SC tags → output), Common Rationalizations, Red Flags, Verification
- [ ] `.claude/commands/ticket.md` exists: invokes `pod/skills/ticket-intake/SKILL.md`; accepts ticket ID or URL as `$ARGUMENTS`
- [ ] ClickUp path uses `mcp__claude_ai_ClickUp__clickup_get_task`; Jira path notes Atlassian MCP requirement
- [ ] SC tags assigned in AC order: first AC → SC-01, second → SC-02, etc.
- [ ] Sparse ticket stops with a numbered list of which ACs need enrichment

**Verification:**
- [ ] Manual test (ClickUp): run `/ticket <clickup-id>` → output block with SC tags and scope
- [ ] Manual test (sparse): ticket with vague AC → command stops and lists the gap
- [ ] Jira: `/ticket PROJECT-123` → command detects Jira format, attempts Atlassian MCP

**Dependencies:** T02  
**Files:** `pod/skills/ticket-intake/SKILL.md`, `.claude/commands/ticket.md`  
**Size:** M

---

### Checkpoint: Phase 1

- [ ] `/ticket <id>` produces a SC-tagged requirement block from a real ticket
- [ ] Sparse ticket is caught before spec derivation

---

## Phase 2: Spec Layer

### Task T04 — `/spec:full` Command (9-section SPEC + Gate 1)

**Description:** Create `/spec:full` — the ticket-aware spec command. It takes the output from `/ticket` and generates a SPEC.md using `pod/templates/SPEC.md`. Gate 1 (human approval) is enforced before status can move to `approved`. Upstream `/spec` is untouched and still available for simpler use.

**Gate 1 rule:** Status only moves `draft → approved` on an unambiguous affirmative ("approve", "yes", "go"). Hedged responses ("looks OK", "I guess") are treated as NOT approved.

**Scope guards:** FE_ONLY stories → §3 Data Model and §4 API Contract are marked N/A. BE_ONLY stories → §5 FE Component Tree is N/A.

**Pre-gate check:** §8 Open Questions must have zero unresolved entries before Gate 1 can pass.

**Acceptance criteria:**
- [ ] `.claude/commands/spec/full.md` exists: reads ticket output (from `/ticket`) as input or from `$ARGUMENTS`; generates `SPEC.md` at project root using `pod/templates/SPEC.md`; presents draft to user; waits for Gate 1
- [ ] `clickup_task` or `jira_issue` frontmatter field populated from the ticket ID
- [ ] `scope` field set from ticket tags: `fe` → `FE_ONLY`, `be` → `BE_ONLY`, `fullstack`/absent → `FULL_STACK`
- [ ] Hedged responses do NOT advance `status` to `approved`
- [ ] Spec with unresolved §8 questions cannot be approved (command lists them and stops)
- [ ] Upstream `skills/spec-driven-development/SKILL.md` is referenced (not duplicated) for the general spec process; `/spec:full` adds the 9-section format and Gate 1 on top

**Verification:**
- [ ] Manual test: run `/spec:full` with ticket output → SPEC.md with correct frontmatter, §0–§9, SC tags in §1 and §7
- [ ] Test Gate 1: reply "looks reasonable" → status stays `draft`
- [ ] Test §8 guard: spec with an open question → cannot be approved

**Dependencies:** T03  
**Files:** `.claude/commands/spec/full.md`  
**Size:** M

---

### Checkpoint: Phase 2

- [ ] `/ticket` → `/spec:full` → SPEC.md with SC tags in §1 + §7 and Gate 1 enforced

---

## Phase 3: Test Cases + Plan

### Task T05 — `test-case-engineering` Skill + `/tc` Command

**Description:** Create the skill that derives TC.md from an approved SPEC.md. Each SC tag in §7 Test Scope becomes Given/When/Then blocks in TC.md. Multiple blocks per tag are allowed (happy path + edge cases + error path).

**Acceptance criteria:**
- [ ] `pod/skills/test-case-engineering/SKILL.md` exists: Overview, When to Use, Process (read §7 → one block set per SC tag → validate completeness → save TC.md), Common Rationalizations, Red Flags, Verification
- [ ] `.claude/commands/tc.md` exists: reads `SPEC.md` from project root; errors if `status != approved`; saves `TC.md` using `pod/templates/TC.md`
- [ ] Each SC tag in §7 gets: happy path block + at least one edge-case block + one error-path block
- [ ] `Verdict: [ ] PASS / [ ] FAIL` on each block (filled in during /impl:full)
- [ ] Running `/tc` on a `draft` spec exits with an error

**Verification:**
- [ ] Manual test: `/tc` on approved SPEC.md → TC.md has block sets for every SC tag in §7
- [ ] Verify: `/tc` on `draft` SPEC.md → error, not partial TC.md

**Dependencies:** T04  
**Files:** `pod/skills/test-case-engineering/SKILL.md`, `.claude/commands/tc.md`  
**Size:** M

---

### Task T06 — `/plan:full` Command (PLAN.md with sc_refs)

**Description:** Create `/plan:full` — extends the upstream planning skill with sc_refs per task. Upstream `/plan` is untouched. Every task in PLAN.md must declare which SC tags it satisfies. A coverage check verifies every SC tag is covered before the plan is usable.

**Acceptance criteria:**
- [ ] `.claude/commands/plan/full.md` exists: reads `SPEC.md` + `TC.md`; errors if spec `status != approved`; saves `PLAN.md` using `pod/templates/PLAN.md`; runs coverage check
- [ ] Every PLAN.md task block has `sc_refs: [SC-NN, ...]`
- [ ] Coverage check: after generating PLAN.md, lists any SC tags with zero assigned tasks (must be zero)
- [ ] Plan presented to user before it is treated as active
- [ ] References upstream `agent-skills:planning-and-task-breakdown` for vertical slicing and task sizing

**Verification:**
- [ ] Manual test: `/plan:full` on approved SPEC.md + TC.md with 4 SC tags → PLAN.md where all 4 appear in at least one task
- [ ] Verify: PLAN.md generated without TC.md present → error

**Dependencies:** T05  
**Files:** `.claude/commands/plan/full.md`  
**Size:** S

---

### Checkpoint A: Ticket → Spec → TC → Plan Pipeline ← HUMAN REVIEW

- [ ] Full pipeline runnable: `/ticket` → `/spec:full` (Gate 1) → `/tc` → `/plan:full`
- [ ] SPEC.md, TC.md, PLAN.md exist with consistent SC tags throughout
- [ ] Every SC tag from the ticket appears in all three artifacts
- [ ] **Human reviews and approves plan before Phase 4**

---

## Phase 4: Shot 1 — Implementation

### Task T07 — `/impl:full` Command (Shot 1 Orchestrator)

**Description:** Create `/impl:full` — Shot 1. Reads SPEC+TC+PLAN and runs the per-story implementation loop. Extends upstream `incremental-implementation` and `test-driven-development` skills; does not duplicate them.

**Pre-flight checks:**
1. `SPEC.md` exists and `status == approved`
2. `TC.md` exists
3. `PLAN.md` exists
4. `git status --porcelain` is clean (no uncommitted changes outside planning artifacts)

**Per-story loop** (for each pending task in PLAN.md):
1. Load just-in-time context: only spec sections relevant to task's `sc_refs` (not the whole SPEC.md)
2. Load discovery map for each module touched (from `pod/` if available)
3. Run TC entries for this task's `sc_refs` (RED — tests should fail)
4. Implement BE (if scope includes BE): NestJS module → CQRS handler → Prisma → Swagger decorator → nestjs-pino log
5. Implement FE (if scope includes FE): Zod schema → component → TanStack Query hook → Zustand slice (if needed) → i18n key → Storybook story
6. Run tests: `npx jest` (BE) or `npx vitest run` (FE) → typecheck → lint
7. Fix loop (T08) if failures
8. Update TC.md verdicts for this task's SC tags
9. Commit: `feat(<story-id>): <task-title> [SC-01, SC-02]`
10. Mark task `complete` in PLAN.md

**Scope guards:**
- `FE_ONLY`: skip steps 4 (BE)
- `BE_ONLY`: skip step 5 (FE)

**Acceptance criteria:**
- [ ] `.claude/commands/impl/full.md` exists: documents pre-flight, per-story loop, scope guards, commit format, `--auto` mode
- [ ] Pre-flight stops with specific error if any check fails
- [ ] Each story produces one atomic commit (never `git add -A`; stages only files the task touched)
- [ ] BE test command: `npx jest` / `npx jest --testPathPattern=<module>`
- [ ] FE test command: `npx vitest run` / `npx vitest run --reporter=verbose`
- [ ] `--auto` flag: human approves plan once, then all tasks run autonomously; pauses on blockers
- [ ] Single-task mode (no `--auto`): implements next pending task, then stops
- [ ] References upstream `agent-skills:incremental-implementation` + `agent-skills:test-driven-development` (not duplicated)

**Verification:**
- [ ] Manual test: single-task mode → implements task 1, commits with SC refs in message, stops
- [ ] Verify: pre-flight fails cleanly if SPEC.md `status = draft`
- [ ] Verify: `BE_ONLY` scope → no FE files touched

**Dependencies:** T06  
**Files:** `.claude/commands/impl/full.md`  
**Size:** M

---

### Task T08 — Fix Loop + BLOCKERS.md

**Description:** Define the fix-loop behaviour that runs when tests/build fail inside Shot 1. Never kills the batch — writes BLOCKERS.md and advances to the next story.

**Fix loop:**
1. On failure: read structured error output; attempt fix (targeted, not a rewrite)
2. Re-run the same test command
3. Max 3 iterations; if still failing → write BLOCKERS.md entry → mark task `blocked` in PLAN.md → continue to next story
4. At run end: if BLOCKERS.md has entries → set run status `PARTIAL` → surface the file to the user

**BLOCKERS.md entry format** (from `pod/templates/BLOCKERS.md`):
```
### BLOCKER: <task-title> — <timestamp>
**Story:** <story-id>  **SC refs:** SC-01, SC-02
**Failed:** <test name or build step>
**Error:** <structured error, not prose>
**Attempted:** <what the fix loop tried>
**Decision needed:** <what the human must decide>
**Status:** [ ] OPEN  [ ] RESOLVED
```

**Acceptance criteria:**
- [ ] `pod/rules/3-shot-gates.md` updated (or created): documents fix loop max iterations, BLOCKERS.md path, `PARTIAL` run status
- [ ] `.claude/commands/impl/full.md` updated to reference fix loop behaviour
- [ ] Fix loop max iterations is configurable via `IMPL_FIX_MAX_ITER` env var (default: 3)
- [ ] A blocked task is marked `blocked` in PLAN.md (not `complete`, not silently skipped)
- [ ] BLOCKERS.md appends entries across runs (never resets); resolved entries marked `[RESOLVED]`

**Verification:**
- [ ] Manual test: break a test intentionally → fix loop runs ≤ 3 times → BLOCKERS.md entry written → next story continues
- [ ] Verify: PLAN.md marks blocked story as `blocked`, not `complete`
- [ ] Verify: second `/impl:full` run appends to BLOCKERS.md, does not overwrite it

**Dependencies:** T07  
**Files:** `pod/rules/3-shot-gates.md`, `.claude/commands/impl/full.md` (update)  
**Size:** S

---

### Checkpoint B-1: Shot 1

- [ ] `/impl:full` runs a full per-story loop on a sample PLAN.md
- [ ] Fix loop triggers on failure, writes BLOCKERS.md, continues
- [ ] Each story produces an individual commit with SC refs
- [ ] `--auto` runs all tasks without stopping between them

---

## Phase 5: Shot 2 — Review

### Task T09 — `3-shot-review` Skill + `/review:full` Command

**Description:** Shot 2. 4-dimension /100 audit in a fresh session. Extends the upstream `/review` and `code-review-and-quality` skill with structured scoring; does not replace them.

**Scoring rubric:**

| Dimension | BE (25 pts) | FE (25 pts) |
|---|---|---|
| **Fidelity** | Each SC tag in SPEC.md §7 verified in code. 25/N pts per tag. | Same |
| **Type Health** | TS strict compile + no untyped `any` + class-validator DTOs match §4 contract | TS strict + Zod schemas match §5 props + no `any` |
| **Coverage** | `npx jest --coverage` ≥ 85% on changed files + TC.md verdicts filled | `npx vitest run --coverage` ≥ 85% on changed files + TC.md verdicts filled |
| **Security (BE) / A11y+Perf (FE)** | OWASP Top 10, Passport guards on all endpoints, Prisma parameterized queries, class-validator on all DTOs, no secrets in logs | WCAG 2.1 AA, keyboard nav, no unnecessary re-renders, TanStack Query stale-time set, Sentry boundaries |

**P0 trait gates** (override verdict regardless of score):
- `ACCESS_CONTROLLED`: every NestJS endpoint has `@UseGuards(JwtAuthGuard)` + `@Roles(...)` → FE equivalent: oidc-client protected routes
- `WORKFLOW_DRIVEN`: all state transitions tested in TC.md and covered by tests

**Verdict thresholds:**
- ≥ 90: **APPROVE** — proceed to `/docs:full`
- 75–89: **MINOR** — fix listed issues; may proceed to docs after fixes; re-run review
- 60–74: **REWORK** — return to `/impl:full`
- < 60 or P0 gate fail: **BLOCK** — significant rework; human must review before any next step

**Fan-out:** `/review:full` spawns the upstream `code-reviewer`, `security-auditor`, and `test-engineer` personas in parallel (same pattern as upstream `/ship`), then applies the scoring rubric to their outputs. No new agents needed.

**Acceptance criteria:**
- [ ] `pod/skills/3-shot-review/SKILL.md` exists: 4-dimension rubric with BE/FE variants, P0 gate definitions, verdict thresholds, fresh-session requirement
- [ ] `.claude/commands/review/full.md` exists: documents fresh-session requirement, spawns 3 upstream agents in parallel, applies rubric, writes `REVIEW.md` using `pod/templates/REVIEW.md`
- [ ] `REVIEW.md` includes: per-dimension score + breakdown, SC tag coverage table (each tag: AC text, verified Y/N, notes), P0 gate results, verdict, rework instructions
- [ ] Fidelity score: computed per SC tag (partial credit for partially-met ACs)
- [ ] P0 gate fail → verdict `BLOCK` regardless of numeric score
- [ ] `/review:full` is independent of `/review` (upstream command unchanged)

**Verification:**
- [ ] Manual test: `/review:full` on a completed impl → REVIEW.md with all 4 scores and SC tag table
- [ ] Verify: P0 gate failure with score 91 → verdict is `BLOCK`, not APPROVE
- [ ] Verify: all SC tags from SPEC.md §7 appear in the coverage table

**Dependencies:** T07, T02  
**Files:** `pod/skills/3-shot-review/SKILL.md`, `.claude/commands/review/full.md`  
**Size:** L

---

### Checkpoint B-2: Shot 2

- [ ] `/review:full` produces a scored REVIEW.md
- [ ] P0 gates enforced
- [ ] Verdict correctly gates progression to Shot 3

---

## Phase 6: Shot 3 — Docs

### Task T10 — `3-shot-docs` Skill + `/docs:full` Command

**Description:** Shot 3. Doc generation gated on `review ≥ 90` AND `coverage ≥ 85%` on changed files. Runs in a fresh session after Shot 2.

**Gate checks (in order):**
1. Read `REVIEW.md` → if verdict is `REWORK` or `BLOCK` → stop with message ("Run /review:full first; current verdict is REWORK")
2. Check coverage report (Jest/Vitest JSON output) → if changed-file coverage < 85% → stop
3. Proceed to doc generation

**Outputs:**
- **README.md** — updated project README covering the feature (what it does, how to use it)
- **ARCHITECTURE.md** — ADR-style record of design decisions from §2 (Prototype Analysis) and §3 (Data Model); keyed by story ID
- **API_SPEC.md** (BE scope): derived from §4 API Contract, updated to reflect actual implementation; NestJS Swagger format
- **COMPONENT_SPEC.md** (FE scope): derived from §5 Component Tree, actual prop types, Storybook links

**Acceptance criteria:**
- [ ] `pod/skills/3-shot-docs/SKILL.md` exists: gate check process, output docs per scope, fresh-session requirement
- [ ] `.claude/commands/docs/full.md` exists: performs both gate checks before generating; documents fresh-session requirement; generates docs from implemented code + SPEC.md (not from chat history)
- [ ] `REWORK` or `BLOCK` verdict → command stops with actionable message
- [ ] Coverage < 85% → command stops with the coverage report and which files are under threshold
- [ ] `ARCHITECTURE.md` always references decisions from §2 and §3 of SPEC.md
- [ ] Docs generated reflect actual code, not the spec's intent (reads the implementation)

**Verification:**
- [ ] Manual test: `/docs:full` with APPROVE verdict + 90% coverage → 3–4 docs generated
- [ ] Verify: `REWORK` verdict → command stops, no docs generated
- [ ] Verify: `ARCHITECTURE.md` references §2 Prototype Analysis decisions

**Dependencies:** T09, T04  
**Files:** `pod/skills/3-shot-docs/SKILL.md`, `.claude/commands/docs/full.md`  
**Size:** M

---

### Checkpoint B: Full 3-Shot Loop ← HUMAN REVIEW

- [ ] `/ticket` → `/spec:full` → `/tc` → `/plan:full` → `/impl:full` → `/review:full` → `/docs:full` runs end-to-end
- [ ] Gates enforced: Gate 1 (human), Shot 2→3 (score + coverage)
- [ ] All artifacts produced per story
- [ ] **Human reviews before Phase 7**

---

## Phase 7: Traceability Enforcement

### Task T11 — SC Tag Validator + Pre-Impl Hook

**Description:** Mechanical gate that checks SC tag consistency across all 4 artifacts. Wired as a Claude Code hook so it fires automatically before impl starts.

**Validation rules:**
1. Every SC tag assigned in ticket output must appear in SPEC.md §1 and §7
2. Every SC tag in SPEC.md §7 must have ≥ 1 Given/When/Then block in TC.md
3. Every SC tag must appear in at least one task's `sc_refs` in PLAN.md
4. Post-review: every SC tag must appear in REVIEW.md SC coverage table

**Script output (exit 1 on gap):**
```
SC Tag Coverage Report
────────────────────────────────────
Tag    SPEC§1  SPEC§7  TC      PLAN
SC-01  ✓       ✓       ✓       ✓
SC-02  ✓       ✓       ✗       ✓   ← MISSING TC BLOCK
SC-03  ✓       ✗       ✗       ✗   ← MISSING FROM §7, TC, PLAN
────────────────────────────────────
2 gaps found. Fix before proceeding.
```

**Acceptance criteria:**
- [ ] `scripts/validate-sc-tags.sh` exists: accepts `--spec SPEC.md --tc TC.md --plan PLAN.md`; outputs the coverage table; exits 0 if clean, 1 with gaps listed
- [ ] `.claude/settings.json` updated: `PreToolUse` hook fires `validate-sc-tags.sh` before any write to `PLAN.md`; non-zero exit blocks the write and surfaces the gap table
- [ ] Pre-flight in `/impl:full` (T07) also calls `validate-sc-tags.sh` explicitly
- [ ] Script handles missing files gracefully (reports which file is absent, exits 1)
- [ ] Script works on Windows (PowerShell-compatible) and Unix (bash)

**Verification:**
- [ ] Test: PLAN.md missing SC-02 in all `sc_refs` → validator exits 1, SC-02 row shows ✗ in PLAN column
- [ ] Test: all consistent → exits 0
- [ ] Verify: Claude Code hook fires and blocks a PLAN.md write when validator fails

**Dependencies:** T06, T08  
**Files:** `scripts/validate-sc-tags.sh`, `.claude/settings.json` (minimal update — add hook)  
**Size:** S

---

### Checkpoint: Phase 7

- [ ] Validator catches any missing SC tag across all 4 artifacts
- [ ] Hook fires and blocks a bad PLAN.md write in a live session

---

## Phase 8: Project Harness

### Task T12 — skeleton-be CLAUDE.md + settings.json

**Description:** Project-specific rules file and settings for skeleton-be. Tells Claude the stack, overrides the upstream npm-generic commands with NestJS-specific ones, and wires the traceability hook.

**Acceptance criteria:**
- [ ] `skeleton-be/CLAUDE.md` covers:
  - Project: NestJS 11 + CQRS + Prisma 7 + PostgreSQL
  - Test commands: `npx jest`, `npx jest --testPathPattern=<module>`, `npx jest --coverage`
  - Build: `npx nest build`
  - Lint: `npx eslint src/`
  - Migrate: `npx prisma migrate dev`
  - Architecture rules: new feature = new NestJS module; CQRS handlers in `commands/` + `queries/`; never raw SQL (use Prisma)
  - Security rules: every endpoint must have `@UseGuards(JwtAuthGuard)`; DTOs must use class-validator; no secrets in logs (nestjs-pino)
  - Primary skills: `api-and-interface-design`, `security-and-hardening`, `observability-and-instrumentation`
  - Test file patterns: `**/*.spec.ts` (unit), `**/*.e2e-spec.ts` (e2e)
  - Explicitly overrides: "Use `npx jest` not `npm test`"
- [ ] `skeleton-be/.claude/settings.json`: read/write auto; destructive actions (push, delete, migrate reset) require approval; hook wires `validate-sc-tags.sh`

**Verification:**
- [ ] Manual review: tech lead reads CLAUDE.md and confirms it matches the actual skeleton-be codebase
- [ ] Verify: Claude Code session opened in skeleton-be with plugin → reads CLAUDE.md correctly

**Dependencies:** T11  
**Files:** `skeleton-be/CLAUDE.md`, `skeleton-be/.claude/settings.json` (created in the target project)  
**Size:** S

---

### Task T13 — skeleton-fe CLAUDE.md + settings.json

**Description:** Same as T12 for skeleton-fe.

**Acceptance criteria:**
- [ ] `skeleton-fe/CLAUDE.md` covers:
  - Project: React 19 + Vite 6 + TypeScript 5.7 + Tailwind 4 + shadcn/ui
  - Test commands: `npx vitest run`, `npx vitest run --coverage`, `npx playwright test`
  - Build: `npm run build`
  - Lint: `npx eslint src/`
  - Dev: `npm run dev`
  - Architecture rules: Zod 4 schemas are source of truth for props (match SPEC.md §5); components in `src/features/<name>/`; TanStack Query for server state (no manual fetch); Zustand only for UI state
  - A11y rules: WCAG 2.1 AA; every interactive element must be keyboard-accessible; use `<button>` not `<div onClick>`
  - i18n rules: all user-visible strings via i18next keys; no hardcoded English in JSX
  - Primary skills: `frontend-ui-engineering`, `browser-testing-with-devtools`, `performance-optimization`
  - Storybook: every new component gets a story
  - Test file patterns: `**/*.test.tsx`, `**/*.spec.tsx`, `tests/**/*.spec.ts` (Playwright)
- [ ] `skeleton-fe/.claude/settings.json`: mirrors T12 pattern

**Verification:**
- [ ] Manual review: tech lead reads CLAUDE.md and confirms it matches the actual skeleton-fe codebase

**Dependencies:** T11  
**Files:** `skeleton-fe/CLAUDE.md`, `skeleton-fe/.claude/settings.json`  
**Size:** S

---

### Task T14 — Discovery Map Templates + Context Engineering

**Description:** Create the discovery map template and the context engineering guide so `/impl:full` knows how to load just-in-time context per story — preventing context rot on large implementations.

**Discovery map format** (one per BE module, one per FE feature area):
```markdown
# Discovery: <module-or-feature>

## Entry points
- `src/modules/auth/auth.controller.ts` — NestJS controller (HTTP layer)
- `src/modules/auth/auth.service.ts` — business logic

## Shared dependencies
- `src/common/guards/jwt.guard.ts`
- `src/shared/types/user.types.ts`

## Prisma models (BE) / Zod schemas (FE)
- `prisma/schema.prisma#User`

## Tests
- `src/modules/auth/auth.service.spec.ts` — unit
- `test/auth.e2e-spec.ts` — e2e

## Spec refs
- `SPEC.md §4` — API Contract (auth endpoints)

## Do not load (noise for this module)
- `src/modules/billing/**`
```

**Acceptance criteria:**
- [ ] `pod/templates/discovery-map.md` exists with BE and FE variants and `{{...}}` placeholders
- [ ] `pod/docs/context-engineering.md` updated: explains just-in-time loading, how `/impl:full` uses discovery maps (load only maps for current story's `sc_refs`), how to create a map per module, pointer to `pod/templates/discovery-map.md`
- [ ] `/impl:full` command references discovery maps in its per-story loop: "Load the discovery map for each module touched by this task before implementing"

**Verification:**
- [ ] Manual review: template covers both BE (Prisma/NestJS) and FE (Zod/React) conventions

**Dependencies:** T07  
**Files:** `pod/templates/discovery-map.md`, `pod/docs/context-engineering.md`  
**Size:** S

---

### Checkpoint C: Harness Installable ← HUMAN REVIEW

- [ ] Plugin installed in skeleton-be: `claude --plugin-dir /path/to/fork`; CLAUDE.md loaded; all `/ticket`, `/spec:full`, `/tc`, `/plan:full`, `/impl:full`, `/review:full`, `/docs:full` commands available
- [ ] Plugin installed in skeleton-fe: same; FE-specific CLAUDE.md loaded
- [ ] Full pipeline runs on a real story in one of the target projects
- [ ] SC tag validator enforces traceability end-to-end
- [ ] **Human sign-off before treating harness as production-ready**

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| ClickUp MCP field names differ from expected | High | T03: test against a real ClickUp task before building /spec:full on top |
| Atlassian MCP requires interactive auth each session | Med | `/ticket` documents the auth-first step for Jira tickets; include in harness-install.md |
| `/review:full` self-scores (oracle collapse) | High | T09: fan-out to 3 upstream agents in parallel; score computed from structured sub-scores per SC tag, not model's prose; fresh session enforced |
| Context rot in `/impl:full --auto` on multi-story batches | Med | T14: discovery maps scope context per module; each story's context pruned before the next |
| upstream `agent-skills` adds `ticket.md` or `tc.md` to `.claude/commands/` | Low | MANIFEST.md documents which flat files are ours; monitor upstream PRs |
| Coverage reporter output format differs between projects | Med | T12/T13: pin the specific coverage JSON path in CLAUDE.md for each project |
| Zod v4 API is different from v3 | Med | T13: CLAUDE.md calls out "Zod 4 — use `z.string().min(1)` not `z.string().nonempty()`" |

---

## Open Questions — All Resolved

| # | Question | Resolution |
|---|---|---|
| 1 | skeleton-be stack | NestJS 11 + Prisma 7 + PostgreSQL + Jest 30 (T12) |
| 2 | skeleton-fe stack | React 19 + Vite 6 + Vitest 3 + Playwright + shadcn/ui (T13) |
| 3 | ClickUp only or Jira too? | Both — auto-detect from ticket ID format (T03) |
| 4 | Review weights equal? | Equal 25/25/25/25; dimension 4 differs: BE=Security, FE=A11y+Perf (T09) |
| 5 | Coverage tool | BE: Jest JSON (`--coverage --coverageReporters=json`); FE: Vitest JSON (T10) |
| 6 | BLOCKERS.md reset or accumulate? | Accumulate across runs; resolved entries marked `[RESOLVED]` (T08) |
