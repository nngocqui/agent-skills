---
description: Shot 1 — implement every task in PLAN.md with a per-story TDD loop, fix loop on failure, and individual commits. Reads SPEC.md + TC.md + PLAN.md. Run in its own session.
---

Invoke `agent-skills:incremental-implementation` and `agent-skills:test-driven-development` alongside `pod/rules/3-shot-gates.md`.

## Session rule

Run `/impl:full` in a **fresh Claude Code session**. Do not run it in the same session as `/review:full` or `/docs:full`. This prevents context rot across shots.

## Modes

- **`/impl:full`** — implement the next pending task, then stop.
- **`/impl:full --auto`** — human approves the plan once at the start, then all tasks run autonomously. Pauses on blockers.

`$ARGUMENTS` selects the mode. `--auto` or `auto` = autonomous. Anything else or empty = single-task.

---

## Pre-flight (always runs first)

1. **SPEC.md check:** read `SPEC.md` from project root. Require `status: approved`. If not: "Stop — SPEC.md status is `{{status}}`. Run `/spec:full` and get Gate 1 approval."
2. **TC.md check:** `TC.md` must exist. If not: "Stop — TC.md missing. Run `/tc` first."
3. **PLAN.md check:** `PLAN.md` must exist. If not: "Stop — PLAN.md missing. Run `/plan:full` first."
4. **SC tag validator:** run `bash scripts/validate-sc-tags.sh --spec SPEC.md --tc TC.md --plan PLAN.md`. If exit 1: show the gap table and stop.
5. **Git baseline:** run `git status --porcelain`. If uncommitted changes exist outside `SPEC.md`, `TC.md`, `PLAN.md`, `BLOCKERS.md`: "Stop — uncommitted changes detected. Commit or stash first."
6. **Classify traits:** read `traits` from SPEC.md frontmatter. Note active trait guards (see Trait Guards below).

If all checks pass: "Pre-flight OK. Scope: {{scope}}. Tasks pending: {{N}}."

---

## Single-task mode (default)

1. Find the next task in PLAN.md with `Status: pending`
2. Run the per-story loop (see below)
3. Stop after committing that task

---

## Autonomous mode (`--auto`)

1. Pre-flight (above)
2. Show the full task list from PLAN.md
3. Wait for an unambiguous human affirmative ("approve" / "go" / "yes"). Treat "looks good" or "I guess" as NOT approved.
4. Run every pending task in dependency order using the per-story loop
5. Pause and ask the human only when:
   - A blocker cannot be resolved in the fix loop (max 3 iterations)
   - A task touches auth/payments/migrations/destructive operations
   - The spec is ambiguous for the current task
6. After the human resolves a blocker: resume from the next pending task

---

## Per-story loop

For each task:

### A. Load just-in-time context

Load ONLY what this task needs:
- The SPEC.md sections referenced by the task's `sc_refs` (not the whole spec)
- The TC.md blocks for the task's `sc_refs`
- The discovery map for each module/feature touched (from `pod/` if it exists)
- Existing code files listed in the task's "Files likely touched"

Do NOT load: unrelated modules, the full spec, the full TC.md, other stories' plan tasks.

### B. Write failing tests first (RED)

For each TC.md block assigned to this task's `sc_refs`, write every applicable test type before writing any implementation code.

**BE — write both:**
1. **Unit spec** (`src/{{module}}/{{file}}.spec.ts`) — test the service/handler in isolation using `@nestjs/testing`. Mock repository interfaces at the module boundary.
2. **E2E spec** (`test/{{module}}.e2e-spec.ts`) — add a Supertest case for every new or modified HTTP endpoint (happy path + at least one error path). Create the file if it doesn't exist.

**FE — write all three:**
1. **Component test** (`src/features/{{feature}}/components/{{name}}.test.tsx`) — Vitest + Testing Library + MSW. Test rendering, user events, loading/error states.
2. **Story** (`src/features/{{feature}}/components/{{name}}.stories.tsx`) — one story per component state. Required for every new component, no exceptions.
3. **E2E spec** (`e2e/{{feature}}.spec.ts`) — Playwright scenario for every new page/route. Add to existing spec file if feature already has one.

**Run the unit test (RED check):**
- BE: `npx vitest run --reporter=verbose src/{{module}}/{{file}}.spec.ts`
- FE: `npx vitest run --reporter=verbose src/features/{{feature}}/components/{{name}}.test.tsx`

The unit test must FAIL before implementation begins. If it passes: the test is testing nothing — rewrite it. (E2E tests are not run in RED — they require the running app.)

### C. Implement (scope-guarded)

Follow `agent-skills:incremental-implementation` rules:
- One logical thing at a time; never `git add -A`
- Touch only files in the task's "Files likely touched" list

**BE implementation** (skip for FE_ONLY):
1. Prisma schema change → run `npx prisma migrate dev --name {{migration-name}}`
2. DTO with class-validator decorators (matches §4 API Contract)
3. CQRS command/query handler in `src/modules/{{module}}/commands/` or `queries/`
4. Service method
5. NestJS controller endpoint with `@UseGuards(JwtAuthGuard)` + `@Roles(...)` if `ACCESS_CONTROLLED` trait
6. Swagger `@ApiOperation`, `@ApiResponse` decorators
7. nestjs-pino log at entry and exit of service method

**FE implementation** (skip for BE_ONLY):

Before writing any hook or API call: **check `src/api/generated/` first.**
If the endpoint is already covered by an orval-generated hook, import it. Only write a custom hook in `src/features/{{feature}}/hooks/` when you need to compose or enrich the generated one. If `openapi.json` is stale, run `pnpm gen:spec` in skeleton-be then `pnpm gen:api` in skeleton-fe before proceeding.

1. Zod schema in `src/features/{{feature}}/schemas/{{feature}}.schema.ts` (form validation shape — separate from generated DTO types)
2. TanStack Query hook in `src/features/{{feature}}/hooks/use{{Feature}}.ts` — wraps the generated hook if one exists; otherwise hand-writes using `src/api/axios-instance.ts`
3. Zustand slice update in `src/features/{{feature}}/store/` (only if UI state needed)
4. Component in `src/features/{{feature}}/components/` — props typed from Zod schema or generated model types
5. i18n keys added to `src/locales/` for all user-visible strings
6. Storybook story created alongside the component
7. Sentry error boundary if this is a new route/page

### D. Run tests (GREEN + regression)

Run every applicable test type. All must pass before committing.

**BE:**
1. Unit (new): `npx vitest run src/{{module}}/{{file}}.spec.ts` — must PASS
2. Unit (regression): `npx vitest run` — full unit suite
3. E2E (if endpoint task): `npx vitest run --config vitest.e2e.config.ts` — requires DB running
4. Type-check: `npx tsc --noEmit`
5. Lint: `npx eslint src/`

**FE:**
1. Component (new): `npx vitest run src/features/{{feature}}/components/{{name}}.test.tsx` — must PASS
2. Unit (regression): `npx vitest run` — full unit + storybook suite
3. E2E (if page/route task): `npx playwright test e2e/{{feature}}.spec.ts` — requires dev server running (`pnpm dev`)
4. Type-check: `npx tsc -b --noEmit`
5. Lint: `npx eslint src/`

If any step fails → **Fix loop** (see below).

### E. Update TC.md verdicts

For each test block that passed, mark `Verdict: [x] PASS`.

### F. Mark complete

In PLAN.md, set `Status: complete` for this task.

### G. Commit

Stage ONLY files touched by this task plus TC.md and PLAN.md (now updated to `complete`):
```bash
git add <specific files> TC.md PLAN.md
git commit -m "feat({{feature-slug}}): {{task title}} [SC-01, SC-02]"
```

Never `git add -A`. Never `git add .`. Stage by name.

---

## Fix loop

When tests or build fail after implementation:

```
Attempt 1/3: read the structured error, make a targeted fix, re-run
Attempt 2/3: if still failing, take a different approach
Attempt 3/3: if still failing → write BLOCKERS.md entry
```

**Max iterations:** 3 (configurable via `IMPL_FIX_MAX_ITER` env var, default 3).

**On max-iteration failure:**
1. Append an entry to `BLOCKERS.md` using `pod/templates/BLOCKERS.md` format
2. Mark the task `Status: blocked` in PLAN.md (not `complete`, not deleted)
3. Continue to the next pending task (never kill the batch)

**At run end:** if BLOCKERS.md has OPEN entries, surface the file and set run status `PARTIAL`.

---

## Trait guards

| Trait | Additional requirement |
|-------|----------------------|
| `ACCESS_CONTROLLED` | Every new NestJS endpoint must have `@UseGuards(JwtAuthGuard)` + `@Roles(...)`; every new FE route must be wrapped in the OIDC protected route component. Fail the test run if any endpoint lacks a guard. |
| `WORKFLOW_DRIVEN` | Every state transition must have a TC.md test block. If a transition has no test, stop and ask the user to add one before continuing. |

---

## Scope guards

| Scope | Skip |
|-------|------|
| `FE_ONLY` | Steps B–D BE implementation; Prisma migrations; NestJS controller/service |
| `BE_ONLY` | Steps B–D FE implementation; Zod schemas; React components; Storybook |
| `FULL_STACK` | Nothing skipped |

---

## Run summary (end of --auto run)

```
/impl:full run summary
──────────────────────
Completed: T01, T02, T03  (3 tasks)
Blocked:   T04             (1 task) → see BLOCKERS.md
Commits:   3

Next:
  • Resolve BLOCKERS.md → re-run /impl:full to finish T04
  • Or proceed with /review:full on the completed tasks
```

---

## Upstream reuse

- `agent-skills:incremental-implementation` — vertical slicing, scope discipline, commit discipline
- `agent-skills:test-driven-development` — RED→GREEN loop, test-first mandate
- `agent-skills:debugging-and-error-recovery` — invoked when the fix loop hits a structural problem
- `agent-skills:doubt-driven-development` — invoked for high-risk decisions (auth, migrations, payments)
