---
description: Generate TC.md from an approved SPEC.md — Given/When/Then blocks per SC tag covering happy path, edge cases, and error paths
---

Read and follow `pod/skills/test-case-engineering/SKILL.md`.

## Pre-flight

Before generating anything:
1. Read `SPEC.md` from the project root
2. Check `status` field — must be `approved`
3. If not approved: stop with "SPEC.md status is `{{status}}`. Run `/spec:full` and get Gate 1 approval first."

## What this command produces

`TC.md` at the project root, generated from `pod/templates/TC.md`.

For each SC tag in SPEC.md §7:
- **Happy path** — primary success scenario
- **Edge case(s)** — boundaries, conditionals, optional fields
- **Error path** — invalid input, auth failure, constraint violation

Each block includes: Given/When/Then, test file path, test name, Verdict checkbox.

## Usage

```
/tc
```

No arguments — reads SPEC.md from the current project root.

## Output

`TC.md` saved to project root. Summary:
```
TC.md generated: N SC tags, M total test blocks
  SC-01: 3 blocks (happy + 1 edge + 1 error)
  SC-02: 4 blocks (happy + 2 edge + 1 error)
Next: run /plan:full
```

## Notes

- Scope guards apply: FE_ONLY skips BE test files; BE_ONLY skips FE test files
- Test files that do not exist yet are marked `(to be created)` — `/impl:full` creates them
- TC.md verdicts (`[ ] PASS / [ ] FAIL`) are filled in during `/impl:full` as tests run
- Do not manually edit Verdict checkboxes — they are updated by the impl loop
