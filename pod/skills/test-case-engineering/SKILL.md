---
name: test-case-engineering
phase: plan
tags: [tdd, tc, sc-tags, given-when-then, test-specification, coverage]
triggers:
  - After SPEC.md status is approved (Gate 1 passed)
  - Before /plan:full and /impl:full
  - Regenerating TC.md after a spec change
related:
  - ticket-intake
  - planning-and-task-breakdown
  - test-driven-development
description: Derives TC.md from an approved SPEC.md. Each SC tag in §7 Test Scope becomes a set of Given/When/Then blocks covering the happy path, edge cases, and error paths. Use before /impl:full to produce the test specification the implementation loop verifies against.
---

# Test Case Engineering

## Overview

Turns SPEC.md §7 Test Scope into a concrete, file-level test specification. TC.md is written before any code is implemented — it is the oracle the `/impl:full` loop verifies against and the source of the Fidelity dimension in `/review:full`.

A TC.md that only covers happy paths will produce code that only works in happy paths. This skill mandates edge-case and error-path coverage for every SC tag.

## When to Use

- After SPEC.md `status: approved` (Gate 1 passed)
- Before `/plan:full` and `/impl:full`
- When an existing TC.md needs to be regenerated after a spec change

**When NOT to use:** Before SPEC.md is approved (Gate 1 not passed). The skill must reject draft specs.

## Process

### Step 1: Pre-flight

Read SPEC.md from the project root. Check `status` field:
- `approved` → proceed
- anything else → stop: "Cannot generate TC.md: SPEC.md status is `{{status}}`. Run `/spec:full` and get human approval first."

> [!WARNING]
> Never generate TC.md from a draft SPEC.md. The spec must carry `status: approved` before any test blocks are written.

### Step 2: Extract §7 Test Scope

Read the §7 table. For each row:
- SC tag
- What to test
- FE / BE / E2E coverage flags

Build a list: `[(SC-01, "what to test", {fe, be, e2e}), ...]`

### Step 3: Generate blocks per SC tag

For each SC tag, generate **three block types** in TC.md:

#### Happy Path block

The primary success scenario. Conditions are met; output is the expected result.

```markdown
### Happy Path

**Given** <precondition — system state, user role, existing data>
**When** <action — user interaction, API call, or event>
**Then** <expected outcome — specific: status code, UI state, DB record, error message>

**Test file:** `<path>`
**Test name:** `<describe block > it block>`
**Verdict:** [ ] PASS  [ ] FAIL  [ ] SKIPPED
```

#### Edge Case block(s)

Boundary conditions, optional fields, conditional logic, maximum/minimum values.

```markdown
### Edge Case: <description>

**Given** <precondition>
**When** <boundary or unusual input>
**Then** <expected outcome>
...
```

Generate one block per distinct edge case. For conditional ACs (e.g. "field shows only when parent = Others"), generate one block for the condition-true path and one for condition-false.

#### Error Path block

Invalid input, auth failure, network error, or constraint violation.

```markdown
### Error Path: <scenario>

**Given** <precondition>
**When** <action that should fail>
**Then** <expected error — HTTP status + error code + user-visible message>
...
```

### Step 4: Assign test files

For each block, assign the most specific test file based on coverage flags:

| Coverage | NestJS BE file | React FE file |
|----------|---------------|--------------|
| BE unit | `src/modules/{{module}}/{{module}}.service.spec.ts` | — |
| BE e2e | `test/{{module}}.e2e-spec.ts` | — |
| FE unit | — | `src/features/{{feature}}/{{Feature}}.test.tsx` |
| FE E2E | — | `tests/{{feature}}.spec.ts` |

These paths follow the NestJS + React project conventions. If the project uses a different structure, derive the path from the nearest sibling test file in the same module rather than from this table.

If the test file does not exist yet, note it as `(to be created)`.

### Step 5: Write coverage summary

At the end of TC.md, write a coverage table:

```markdown
| Tag | Happy | Edge | Error | All Pass? |
|-----|-------|------|-------|-----------|
| SC-01 | [ ] | [ ] | [ ] | [ ] |
```

### Step 6: Save TC.md

Save to the project root alongside SPEC.md.

Confirm: "TC.md generated with {{N}} SC tags, {{M}} total test blocks. Run `/plan:full` next."

## Scope guards

- `FE_ONLY` scope: skip BE test file assignments; no `src/modules/` references
- `BE_ONLY` scope: skip FE test file assignments; no `src/features/` references
- `FULL_STACK`: generate both

## What makes a good Given/When/Then

| Element | Weak | Strong |
|---------|------|--------|
| **Given** | "User is logged in" | "An authenticated adviser with role `ADVISER` is logged in; the DB has 0 existing clients" |
| **When** | "User submits the form" | "User fills Step 1 form with valid Full Name, DOB, Gender, Nationality and clicks Next" |
| **Then** | "Data is saved" | "POST /api/onboarding/step-1 returns 200 `{success:true, data:{id}}` and a new OnboardingRecord exists in DB with status `STEP_1_COMPLETE`" |

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The happy path is enough for now" | An agent that only tests happy paths ships code that only works in demos. Edge cases are where bugs live. |
| "I'll add edge cases during review" | The review dimension checks TC.md verdicts. Missing blocks → missing verdicts → Coverage score drops. |
| "The test names are self-explanatory" | Test file + test name in each block are required so `/impl:full` can run exactly the right test, not the whole suite. |

## Red Flags

- Blocks with `**Then** <verify it works>` (no specific assertion)
- All blocks assigned to the same test file regardless of coverage flags
- Zero edge-case blocks for a conditional AC
- TC.md generated before SPEC.md is approved
- Missing error-path block for any endpoint or form submission

## Verification

- [ ] Every SC tag in SPEC.md §7 has ≥ 1 happy-path block
- [ ] Every SC tag has ≥ 1 edge-case block
- [ ] Every SC tag that touches an API endpoint or form has ≥ 1 error-path block
- [ ] Every block has a specific test file + test name assigned
- [ ] Coverage summary table is complete
- [ ] Running `/tc` on a `draft` spec produces an error, not a partial TC.md

## See Also

- [[sc-tag-system]] — SC tag convention and traceability chain
- [[ticket-intake]] — prior step (assigns SC tags to ACs)
- [[test-driven-development]] — used by `/impl:full` to implement against TC.md
- `/plan:full` — next command after TC.md is generated
- `pod/templates/TC.md` — the template this skill populates
