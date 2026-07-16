# Plan: {{feature_slug}}

> Generated from `SPEC.md` + `TC.md` by `/plan:full`.
> Each task declares `sc_refs` — the SC tags whose ACs it satisfies.
> Every SC tag from SPEC.md §1 must appear in at least one task's `sc_refs`.
> Reference: `pod/docs/sc-tag-system.md`

---

## Coverage Check

| SC Tag | Covered by task(s) |
|--------|--------------------|
| SC-01 | T01, T02 |
| SC-02 | T02 |

> All tags covered: ✓ / ✗ (fill before plan is active)

---

## Task T01: {{Short descriptive title}}

**sc_refs:** [SC-01, SC-02]

**Description:** {{One paragraph. What this task accomplishes. What the system can do after it that it could not do before.}}

**Scope:** BE_ONLY / FE_ONLY / FULL_STACK

**Acceptance criteria:**
- [ ] SC-01: {{specific, testable condition derived from the AC}}
- [ ] SC-02: {{specific condition}}
- [ ] {{implementation criterion — e.g. "NestJS module created at src/modules/{{name}}/"}}

**Verification:**
- [ ] BE: `npx jest --testPathPattern={{module}}` passes
- [ ] FE: `npx vitest run --reporter=verbose` passes
- [ ] Type-check: `npx tsc --noEmit` clean
- [ ] Lint: `npx eslint src/` clean
- [ ] Manual: {{what to verify by looking at the running app or API}}

**Dependencies:** None / T{{N}}

**Files likely touched:**
- `src/modules/{{module}}/{{module}}.module.ts`
- `src/modules/{{module}}/{{module}}.service.ts`
- `src/modules/{{module}}/{{module}}.service.spec.ts`

**Status:** pending / in_progress / complete / blocked

**Size:** XS / S / M / L

---

## Task T02: {{Title}}

**sc_refs:** [SC-02]

**Description:** {{description}}

**Scope:** FE_ONLY

**Acceptance criteria:**
- [ ] SC-02: {{condition}}
- [ ] {{implementation criterion}}

**Verification:**
- [ ] FE: `npx vitest run` passes
- [ ] Storybook: story renders without errors
- [ ] A11y: keyboard nav works, no missing aria labels
- [ ] Manual: {{what to check in browser}}

**Dependencies:** T01

**Files likely touched:**
- `src/features/{{feature}}/{{Feature}}.tsx`
- `src/features/{{feature}}/{{Feature}}.test.tsx`
- `src/features/{{feature}}/schemas/{{feature}}.schema.ts`

**Status:** pending

**Size:** M

---

<!-- Repeat task block for each task -->

---

## Commit Convention

Each task → one commit:
```
feat({{feature-slug}}): {{task title}} [SC-01, SC-02]
```

## Run Status

- [ ] All tasks complete → ready for `/review:full`
- [ ] Partial — see `BLOCKERS.md` for blocked tasks
