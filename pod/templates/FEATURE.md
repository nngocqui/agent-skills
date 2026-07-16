---
feature_slug: {{feature-slug}}
feature_name: {{Feature Name}}
scope: FULL_STACK
impl_status: pending
review_verdict: —
---

# Feature: {{Feature Name}}

## Stories

| ID  | Title         | Dir                       | Depends On | Status  |
|-----|---------------|---------------------------|------------|---------|
| S01 | {{title}}     | stories/S01-{{slug}}/     | —          | pending |
| S02 | {{title}}     | stories/S02-{{slug}}/     | S01        | pending |
| S03 | {{title}}     | stories/S03-{{slug}}/     | S01        | pending |
| S04 | {{title}}     | stories/S04-{{slug}}/     | S02, S03   | pending |

**Status values:** `pending` · `in_progress` · `impl_complete` · `blocked` · `skipped` · `done`

> `skipped` = dependency was `blocked`; story could not run.
> `blocked` = impl started but hit an unresolvable blocker (see story's `BLOCKERS.md`).

## Directory layout

```
FEATURE.md                    ← this file (update Status column as work progresses)
DISCOVERY.md                  ← project-level discovery map
stories/
  S01-{{slug}}/
    SPEC.md                   ← status: approved required before /implf:full
    TC.md
    PLAN.md
    BLOCKERS.md               ← written if tasks are blocked during impl
  S02-{{slug}}/
    SPEC.md
    TC.md
    PLAN.md
REVIEW.md                     ← written by /reviewf:full (feature-scope)
ARCHITECTURE.md               ← written/updated by /docsf:full
API_SPEC.md                   ← (BE) or COMPONENT_SPEC.md (FE), written by /docsf:full
```

## Notes

<!-- Shared migrations, cross-story API contracts, ordering concerns not captured in depends_on -->
-
