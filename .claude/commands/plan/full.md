---
description: Generate PLAN.md from an approved SPEC.md + TC.md. Every task carries sc_refs linking it to the SC tags it satisfies. Runs a coverage check before saving.
---

Invoke `agent-skills:planning-and-task-breakdown` for the vertical-slicing and task-sizing process, then apply the pod sc_refs requirements below.

## Pre-flight

1. Read `SPEC.md` — must have `status: approved`
2. Read `TC.md` — must exist (run `/tc` first if missing)
3. If either check fails: stop with a specific error.

## What this command produces

`PLAN.md` at the project root, generated from `pod/templates/PLAN.md`.

## Process

### 1. Read inputs

- **SPEC.md §1** — SC tags and ACs
- **SPEC.md §3–§6** — implementation surface (models, API, components, state)
- **TC.md** — test file assignments per SC tag (used to populate Verification steps)

### 2. Build dependency graph

Map what depends on what for this story:

```
Prisma migration (§3)
  └─→ NestJS service + DTO (§4)
        └─→ NestJS controller + guard (§4)
              └─→ FE API hook (§4 contract)
                    └─→ Zod schema (§5)
                          └─→ FE component (§5)
                                └─→ FE store slice (§6, if needed)
```

Build foundation first; implement top-down.

### 3. Slice vertically

Each task delivers one complete working path — not a horizontal layer. Follow `agent-skills:planning-and-task-breakdown` vertical-slicing rules.

### 4. Write tasks with sc_refs

Every task block must include `sc_refs`. The `sc_refs` field declares which SC tags this task satisfies — it is the traceability link between the plan and the spec.

Rules:
- At least one task must reference each SC tag
- A task may reference multiple SC tags if they are implemented together
- sc_refs must only contain tags from SPEC.md §1

Task verification steps use the test commands from TC.md:
- BE: `npx jest --testPathPattern={{module}}`
- FE: `npx vitest run --reporter=verbose`
- Type-check: `npx tsc --noEmit`
- Lint: `npx eslint src/`
- E2E (if applicable): `npx playwright test tests/{{feature}}.spec.ts`

### 5. Coverage check

After generating all tasks, verify:

```
SC Tag Coverage
───────────────────────────────
SC-01  covered by: T01, T02  ✓
SC-02  covered by: T02        ✓
SC-03  NOT COVERED            ✗ ← must fix before plan is active
```

If any SC tag has no task, add a task or extend an existing task's `sc_refs`. The plan is not usable with a coverage gap.

### 6. Present for human review

Show the full PLAN.md. State:
```
PLAN.md draft: N tasks, covering SC-01 through SC-NN.
Coverage: all SC tags covered ✓

Please review, then:
  - Reply "approve" to accept and begin /impl:full
  - Reply with changes to revise the plan
```

### 7. Save PLAN.md

Save to the project root when the human accepts.

## Commit convention

Include the commit message convention at the bottom of PLAN.md:
```
feat({{feature-slug}}): {{task title}} [SC-01, SC-02]
```

## Upstream reuse

References `agent-skills:planning-and-task-breakdown` for:
- Vertical-slicing discipline (not horizontal layers)
- Task sizing (XS/S/M/L — reject L+ tasks)
- Dependency ordering
- Checkpoints between phases

The pod layer adds sc_refs, coverage check, and stack-specific verification commands.
