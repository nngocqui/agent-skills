---
name: 3-shot-review
phase: review
tags: [review, scorecard, audit, fidelity, coverage, security, a11y, perf]
triggers:
  - After /impl:full completes (all tasks complete or PARTIAL accepted)
  - Before /docs:full
  - Re-reviewing after REWORK verdict
related:
  - 3-shot-docs
  - incremental-implementation
  - code-review-and-quality
  - security-and-hardening
description: Shot 2 of the 3-shot delivery loop. Audits the implementation against SPEC.md using a 4-dimension /100 scorecard. BE dimension 4 = Security; FE dimension 4 = A11y + Perf. P0 trait gates override the verdict regardless of score. Use after /impl:full completes and before /docs:full.
---

# 3-Shot Review

## Overview

A structured /100 audit that verifies implementation against the spec. Unlike a general code review, this skill is spec-anchored: every SC tag in SPEC.md §7 is individually verified, and the score reflects how completely the implementation satisfies the agreed acceptance criteria.

Runs in a **fresh session** to prevent oracle collapse (the model reviewing its own work).

## When to Use

- After `/impl:full` completes (all tasks `complete` or `PARTIAL` accepted)
- Before `/docs:full`
- When re-reviewing after REWORK

**When NOT to use:**
- In the same session as `/impl:full`
- As a substitute for Gate 1 (the spec must already be approved)

> [!IMPORTANT]
> Fresh session is mandatory. Running `/review:full` in the same session as `/impl:full` collapses the reviewer's independent perspective — the model is reviewing its own work with full memory of every decision it made.

## Process

### Step 1: Pre-flight

Read from project root:
- `SPEC.md` — must exist and `status: approved`
- `PLAN.md` — read to know what was implemented
- `TC.md` — read for expected test blocks and verdicts
- `REVIEW.md` — check if a prior review exists; if so, note the prior score

Confirm: "Starting /review:full. Scope: {{scope}}. SC tags: SC-01 through SC-NN."

### Step 2: Parallel fan-out (3 agents)

Spawn three upstream agent personas in **parallel** (single assistant turn, all three Agent tool calls at once):

1. **`code-reviewer`** — five-axis review (correctness, readability, architecture, security, performance) on the changes since the implementation started
2. **`security-auditor`** — OWASP Top 10, auth/authz, secrets handling, dependency CVEs
3. **`test-engineer`** — test coverage analysis, TC.md verdict validation, missing scenarios

These three agents read code independently. They do not coordinate. The merge step below synthesises their outputs into the 4-dimension scorecard.

### Step 3: Score each dimension

#### Dimension 1 — Fidelity (25 pts)

For each SC tag in SPEC.md §7:

1. Read the AC text from §1
2. Find the implementation: what code was written to satisfy this AC?
3. Check TC.md: does the tag have a `Verdict: PASS` block?
4. Verify the implementation matches the AC text literally (not just in spirit)

Scoring:
- Full marks per tag: `25 / total_SC_tags` (e.g. 4 tags = 6.25 pts each)
- Partial credit: AC partially met = half points
- No credit: AC not implemented = 0

Sources: `code-reviewer` correctness findings + `test-engineer` verdict validation.

#### Dimension 2 — Type Health (25 pts)

**BE (NestJS + Prisma):**
- `npx tsc --noEmit` clean → 10 pts
- All DTOs use class-validator; DTO shape matches §4 API Contract → 8 pts
- No untyped `any` without a justifying `// typed-later:` comment → 7 pts

**FE (React + Zod):**
- `npx tsc --noEmit` clean → 10 pts
- Zod schemas in `schemas/` match §5 Component Tree prop types; `z.infer<>` used as prop type → 8 pts
- TanStack Query return types fully typed; no `any` in hook return → 7 pts

Source: `code-reviewer` type health findings.

#### Dimension 3 — Coverage (25 pts)

**Unit / component coverage — 10 pts**
- Statement coverage ≥ 85% on all changed files → 10 pts
  - BE: `npx vitest run --coverage` (src/\*\*/\*.spec.ts)
  - FE: `npx vitest run --coverage --project=unit`
- Deduction: −5 pts per changed file under 85%

**TC.md verdicts — 5 pts**
- All TC.md blocks for this story have `Verdict: PASS` → 5 pts
- Deduction: −3 pts per block with `Verdict: FAIL` or left blank

**Test completeness — 10 pts**

BE:
- Every new or modified HTTP endpoint has a Supertest e2e case in `test/*.e2e-spec.ts` covering happy path + ≥ 1 error path → 5 pts
- E2E suite passes clean (`npx vitest run --config vitest.e2e.config.ts`) → 5 pts

FE:
- Every new component has a `.stories.tsx` alongside it → 3 pts
- Every new page/route has a Playwright spec in `e2e/` covering golden path + ≥ 1 error path → 4 pts
- Playwright suite passes clean (`npx playwright test`) → 3 pts

Missing a story or e2e spec is a finding, not just a deduction — list each gap by file in the REVIEW.md findings.

#### Dimension 4 — Security (BE) / A11y + Perf (FE) (25 pts)

**BE Security** (from `security-auditor` report):
- OWASP Top 10 checked: no injection, broken auth, sensitive data exposure → 10 pts
- Every new endpoint has `@UseGuards(JwtAuthGuard)` + role decorator → 8 pts
- All Prisma queries parameterized; no `$queryRaw` with string interpolation → 4 pts
- No secrets, PII, or tokens in nestjs-pino log output → 3 pts

**FE A11y + Perf** (from `code-reviewer` + manual scan):
- WCAG 2.1 AA: keyboard nav, `aria-label` on icons, `alt` on images, `<button>` not `<div onClick>` → 10 pts
- No unnecessary re-renders (no missing `useMemo`/`useCallback` on stable callbacks passed as props) → 5 pts
- TanStack Query `staleTime` set for new queries (not default 0) → 5 pts
- All user-visible strings via i18next keys → 5 pts

### Step 4: Check P0 trait gates

> [!WARNING]
> P0 gates override the numeric score. A story scoring 95/100 with a P0 failure is still BLOCK. The score is irrelevant once a gate fails.

P0 gates override the numeric verdict. Check AFTER scoring.

| Trait | Check | Fail condition |
|-------|-------|---------------|
| `ACCESS_CONTROLLED` | Every NestJS endpoint added in this story has `@UseGuards(JwtAuthGuard)` AND a `@Roles(...)` decorator / every new FE route is wrapped in the OIDC protected route component | Any unguarded endpoint or unprotected route → P0 FAIL |
| `WORKFLOW_DRIVEN` | Every state transition defined in §6 State & Data Flow has a TC.md test block with `Verdict: PASS` | Any transition without a passing test → P0 FAIL |

If any P0 gate fails → verdict is `BLOCK` regardless of numeric score.

### Step 5: Determine verdict

| Score | Verdict | Meaning | Next step |
|-------|---------|---------|-----------|
| ≥ 90 | **APPROVE** | All dimensions strong | Run `/docs:full` |
| 75–89 | **MINOR** | Small gaps; fix and re-review | Fix listed issues; re-run `/review:full` |
| 60–74 | **REWORK** | Material gaps | Return to `/impl:full` |
| < 60 or P0 fail | **BLOCK** | Significant rework or safety issue | Human must review before any next step |

### Step 6: Write REVIEW.md

Save `REVIEW.md` to the project root using `pod/templates/REVIEW.md`. Fill:
- Per-dimension score + specific findings (file:line)
- SC tag coverage table (each tag: verified Y/N + notes)
- P0 gate results
- Verdict
- Rework instructions (for REWORK or BLOCK)

State clearly: "REVIEW.md written. Verdict: {{APPROVE|MINOR|REWORK|BLOCK}} ({{N}}/100)."

For APPROVE/MINOR: "Run `/docs:full` in a new session."
For REWORK/BLOCK: "Return to `/impl:full` and fix the listed issues. Do not run `/docs:full`."

## Scoring anti-patterns

| Anti-pattern | Why it's wrong |
|---|---|
| Giving full Fidelity score because "the intent is right" | Score is for literal AC satisfaction, not intent |
| Awarding Type Health points without running `tsc` | The compiler is the oracle, not the reading |
| Skipping security check for "internal" endpoints | Internal endpoints are exploited in privilege-escalation attacks |
| Marking a TC.md block PASS without running the test | A verdict without evidence is oracle collapse |

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The score is close enough to 90" | 89 is MINOR, not APPROVE. The threshold is mechanical, not negotiable. |
| "Security issues are low-risk for this feature" | The security-auditor finds issues the feature spec didn't anticipate. Low-risk assessments by the implementing agent are not objective. |
| "All the tests pass so coverage is fine" | Coverage % and TC.md verdicts are different checks. Tests can pass at 60% coverage. |

## Red Flags

- Review run in the same session as `/impl:full`
- Fidelity score given without reading the SC tag AC text
- P0 gate not checked for stories with `ACCESS_CONTROLLED` or `WORKFLOW_DRIVEN` traits
- REVIEW.md written before the three fan-out agents return
- APPROVE verdict with unresolved `test-engineer` Critical findings

## Verification

- [ ] All three fan-out agents ran in parallel (single assistant turn)
- [ ] Every SC tag from SPEC.md §7 appears in the REVIEW.md coverage table
- [ ] P0 gates checked for applicable traits
- [ ] Numeric score computed from structured sub-scores (not estimated from prose)
- [ ] REVIEW.md written to project root
- [ ] Verdict threshold applied correctly

## See Also

- [[3-shot-gates]] — Shot 2→3 gate conditions (score ≥ 90 + coverage ≥ 85%)
- [[3-shot-docs]] — next skill on APPROVE verdict
- [[3-shot-loop|pod/docs/3-shot-loop.md]] — full loop map
- `agents/code-reviewer.md` — upstream fan-out agent
- `agents/security-auditor.md` — upstream fan-out agent
- `agents/test-engineer.md` — upstream fan-out agent
- `pod/templates/REVIEW.md` — the artifact this skill produces
