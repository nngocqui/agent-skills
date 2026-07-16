# 3-Shot Gate Rules

> Applies to both single-story commands (`/impl:full`, `/review:full`, `/docs:full`) and feature commands (`/implf:full`, `/reviewf:full`, `/docsf:full`). Feature-specific additions are marked **[feature]**.

Standing rules enforced by the `/impl:full`, `/review:full`, and `/docs:full` commands. These are mechanical gates — not suggestions.

## Shot 1 → Shot 2 gate

`/review:full` may run at any time, but its Fidelity score will reflect any incomplete tasks in PLAN.md. Run `/review:full` only after all PLAN.md tasks are `complete` or the user has explicitly accepted `PARTIAL` status.

## Shot 2 → Shot 3 gate

`/docs:full` will not proceed unless BOTH conditions are true:
1. `REVIEW.md` verdict is `APPROVE` (score ≥ 90) or `MINOR` with fixes confirmed
2. Test coverage on changed files ≥ 85% (from Jest or Vitest JSON coverage output)

If either condition fails, `/docs:full` stops with a specific message.

## Fix loop rules

- **Max iterations:** 3 per task (configurable: `IMPL_FIX_MAX_ITER` env var, default 3)
- **On exhaustion:** write BLOCKERS.md entry → mark task `blocked` → continue to next task
- **Never kill the batch:** a single failing task never stops the entire run
- **BLOCKERS.md is append-only:** new entries are appended; resolved entries are marked `[RESOLVED]`; old entries are never deleted

## BLOCKERS.md format

Each entry must include:
- Timestamp (`YYYY-MM-DD HH:MM`)
- Story (feature_slug) and task ID
- SC refs affected
- Exact structured error (not prose)
- What was attempted (iterations 1–3)
- Specific decision needed from the human
- `Status: [ ] OPEN` (changed to `[x] RESOLVED` when fixed)

## Commit rules

- One commit per PLAN.md task — no exceptions
- Stage by name: never `git add -A` or `git add .`
- Commit message format: `feat({{feature-slug}}): {{task title}} [SC-01, SC-02]`
- TC.md and PLAN.md status updates are included in the same commit as the task

## Feature-scope gate rules [feature]

### Dependency gate (before each story in /implf:full)

Before starting story S, all stories in its `depends_on` list must have `status: impl_complete`.
- If a dep is `blocked`: mark S as `skipped`. Never start a story with an unmet dependency.
- If a dep is `pending`: hard stop — re-run `/implf:full` after the dep completes.

Cycle detection is a hard stop: list the cycle and exit before touching any code.

### /implf:full → /reviewf:full gate

`/reviewf:full` may run when at least one story is `impl_complete`. Blocked/skipped stories are excluded from the review scope. The reviewer must clearly state which stories are in scope.

### /reviewf:full → /docsf:full gate

Same as the single-story gate: `REVIEW.md` verdict must be `APPROVE` (or `MINOR` with confirmed fixes) AND coverage ≥ 85% on all changed files across in-scope stories. Blocked/skipped stories do not block this gate.

### Commit format [feature]

Feature story commits include the story slug:
```
feat(<feature-slug>/<story-slug>): <task title> [SC-01, SC-02]
```

### Resumability

`/implf:full` is resumable. On re-run it skips `impl_complete` and `done` stories, re-runs `blocked` stories from their first `blocked` task, and skips `skipped` stories whose dep is still not `impl_complete`.

## Session isolation

> [!IMPORTANT]
> Session isolation is the primary defense against context rot. Each shot runs in its own Claude Code session. Do not run two shots in the same session under any circumstances.

Each shot runs in its own Claude Code session:
- `/impl:full` — Session 1
- `/review:full` — Session 2 (fresh context)
- `/docs:full` — Session 3 (fresh context)

## Pre-flight failures

> [!WARNING]
> Pre-flight failures are hard stops, not warnings. The command exits immediately with a specific message. Do not attempt to work around them.

A pre-flight failure is a hard stop — not a warning. The command exits with a specific message. The user must resolve the issue and re-run. The following are hard stops:
- `SPEC.md` missing or `status != approved`
- `TC.md` missing
- `PLAN.md` missing
- SC tag validator returns exit 1
- Uncommitted changes outside planning artifacts (in `--auto` mode)
