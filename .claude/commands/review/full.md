---
description: Shot 2 — 4-dimension /100 audit of the implementation against SPEC.md. Spawns code-reviewer, security-auditor, and test-engineer in parallel. Writes REVIEW.md. Run in a fresh session after /impl:full.
---

Read and follow `pod/skills/3-shot-review/SKILL.md`.

## Session rule

Run in a **fresh Claude Code session** — never the same session as `/impl:full`. Open a new terminal and execute `/review:full` there.

## What this command does

1. **Pre-flight:** reads SPEC.md (must be `approved`), PLAN.md, TC.md
2. **Parallel fan-out:** spawns `code-reviewer` + `security-auditor` + `test-engineer` in one turn
3. **Scores:** 4 dimensions × 25 pts against the implementation and SPEC.md §7 SC tags
4. **P0 gates:** checks trait-specific blockers (ACCESS_CONTROLLED, WORKFLOW_DRIVEN)
5. **Verdict:** APPROVE / MINOR / REWORK / BLOCK
6. **Writes** `REVIEW.md` to project root

## Usage

```
/review:full
```

No arguments. Reads all inputs from the project root.

## Scoring summary

| Dimension | BE (25 pts) | FE (25 pts) |
|---|---|---|
| **Fidelity** | SC tags satisfied per §7 | Same |
| **Type Health** | tsc clean · DTO ↔ §4 contract · no untyped any | tsc clean · Zod ↔ §5 props · no untyped any |
| **Coverage** | Vitest ≥ 85% changed files (10) · TC.md PASS (5) · e2e spec + suite pass (10) | Vitest ≥ 85% changed files (10) · TC.md PASS (5) · stories + Playwright spec + suite (10) |
| **Dimension 4** | Security (OWASP, guards, Prisma, pino) | A11y + Design + Perf (WCAG 2.1 AA, design-plan token adherence, `prefers-reduced-motion`, UX copy, re-renders, staleTime, i18n) |

## Verdicts

| Score | Verdict | Next |
|-------|---------|------|
| ≥ 90 | **APPROVE** | `/docs:full` in new session |
| 75–89 | **MINOR** | Fix issues · re-run review · then docs |
| 60–74 | **REWORK** | `/impl:full` to fix |
| < 60 or P0 fail | **BLOCK** | Human review required |

## FE D4 — design fidelity checks

When scope includes FE (FULL_STACK or FE_ONLY), the D4 dimension includes:

- **Token adherence**: components use token names from `design-plan.md` (or the project's design system); no arbitrary hex values or spacing outside the token set
- **Motion**: `prefers-reduced-motion` is respected on every animation; no more than one "featured" animation per view
- **UX copy**: interactive elements use active voice and specific verbs ("Save changes", not "Submit"); action names are consistent across button → loading state → success toast
- **A11y**: WCAG 2.1 AA — keyboard navigation, ARIA labels, focus management, contrast ≥ 4.5:1

If `design-plan.md` is absent and the task created new pages or views, deduct 5 pts from D4 and note: "No design plan found — token provenance unverifiable."

## P0 gates

P0 gate failure → **BLOCK** regardless of score:
- `ACCESS_CONTROLLED` trait: any unguarded endpoint or unprotected route
- `WORKFLOW_DRIVEN` trait: any state transition without a passing TC.md test

## Output

`REVIEW.md` at the project root with:
- Per-dimension score + findings (file:line)
- SC tag coverage table
- P0 gate results
- Verdict + rework instructions (if not APPROVE)

## See Also

- [[3-shot-review]] — full skill process (`pod/skills/3-shot-review/SKILL.md`)
- [[3-shot-gates]] — gate rules between shots
- [[3-shot-loop|pod/docs/3-shot-loop.md]] — full loop map
