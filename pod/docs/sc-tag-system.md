# SC Tag System

SC tags are the traceability contract of the 3-shot delivery loop. A tag assigned at ticket intake is carried **unchanged** through every artifact until the review sign-off.

## Format

```
SC-NN
```

- Two-digit, zero-padded: `SC-01`, `SC-02` … `SC-99`
- Assigned once at ticket intake by `/ticket`; never renumbered after assignment
- If a story has more than 99 ACs, split the story — a 100-AC story is a feature, not a story

## Assignment

`/ticket` numbers ACs in order of appearance in the source ticket:

```
Ticket AC 1 → SC-01
Ticket AC 2 → SC-02
Ticket AC 3 → SC-03
```

If an AC is later split into two sub-criteria during spec writing, both sub-criteria are recorded under the same SC tag in SPEC.md §1. The tag is not split.

## Traceability chain

The same tag must appear in each artifact:

| Artifact | Where the tag appears | Form |
|----------|-----------------------|------|
| **Ticket** | AC list | plain text |
| **SPEC.md §1** | Story Summary AC table | `SC-01` in Tag column |
| **SPEC.md §7** | Test Scope table | `SC-01` in Tag column |
| **TC.md** | Section heading | `## SC-01: <AC text>` |
| **PLAN.md** | Task `sc_refs` field | `sc_refs: [SC-01, SC-02]` |
| **REVIEW.md** | Fidelity dimension table | `SC-01` in Tag column |

The `scripts/validate-sc-tags.sh` validator checks columns 2–5 mechanically and exits non-zero if any tag is missing.

## Validator usage

```bash
# Check consistency across SPEC, TC, and PLAN (before impl)
bash scripts/validate-sc-tags.sh --spec SPEC.md --tc TC.md --plan PLAN.md

# Check all four artifacts (after review)
bash scripts/validate-sc-tags.sh --spec SPEC.md --tc TC.md --plan PLAN.md --review REVIEW.md
```

Exit 0 = all consistent. Exit 1 = gap table printed to stdout.

## What "verified" means in REVIEW.md

A tag is marked ✓ in the Fidelity dimension when:
1. The implementation satisfies the literal AC text
2. At least one TC.md test block for that tag has `Verdict: PASS`
3. The test file/line is cited in the REVIEW.md finding

A tag is marked ✗ when any of the three conditions above is not met.

## Scope guards and N/A tags

For `FE_ONLY` scope: tags that are BE-only (e.g. an AC about a database constraint) are still listed in §7 but marked `BE: N/A` and excluded from coverage counting.

For `BE_ONLY` scope: tags about FE behaviour are marked `FE: N/A` similarly.

The validator treats `N/A` entries as satisfied (not a gap).

## Renumbering rule

Tags are **never renumbered**. If AC 2 is deleted during spec review:

- SC-02 is marked `Removed: {{reason}}` in SPEC.md §1
- SC-02 is removed from §7 and TC.md
- SC-03 stays SC-03 (not promoted to SC-02)
- The validator treats a `Removed` tag as satisfied

This preserves the audit trail: every number that was ever assigned is accounted for.
