# Test Cases: {{feature_slug}}

> Generated from `SPEC.md §7 Test Scope`.
> Each SC tag gets one block set: happy path + edge case(s) + error path.
> Verdicts are filled in during `/impl:full` as tests are run.
> Reference: `pod/docs/sc-tag-system.md`

---

## SC-01: {{AC text from SPEC.md §1}}

### Happy Path

**Given** {{precondition — system state, user role, data in place}}
**When** {{action performed}}
**Then** {{expected outcome — specific and measurable}}

**Test file:** `{{path/to/test.spec.ts}}`
**Test name:** `{{describe block > it block}}`
**Verdict:** [ ] PASS  [ ] FAIL  [ ] SKIPPED

---

### Edge Case: {{edge case description}}

**Given** {{precondition}}
**When** {{boundary or unusual input}}
**Then** {{expected outcome — e.g. validation error, fallback, no-op}}

**Test file:** `{{path/to/test.spec.ts}}`
**Test name:** `{{describe block > it block}}`
**Verdict:** [ ] PASS  [ ] FAIL  [ ] SKIPPED

---

### Error Path: {{error scenario}}

**Given** {{precondition}}
**When** {{action that should fail — invalid input, missing auth, network error}}
**Then** {{expected error — status code, error message, UI state}}

**Test file:** `{{path/to/test.spec.ts}}`
**Test name:** `{{describe block > it block}}`
**Verdict:** [ ] PASS  [ ] FAIL  [ ] SKIPPED

---

## SC-02: {{AC text from SPEC.md §1}}

### Happy Path

**Given** {{precondition}}
**When** {{action}}
**Then** {{outcome}}

**Test file:** `{{path}}`
**Test name:** `{{name}}`
**Verdict:** [ ] PASS  [ ] FAIL  [ ] SKIPPED

---

### Edge Case: {{description}}

**Given** {{precondition}}
**When** {{action}}
**Then** {{outcome}}

**Test file:** `{{path}}`
**Test name:** `{{name}}`
**Verdict:** [ ] PASS  [ ] FAIL  [ ] SKIPPED

---

### Error Path: {{description}}

**Given** {{precondition}}
**When** {{action}}
**Then** {{outcome}}

**Test file:** `{{path}}`
**Test name:** `{{name}}`
**Verdict:** [ ] PASS  [ ] FAIL  [ ] SKIPPED

---

<!-- Repeat the SC-NN block for each tag in SPEC.md §7 -->

---

## Coverage Summary

| Tag | Happy | Edge | Error | All Pass? |
|-----|-------|------|-------|-----------|
| SC-01 | [ ] | [ ] | [ ] | [ ] |
| SC-02 | [ ] | [ ] | [ ] | [ ] |

**Overall verdict:** [ ] ALL PASS — ready for `/review:full`
