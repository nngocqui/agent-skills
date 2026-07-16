---
name: 3-shot-docs
phase: ship
tags: [docs, adr, api-spec, readme, architecture, documentation]
triggers:
  - After /review:full returns APPROVE or MINOR-fixed
  - After coverage gate passes (≥ 85% on changed files)
related:
  - 3-shot-review
  - documentation-and-adrs
description: Shot 3 of the 3-shot delivery loop. Generates documentation from the implemented code and SPEC.md, gated on review ≥ 90 AND test coverage ≥ 85% on changed files. Runs in a fresh session. Use after /review:full returns APPROVE or MINOR-fixed.
---

# 3-Shot Docs

## Overview

Generates four documentation artifacts from the implemented code and the approved spec. Documentation is derived from what was actually built — not from chat history or the spec's intent. This distinction matters: if the implementation deviated from the spec in any way, the docs reflect the implementation (and the deviation should be noted).

Runs in a **fresh session** after Shot 2.

## When to Use

- After `/review:full` returns `APPROVE` (≥ 90) or after MINOR issues are fixed and re-reviewed
- After test coverage on changed files is ≥ 85%
- Never in the same session as `/impl:full` or `/review:full`

## Process

### Step 1: Gate checks (hard stops)

**Gate A — Review verdict:**
1. Read `REVIEW.md` from project root
2. Check the Verdict field:
   - `APPROVE` → proceed
   - `MINOR` → check if the user has confirmed fixes were made; if yes, proceed; if no, stop: "REVIEW.md verdict is MINOR. Confirm fixes are done and /review:full has been re-run with APPROVE verdict."
   - `REWORK` or `BLOCK` → stop: "Cannot generate docs. REVIEW.md verdict is {{verdict}}. Run /impl:full to fix the issues, then re-run /review:full."
   - REVIEW.md missing → stop: "REVIEW.md not found. Run /review:full first."

> [!WARNING]
> Gate A and Gate B are hard stops — not advisory checks. If either fails, exit immediately. Do not generate partial documentation.

**Gate B — Coverage:**
1. Read coverage report:
   - BE: `npx vitest run --coverage` → read `coverage/coverage-summary.json`
   - FE: `npx vitest run --coverage --project=unit` → read `coverage/coverage-summary.json`
2. For each file changed in this story (git diff against the branch point):
   - Check `statements.pct` in the coverage summary
   - If any changed file < 85% → stop: "Coverage gate failed. The following changed files are under 85%: {{list with current %}}"

If both gates pass: "Gates passed. Generating docs."

### Step 2: Read inputs

Do NOT use chat history or memory of the implementation session. Read from the filesystem:
- `SPEC.md` — source of truth for intent and contract
- `PLAN.md` — what tasks were completed
- `TC.md` — test coverage and scenarios
- `REVIEW.md` — score and findings (reference for Architecture doc)
- Implemented code files (read the actual files, not recollections)

### Step 3: Generate README.md update

Update the project's `README.md` (or create a `docs/features/{{feature_slug}}.md` if the project uses per-feature docs).

Include:
- **What this feature does** — 2–3 sentences from the user's perspective
- **How to use it** — API endpoints (BE) or UI flow steps (FE)
- **Configuration** — environment variables, feature flags (if any)
- **Known limitations** — anything from §8 Open Questions marked as "accepted limitation"

Write from the perspective of someone who will use or operate the feature, not someone who built it.

### Step 4: Generate ARCHITECTURE.md entry

Append a new entry to `ARCHITECTURE.md` (create if it doesn't exist). Use ADR-style format:

```markdown
## ADR-{{N}}: {{feature_slug}} — {{YYYY-MM-DD}}

**Status:** Accepted

**Context:**
{{Why this feature was built — from ticket description and business context}}

**Decisions:**
{{Key decisions from §2 Prototype Analysis and §3 Data Model, each with rationale}}
1. Used {{pattern/technology}} because {{reason}}
2. Chose {{approach}} over {{alternative}} because {{reason}}

**Consequences:**
{{What becomes easier, harder, or different because of these decisions}}

**SC tags covered:** SC-01, SC-02, …
**Review score:** {{N}}/100
```

### Step 5: Generate API_SPEC.md (BE scope) or COMPONENT_SPEC.md (FE scope)

**BE — API_SPEC.md:**

Read the actual NestJS controller and DTO files. Document what was implemented:

```markdown
## {{METHOD}} {{/api/path}}

**Auth:** Required — JWT Bearer token  
**Role:** {{role from @Roles decorator}}

**Request body:**
\`\`\`typescript
// Actual DTO fields (read from the implemented file)
\`\`\`

**Response (200):**
\`\`\`typescript
{ success: true, data: { ... } }
\`\`\`

**Error responses:**
| Status | Code | When |
|--------|------|------|
| 400 | VALIDATION_ERROR | ... |

**Swagger:** available at /api/docs
```

Note any deviations from SPEC.md §4. If the implementation differs from the contract, flag it: "⚠️ Deviation from §4: {{what changed and why}}"

**FE — COMPONENT_SPEC.md:**

Read the actual component and Zod schema files. Document:

```markdown
## {{ComponentName}}

**Location:** `src/features/{{feature}}/components/{{Component}}.tsx`

**Props:**
\`\`\`typescript
// Actual Zod schema (z.infer<> type)
\`\`\`

**State:** (Zustand slice name, TanStack Query key)

**Storybook:** `src/features/{{feature}}/{{Component}}.stories.tsx`

**A11y notes:** {{keyboard nav, aria attributes used}}
```

### Step 6: Save all docs

Save to the project root (or `docs/` if the project uses a docs folder). Confirm paths.

State: "Shot 3 complete. Docs generated:
- README.md updated
- ARCHITECTURE.md — ADR-N added
- API_SPEC.md (or COMPONENT_SPEC.md) updated

Story {{feature_slug}} is done. ✓"

## What docs are NOT

- Docs do not paraphrase chat history
- Docs do not describe what we "tried" — only what was built
- Docs do not include implementation detail that will change — they describe the interface and decisions
- ARCHITECTURE.md entries do not say "we decided to..." — they say "the system uses..."

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The spec is the documentation" | The spec documents intent. Docs document what was built. They diverge. |
| "We can skip docs for internal features" | Internal endpoints are called by other teams. Undocumented interfaces get called wrong. |
| "I'll remember the architecture decisions" | ADRs exist because memory fails across sprints and team members. |

## Red Flags

- Docs generated from memory / chat history instead of reading code files
- API_SPEC.md that matches §4 exactly without reading the implementation (may miss deviations)
- ARCHITECTURE.md entry with no rationale (just "we chose X" without "because Y")
- README update written in past tense ("we added…")
- Gate A or Gate B bypassed

## Verification

- [ ] Gate A passed (REVIEW.md verdict is APPROVE)
- [ ] Gate B passed (coverage ≥ 85% on all changed files)
- [ ] README.md describes the feature from user perspective
- [ ] ARCHITECTURE.md has a new ADR entry with decisions and rationale
- [ ] API_SPEC.md or COMPONENT_SPEC.md reflects actual implemented code, not just the spec
- [ ] Any deviations from SPEC.md are flagged with ⚠️ in the API/Component spec
- [ ] All docs are in present tense (not past tense)

## See Also

- [[3-shot-gates]] — Shot 2→3 gate conditions
- [[3-shot-review]] — prior skill (produces REVIEW.md Gate A reads)
- [[documentation-and-adrs]] — upstream ADR writing principles
- [[3-shot-loop|pod/docs/3-shot-loop.md]] — full loop map
- `pod/templates/REVIEW.md` — Gate A source
