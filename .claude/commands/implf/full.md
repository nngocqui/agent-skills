---
description: Feature Shot 1 — dependency-aware impl across all stories in FEATURE.md. Builds a dependency graph, shows execution plan, then runs each story's per-story TDD loop in wave order. Run in its own session.
---

Read and follow `pod/skills/feature-orchestrator/SKILL.md` (Shot 1 — `/implf:full` process).

## Session rule

Run `/implf:full` in a **fresh Claude Code session**. Do not share a session with `/reviewf:full` or `/docsf:full`.

## Modes

- **`/implf:full`** — dependency analysis + implement the next eligible story, then stop.
- **`/implf:full --auto`** — dependency analysis → human approves plan → all stories run autonomously in wave order. Pauses on blockers that need human input.

`$ARGUMENTS`: `--auto` or `auto` = autonomous mode. Empty or anything else = single-story mode.

---

## Pre-flight

1. Read `FEATURE.md` from project root. If missing: stop — "FEATURE.md not found. Create from `pod/templates/FEATURE.md`."
2. For each story in the stories table:
   - Confirm `stories/<dir>/` exists
   - Confirm `SPEC.md` has `status: approved`
   - Confirm `TC.md` and `PLAN.md` exist
   - Run SC tag validator: `bash scripts/validate-sc-tags.sh --spec stories/<dir>/SPEC.md --tc stories/<dir>/TC.md --plan stories/<dir>/PLAN.md`
3. Collect all failures. If any: list them all and stop. Fix before re-running.
4. Run `git status --porcelain`. If uncommitted changes exist outside `stories/*/SPEC.md`, `stories/*/TC.md`, `stories/*/PLAN.md`, `FEATURE.md`, `BLOCKERS.md`: stop — "Uncommitted changes detected. Commit or stash first."

If all pass: "Pre-flight OK."

---

## Step 1: Dependency analysis (always runs)

Build the dependency graph from the `Depends On` column in FEATURE.md. Topological sort (Kahn's BFS):

- **Wave 1**: stories with no dependencies
- **Wave N+1**: stories whose deps are all in waves ≤ N
- **Cycle detected**: hard stop — list the cycle and exit

Display before any impl:

```
Dependency analysis
───────────────────
S01  <title>   deps: —          Wave 1  ← ready
S02  <title>   deps: S01        Wave 2
S03  <title>   deps: S01        Wave 2
S04  <title>   deps: S02, S03   Wave 3

Execution plan:
  Wave 1:  S01
  Wave 2:  S02 → S03    (after S01)
  Wave 3:  S04           (after S02 + S03)

Already complete: <none | S01, ...>
Skipped (dep blocked): <none | S03, ...>
```

In `--auto` mode: wait for "approve" / "go" / "yes" before proceeding. "looks good" = not approved.

In single-story mode: display the plan, then run only the next eligible story (lowest wave, lowest ID among `pending` with all deps `impl_complete`), then stop.

---

## Per-story loop

For each story in wave order:

**Dependency gate**: all `depends_on` stories must be `impl_complete`. If any dep is `blocked` or `skipped`: mark this story `skipped` in FEATURE.md, log it, continue to next story.

Set story `status: in_progress` in FEATURE.md.

**Delegate to `/impl:full`** — all per-task work (JIT context load, RED→GREEN TDD loop, fix loop, TC.md verdicts, commits, PLAN.md updates) is handled by `/impl:full`. This command adds only the orchestration wrapper around it.

Two overrides apply when running `/impl:full` for a feature story:

1. **Working root**: treat `stories/<dir>/` as the project root. `SPEC.md`, `TC.md`, `PLAN.md`, `BLOCKERS.md` are all read from and written to `stories/<dir>/`.

2. **Commit format**: use `feat(<feature-slug>/<story-slug>): <task title> [SC-01]` instead of the single-story format. All other commit rules from `/impl:full` apply unchanged (stage by name, one commit per task, never `git add -A`).

Run `/impl:full --auto` for this story (human approval was already granted at the feature level).

**After `/impl:full` returns for this story:**
- If all PLAN.md tasks are `complete` or some are `blocked` → set `status: impl_complete` in FEATURE.md
- If `/impl:full` reported a hard blocker requiring human input → set `status: blocked`
- Print story summary: `S01 user-login ✓ impl_complete  4/4 tasks  4 commits`

---

## End-of-run summary

```
/implf:full summary
───────────────────────────────────────
S01  <title>  ✓ impl_complete  4/4 tasks  4 commits
S02  <title>  ✓ impl_complete  3/3 tasks  3 commits
S03  <title>  ✗ blocked        2/3 tasks  → stories/S03-.../BLOCKERS.md
S04  <title>  ○ skipped        dep S03 blocked

Feature impl_status: partial

Next:
• Resolve S03 BLOCKERS.md → re-run /implf:full (resumes from S03)
• Or: /reviewf:full in a new session (covers S01 + S02 only)
```

Update `impl_status` in FEATURE.md: `complete` if all `impl_complete`; `partial` if any `blocked` or `skipped`.
