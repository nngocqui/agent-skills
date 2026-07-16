# Task List: Custom AI-SDLC Harness

> Full plan: `tasks/plan.md`
> Pipeline: `/ticket` → `/spec:full` → `/tc` → `/plan:full` → `/impl:full` → `/review:full` → `/docs:full`

---

## Phase 0: Repo Overlay

- [x] **T01** `pod/` directory structure + `MANIFEST.md` + empty command subfolders (`spec/` `plan/` `impl/` `review/` `docs/`) · _None_ · XS
- [x] **T02** 4 artifact templates (`SPEC.md` `TC.md` `PLAN.md` `REVIEW.md` `BLOCKERS.md`) + SC tag system doc · _T01_ · M

### ✓ Checkpoint 0
- [ ] `pod/` exists with all subdirs · All 5 templates consistent · SC tag system documented

---

## Phase 1: Ticket Intake

- [x] **T03** `pod/skills/ticket-intake/SKILL.md` + `.claude/commands/ticket.md` (ClickUp + Jira auto-detect, AC validation, SC tag assignment) · _T02_ · M

### ✓ Checkpoint 1
- [ ] `/ticket <id>` produces SC-tagged requirement block · Sparse ticket caught before spec

---

## Phase 2: Spec Layer

- [x] **T04** `.claude/commands/spec/full.md` (9-section SPEC.md, frontmatter, Gate 1 human approval, scope guards) · _T03_ · M

### ✓ Checkpoint 2
- [ ] `/ticket` → `/spec:full` → SPEC.md with SC tags in §1 + §7 · Gate 1 enforced

---

## Phase 3: TC + Plan

- [x] **T05** `pod/skills/test-case-engineering/SKILL.md` + `.claude/commands/tc.md` (Given/When/Then per SC tag, rejects draft spec) · _T04_ · M
- [x] **T06** `.claude/commands/plan/full.md` (PLAN.md with `sc_refs` per task, coverage check) · _T05_ · S

### ✓ Checkpoint A — HUMAN REVIEW REQUIRED
- [ ] Full pipeline runnable: `/ticket` → `/spec:full` (Gate 1) → `/tc` → `/plan:full`
- [ ] SPEC.md · TC.md · PLAN.md have consistent SC tags throughout
- [ ] **Human approves plan before Phase 4**

---

## Phase 4: Shot 1 — Implementation

- [x] **T07** `.claude/commands/impl/full.md` — Shot 1 orchestrator (pre-flight · classify · per-story loop · scope guards · commits with SC refs in message · `--auto` mode) · _T06_ · M
- [x] **T08** Fix loop + BLOCKERS.md (`pod/rules/3-shot-gates.md` · max-iter · append-not-reset · `blocked` status in PLAN.md) · _T07_ · S

### ✓ Checkpoint B-1: Shot 1
- [ ] `/impl:full` per-story loop works on a sample PLAN.md
- [ ] Fix loop writes BLOCKERS.md and continues · Individual commits per story with SC refs

---

## Phase 5: Shot 2 — Review

- [x] **T09** `pod/skills/3-shot-review/SKILL.md` + `.claude/commands/review/full.md` — Shot 2 (4D /100 · P0 gates · REVIEW.md · BE=Security / FE=A11y+Perf · fresh session · fan-out to 3 upstream agents) · _T07, T02_ · L

### ✓ Checkpoint B-2: Shot 2
- [ ] `/review:full` → REVIEW.md with 4 scores + SC tag coverage table · P0 gates enforced · Verdict gates /docs:full

---

## Phase 6: Shot 3 — Docs

- [x] **T10** `pod/skills/3-shot-docs/SKILL.md` + `.claude/commands/docs/full.md` — Shot 3 (gated: review ≥ 90 AND coverage ≥ 85% · README + ARCHITECTURE + API_SPEC or COMPONENT_SPEC · fresh session) · _T09, T04_ · M

### ✓ Checkpoint B: Full 3-Shot Loop — HUMAN REVIEW REQUIRED
- [ ] End-to-end: `/ticket` → `/spec:full` → `/tc` → `/plan:full` → `/impl:full` → `/review:full` → `/docs:full`
- [ ] All gates enforced · All artifacts produced
- [ ] **Human reviews before Phase 7**

---

## Phase 7: Traceability Enforcement

- [x] **T11** `scripts/validate-sc-tags.sh` + `.claude/settings.json` hook (PreToolUse on PLAN.md write · coverage table output · exit 1 on gap · cross-platform) · _T06, T08_ · S

### ✓ Checkpoint 7
- [ ] Validator catches any missing SC tag · Hook blocks a bad PLAN.md write in a live session

---

## Phase 8: Project Harness

- [x] **T12** `skeleton-be/CLAUDE.md` + `skeleton-be/.claude/settings.json` (NestJS/Prisma/Jest stack rules · security rules · skill refs) · _T11_ · S
- [x] **T13** `skeleton-fe/CLAUDE.md` + `skeleton-fe/.claude/settings.json` (React 19/Vite/Vitest/Playwright · Zod 4 notes · a11y rules · i18n rules · skill refs) · _T11_ · S
- [x] **T14** `pod/templates/discovery-map.md` (BE + FE variants) + `pod/docs/context-engineering.md` · _T07_ · S

### ✓ Checkpoint C: Harness Installable — HUMAN SIGN-OFF
- [ ] Plugin runs in skeleton-be and skeleton-fe · All 7 commands available · Full pipeline on a real story
- [ ] SC tag validator enforces traceability end-to-end
- [ ] **Human sign-off before production use**

---

## Quick Reference: Command Map

| Command | File | Shot | Upstream reuse |
|---|---|---|---|
| `/ticket` | `.claude/commands/ticket.md` | — | ClickUp + Jira MCP |
| `/spec:full` | `.claude/commands/spec/full.md` | — | `agent-skills:spec-driven-development` |
| `/tc` | `.claude/commands/tc.md` | — | new (`pod/skills/test-case-engineering`) |
| `/plan:full` | `.claude/commands/plan/full.md` | — | `agent-skills:planning-and-task-breakdown` |
| `/impl:full` | `.claude/commands/impl/full.md` | **1** | `agent-skills:incremental-implementation` + `test-driven-development` |
| `/review:full` | `.claude/commands/review/full.md` | **2** | `code-reviewer` + `security-auditor` + `test-engineer` (fan-out) |
| `/docs:full` | `.claude/commands/docs/full.md` | **3** | new (`pod/skills/3-shot-docs`) |

## Upstream commands still available (untouched)
`/spec` · `/plan` · `/build` · `/review` · `/test` · `/ship` · `/webperf` · `/code-simplify`
