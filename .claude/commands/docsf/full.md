---
description: Feature Shot 3 — feature-scope wrapper around /docs:full. Determines in-scope stories from FEATURE.md, then delegates gated doc generation to /docs:full with a feature-wide scope. Writes one coherent README, ARCHITECTURE.md ADR, and API_SPEC.md or COMPONENT_SPEC.md. Run in a fresh session after /reviewf:full.
---

Read and follow `pod/skills/feature-orchestrator/SKILL.md` (Shot 3 — `/docsf:full` process).

## Session rule

Run in a **fresh Claude Code session** — never the same session as `/implf:full` or `/reviewf:full`. Open a new terminal and run `/docsf:full` there.

## Usage

```
/docsf:full
```

No arguments. Reads `FEATURE.md`, `REVIEW.md`, and all in-scope story artifacts from project root.

---

## Pre-flight

Read `FEATURE.md`. Determine in-scope stories (`status: impl_complete`) — same set used by `/reviewf:full`. Note any `blocked` or `skipped` stories; they are mentioned in the docs but not documented as complete.

---

## Delegate to `/docs:full`

All doc generation logic — gates A + B, README/ARCHITECTURE.md/API_SPEC.md/COMPONENT_SPEC.md format, deviation flagging — comes from `/docs:full`. Do not re-implement it here.

Two overrides apply when running `/docs:full` at feature scope:

1. **Scope**: the source of truth is the implemented code across all in-scope stories — not a single story's files. Read from `stories/<dir>/` for each in-scope story; synthesise into one coherent output.

2. **Output**: produce **one doc set** for the whole feature (not N separate docs per story):
   - `README.md` — one feature section covering all in-scope stories from user perspective
   - `ARCHITECTURE.md` — one ADR entry for the whole feature
   - `API_SPEC.md` (BE) or `COMPONENT_SPEC.md` (FE) — complete interface spec across all in-scope stories

Deviation flag format when impl differs from a story's SPEC.md: `⚠️ Deviation from stories/<dir>/SPEC.md §N: ...`

---

## After `/docs:full` completes

1. Update all in-scope story statuses to `done` in `FEATURE.md`
2. Set `impl_status: complete` in `FEATURE.md` frontmatter

State: "Feature docs written. All in-scope stories marked `done`. FEATURE.md updated."

If stories remain `blocked` or `skipped`: "Note: S03, S04 remain blocked/skipped. Resolve their BLOCKERS.md and re-run `/implf:full` → `/reviewf:full` → `/docsf:full` for those stories."
