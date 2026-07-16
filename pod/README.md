# pod/ — Custom AI-SDLC Overlay

This directory contains all custom work for the 3-shot delivery loop and ticket-first workflow. It lives alongside the upstream `agent-skills` files without touching them, so `git merge upstream/main` produces zero conflicts.

## What lives here

| Directory | Contents |
|---|---|
| `skills/` | Custom SKILL.md files (`ticket-intake`, `test-case-engineering`, `3-shot-review`, `3-shot-docs`) |
| `agents/` | Custom agent overrides (if any) |
| `rules/` | Claude Code rule fragments loaded via CLAUDE.md |
| `templates/` | Canonical artifact templates: SPEC, TC, PLAN, REVIEW, BLOCKERS |
| `docs/` | Custom docs: SC tag system, harness install, 3-shot loop, context engineering |

## What lives elsewhere (custom but not here)

| Location | Contents | Why not in pod/ |
|---|---|---|
| `.claude/commands/ticket.md` | `/ticket` command | Must be in `.claude/commands/` for Claude Code to load |
| `.claude/commands/tc.md` | `/tc` command | Same |
| `.claude/commands/spec/full.md` | `/spec:full` | Same — subfolder creates `:` namespace |
| `.claude/commands/plan/full.md` | `/plan:full` | Same |
| `.claude/commands/impl/full.md` | `/impl:full` | Same |
| `.claude/commands/review/full.md` | `/review:full` | Same |
| `.claude/commands/docs/full.md` | `/docs:full` | Same |
| `scripts/validate-sc-tags.sh` | SC tag validator | Lives alongside upstream scripts/ |

See `pod/MANIFEST.md` for the full list and the upstream merge procedure.

## Merge strategy

When pulling upstream updates:

```bash
git fetch upstream
git merge upstream/main
```

Expected result: zero conflicts. All upstream files (`skills/`, `agents/`, `.claude/commands/*.md` flat files, `hooks/`, `references/`, `docs/`, `scripts/run-evals.js`, etc.) are untouched by this overlay.

If a conflict does appear, check `pod/MANIFEST.md` — it lists every file this overlay owns. Any conflict in a file NOT on that list means upstream added something with the same name as one of ours; resolve by keeping both or renaming ours.
