# Pod Manifest — Custom File Registry

Every file this overlay owns. Use this during `git merge upstream/main` to confirm no conflicts affect our work.

## pod/ directory (safe — does not exist in upstream)

```
pod/README.md
pod/MANIFEST.md
pod/skills/ticket-intake/SKILL.md
pod/skills/test-case-engineering/SKILL.md
pod/skills/3-shot-review/SKILL.md
pod/skills/3-shot-docs/SKILL.md
pod/rules/traceability.md
pod/rules/3-shot-gates.md
pod/templates/SPEC.md
pod/templates/TC.md
pod/templates/PLAN.md
pod/templates/REVIEW.md
pod/templates/BLOCKERS.md
pod/templates/discovery-map.md
pod/templates/FEATURE.md
pod/skills/feature-orchestrator/SKILL.md
pod/skills/stack-reference/SKILL.md
pod/docs/sc-tag-system.md
pod/docs/harness-install.md
pod/docs/3-shot-loop.md
pod/docs/context-engineering.md
pod/docs/obsidian-wiki.md
```

## .claude/commands/ additions (new files/subfolders — no upstream equivalent)

```
.claude/commands/ticket.md          → /ticket
.claude/commands/tc.md              → /tc
.claude/commands/spec/full.md       → /spec:full
.claude/commands/plan/full.md       → /plan:full
.claude/commands/impl/full.md       → /impl:full
.claude/commands/review/full.md     → /review:full
.claude/commands/docs/full.md       → /docs:full
.claude/commands/implf/full.md      → /implf:full
.claude/commands/reviewf/full.md    → /reviewf:full
.claude/commands/docsf/full.md      → /docsf:full
.claude/commands/stack-ref.md       → /stack-ref
.claude/commands/design-plan.md     → /design-plan
```

## scripts/ addition (new file alongside upstream files)

```
scripts/validate-sc-tags.sh
```

## .claude/settings.json (modified — minimal delta)

The only change to an upstream-adjacent file. After a merge, verify the `hooks` section we added is still present:
```json
"hooks": {
  "PreToolUse": [{ "matcher": "Write", "hooks": [...validate-sc-tags...] }]
}
```

## tasks/ (planning artifacts — not upstream, not pod)

```
tasks/plan.md
tasks/todo.md
```

## Upstream additions (new skill directories — contributed, no upstream equivalent yet)

These are new `skills/` directories we've added. They do not modify existing upstream files, so they carry no merge risk unless upstream adds the same directory name.

```
skills/frontend-design/SKILL.md     → frontend-design skill (runs before frontend-ui-engineering)
```

---

## Upstream files — DO NOT MODIFY

These belong to `addyosmani/agent-skills`. Modifying them breaks the zero-conflict merge guarantee.

```
skills/**
agents/**
.claude/commands/spec.md        ← upstream /spec
.claude/commands/plan.md        ← upstream /plan
.claude/commands/build.md       ← upstream /build
.claude/commands/review.md      ← upstream /review
.claude/commands/test.md        ← upstream /test
.claude/commands/ship.md        ← upstream /ship
.claude/commands/webperf.md     ← upstream /webperf
.claude/commands/code-simplify.md
.claude/rules/skills-contributing.md
hooks/**
references/**
docs/**
scripts/run-evals.js
scripts/validate-commands.js
scripts/validate-skills.js
evals/**
CLAUDE.md
AGENTS.md
CONTRIBUTING.md
README.md
```

---

## Merge procedure

```bash
# 1. Fetch upstream
git fetch upstream

# 2. Check for potential conflicts before merging
git diff upstream/main --name-only | grep -E "^(pod/|\.claude/commands/(ticket|tc)\.md|\.claude/commands/(spec|plan|impl|review|docs)/|scripts/validate-sc-tags)"

# 3. If the grep above returns nothing — safe to merge
git merge upstream/main

# 4. If it returns files — those upstream files now overlap with ours.
#    Resolve by keeping both versions or renaming ours.
```
