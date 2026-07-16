---
description: Feature Shot 2 — feature-scope wrapper around /review:full. Determines in-scope stories from FEATURE.md, then delegates the 4-dimension audit to /review:full with a feature-wide diff. Writes feature REVIEW.md. Run in a fresh session after /implf:full.
---

Read and follow `pod/skills/feature-orchestrator/SKILL.md` (Shot 2 — `/reviewf:full` process).

## Session rule

Run in a **fresh Claude Code session** — never the same session as `/implf:full`. Open a new terminal and run `/reviewf:full` there.

## Usage

```
/reviewf:full
```

No arguments. Reads `FEATURE.md` and all in-scope story artifacts from project root.

---

## Pre-flight

1. Read `FEATURE.md`. Require at least one story with `status: impl_complete`. If none: stop — "No stories are impl_complete. Run `/implf:full` first."
2. Warn (do not stop) for `blocked` or `skipped` stories — they are excluded from review scope.
3. Print scope confirmation before running anything:

```
/reviewf:full scope
────────────────────────────────────────
In scope (impl_complete):  S01 <title> · S02 <title>
Excluded (blocked):        S03 <title>
Excluded (skipped):        S04 <title>

Aggregate SC tags: S01-SC-01, S01-SC-02, S02-SC-01, S02-SC-02, S02-SC-03
```

---

## Delegate to `/review:full`

All audit logic — parallel fan-out, 4-dimension scoring, P0 gate checks, verdict thresholds, REVIEW.md format — comes from `/review:full`. Do not re-implement it here.

Two overrides apply when running `/review:full` at feature scope:

1. **Diff scope**: the diff under review is the aggregate of all in-scope stories' commits since the feature branch was cut — not a single story's changes.

2. **SC tags**: prefix every tag with its story ID to avoid collision (`S01-SC-01`, `S02-SC-01`). The Fidelity dimension verifies all prefixed tags across all in-scope stories.

One addition on top of `/review:full` output:

3. **Per-story sub-scores**: before the aggregate scorecard, include a summary table:
   ```
   | Story | D1 | D2 | D3 | D4 | Total |
   |-------|----|----|----|----|----|
   | S01   | 24 | 23 | 22 | 25 | 94 |
   | S02   | 22 | 25 | 20 | 24 | 91 |
   | Agg   | 23 | 24 | 21 | 25 | 93 |
   ```
   The aggregate row determines the verdict.

---

## After `/review:full` completes

Update `review_verdict` in `FEATURE.md` frontmatter with the verdict.

State: "REVIEW.md written. Verdict: `{{verdict}}` ({{N}}/100)."

Next step routing (same thresholds as `/review:full`):
- `APPROVE` → run `/docsf:full` in a new session
- `MINOR` → fix all listed issues, confirm fixes with the user, then run `/docsf:full` in a new session (do NOT skip to docs before confirming fixes)
- `REWORK` → return to `/implf:full`
- `BLOCK` → human review required before any next step
