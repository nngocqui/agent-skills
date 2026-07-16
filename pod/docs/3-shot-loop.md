# 3-Shot Delivery Loop — Map of Content

> [!NOTE]
> This is the MOC (Map of Content) for the entire pod delivery harness. Start here when navigating the loop or onboarding to the harness.

Every story is delivered through three session-isolated shots. Each shot is a separate Claude Code session to prevent context rot.

## The Loop

```
/ticket  →  /spec:full  →  /tc  →  /plan:full
                                        ↓
                              /impl:full  ← Shot 1 (Session 1)
                                        ↓  Gate: all tasks complete
                             /review:full ← Shot 2 (Session 2, fresh)
                                        ↓  Gate: score ≥ 90 + coverage ≥ 85%
                              /docs:full  ← Shot 3 (Session 3, fresh)
```

Multi-story features use `/implf:full → /reviewf:full → /docsf:full` (same loop, orchestrated).

---

## Skills

| Shot | Skill | Trigger |
|------|-------|---------|
| Pre-work | [[ticket-intake]] | Starting from a ClickUp / Jira ticket |
| Pre-work | [[test-case-engineering]] | After SPEC.md is approved |
| Shot 1 | [[incremental-implementation]] | Implementing tasks from PLAN.md |
| Shot 1 | [[test-driven-development]] | Writing tests before implementation |
| Shot 2 | [[3-shot-review]] | After /impl:full completes |
| Shot 3 | [[3-shot-docs]] | After /review:full returns APPROVE |
| Feature | [[feature-orchestrator]] | Multi-story feature with dependencies |

---

## Commands

| Command | Shot | File |
|---------|------|------|
| `/ticket` | Pre-work | `.claude/commands/ticket.md` |
| `/tc` | Pre-work | `.claude/commands/tc.md` |
| `/spec:full` | Pre-work | `.claude/commands/spec/full.md` |
| `/plan:full` | Pre-work | `.claude/commands/plan/full.md` |
| `/impl:full` | Shot 1 | `.claude/commands/impl/full.md` |
| `/review:full` | Shot 2 | `.claude/commands/review/full.md` |
| `/docs:full` | Shot 3 | `.claude/commands/docs/full.md` |
| `/implf:full` | Shot 1 (feature) | `.claude/commands/implf/full.md` |
| `/reviewf:full` | Shot 2 (feature) | `.claude/commands/reviewf/full.md` |
| `/docsf:full` | Shot 3 (feature) | `.claude/commands/docsf/full.md` |

---

## Artifacts (per story)

| File | Created by | Read by |
|------|-----------|---------|
| `SPEC.md` | `/spec:full` | `/tc`, `/plan:full`, `/impl:full`, `/review:full` |
| `TC.md` | `/tc` | `/impl:full`, `/review:full` |
| `PLAN.md` | `/plan:full` | `/impl:full`, `/review:full` |
| `REVIEW.md` | `/review:full` | `/docs:full` (Gate A) |
| `BLOCKERS.md` | `/impl:full` fix loop | human, `/implf:full` |
| `FEATURE.md` | human (from template) | `/implf:full`, `/reviewf:full`, `/docsf:full` |

Templates: `pod/templates/`

---

## Rules

- [[3-shot-gates]] — gate conditions between shots; session isolation mandate; fix loop rules
- [[traceability]] — SC tag chain: every AC traced from ticket → spec → tc → plan → impl → review

---

## Reference

- [[sc-tag-system]] — how SC tags are assigned, formatted, and validated
- `pod/docs/obsidian-wiki.md` — Obsidian wiki conventions used in this harness
- `scripts/validate-sc-tags.sh` — enforces SC tag traceability at commit time
