---
schema_version: 2
artifact_kind: story
clickup_task: ""
jira_issue: ""
feature_slug: "{{kebab-case-feature-name}}"
status: draft
scope: FULL_STACK
traits: []
approved_mode: manual
---

# Spec: {{Story Title}}

> **Gate 1** — `status` may only move `draft → approved` via explicit human affirmative ("approve" / "yes" / "go").
> Hedged responses do not advance status. All §8 Open Questions must be Resolved before Gate 1 can pass.

---

## §0 Dependencies

> Models, services, and endpoints this story depends on but does not own.

**Models inherited:**
- `{{ModelName}}` — owned by `{{module}}`

**Endpoints consumed:**
- `{{METHOD /path}}` — from `{{service}}`

**FE libraries assumed:**
- (list any shadcn/ui components, TanStack Query keys, Zustand slices reused)

---

## §1 Story Summary

> Required / Optional / Conditional fields. Each Acceptance Criterion carries its SC tag.
> SC tags are assigned at ticket intake and never renumbered.

**As a** {{role}}, **I want** {{capability}}, **so that** {{benefit}}.

### Acceptance Criteria

| Tag | Criterion | Type |
|-----|-----------|------|
| SC-01 | {{AC text — specific, measurable, testable}} | Required |
| SC-02 | {{AC text}} | Required |
| SC-03 | {{AC text}} | Optional |
| SC-04 | {{AC text — e.g. "field shows only when parent = Others"}} | Conditional |

### Conditional Logic
- SC-04 activates when: {{condition}}

---

## §2 Prototype Analysis

> Review any existing prototype, mockup, or legacy implementation. Decide what to keep, discard, or build fresh.

| Area | Decision | Rationale |
|------|----------|-----------|
| {{component / pattern}} | Keep / Discard / Build fresh | {{why}} |

**Wireframe / Mockup links:** {{URL or "None"}}

---

## §3 Data Model

> New fields, schema changes, Prisma migrations. Omit for FE_ONLY scope.

**New Prisma model / fields:**
```prisma
// {{ModelName}} additions
{{field}}  {{Type}}  {{attributes}}
```

**Migration required:** Yes / No
**Migration notes:** {{e.g. "backfill default value for existing rows"}}

---

## §4 API Contract

> Binding FE ↔ BE interface. All responses use `{ success: boolean, data: T }` envelope.
> Omit for FE_ONLY scope.

### `{{METHOD /api/path}}`

**Request:**
```typescript
interface {{RequestDto}} {
  {{field}}: {{type}};  // required / optional
}
```

**Response (200):**
```typescript
interface {{ResponseDto}} {
  success: true;
  data: {
    {{field}}: {{type}};
  };
}
```

**Error responses:**
| Status | Code | Condition |
|--------|------|-----------|
| 400 | `VALIDATION_ERROR` | {{when}} |
| 401 | `UNAUTHORIZED` | Missing/invalid JWT |
| 403 | `FORBIDDEN` | Insufficient role |
| 404 | `NOT_FOUND` | {{when}} |

---

## §5 FE Component Tree

> Files, props, and Zod schemas. Zod schemas are the source of truth for props.
> Omit for BE_ONLY scope.

```
src/features/{{feature}}/
├── {{FeaturePage}}.tsx            — route-level component
├── components/
│   └── {{SubComponent}}.tsx
├── hooks/
│   └── use{{Feature}}.ts         — TanStack Query hook
├── store/
│   └── {{feature}}Store.ts       — Zustand slice (if UI state needed)
└── schemas/
    └── {{feature}}.schema.ts     — Zod schemas (source of truth)
```

**Zod schema:**
```typescript
export const {{featureSchema}} = z.object({
  {{field}}: z.{{type}}(),
});
export type {{Feature}} = z.infer<typeof {{featureSchema}}>;
```

---

## §6 State & Data Flow

> How data moves through the system. Keep to a sequence or bullet list.

```
User action
  → React Hook Form (validates via Zod schema)
  → TanStack Query mutation (POST /api/{{path}})
  → NestJS controller → CQRS command handler
  → Prisma write → PostgreSQL
  → Response → invalidate query cache
  → UI re-renders from fresh query
```

**Zustand slice** (if needed): {{what UI state it manages, or "None"}}
**Socket.io event** (if real-time): {{event name, or "None"}}

---

## §7 Test Scope

> One entry per SC tag. Each tag gets unit + integration + e2e coverage as applicable.
> This section drives TC.md generation.

| Tag | What to test | FE | BE | E2E |
|-----|-------------|----|----|-----|
| SC-01 | {{what behavior is verified}} | ✓ | ✓ | ✓ |
| SC-02 | {{what behavior is verified}} | ✓ | — | — |
| SC-03 | {{what behavior is verified}} | — | ✓ | — |
| SC-04 | {{conditional — show/hide}} | ✓ | — | — |

**BE test files:** `src/modules/{{module}}/{{module}}.service.spec.ts`, `test/{{module}}.e2e-spec.ts`
**FE test files:** `src/features/{{feature}}/{{Feature}}.test.tsx`
**E2E:** `tests/{{feature}}.spec.ts` (Playwright)

---

## §8 Open Questions

> Each question must be stamped Resolved before Gate 1 can pass.

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | {{question}} | {{name}} | Open / **Resolved: {{answer}}** |

---

## §9 Docs Found

> Existing patterns and code this story can reuse. File:line references.

| Pattern | Location | Reuse |
|---------|----------|-------|
| {{pattern name}} | `src/{{path}}:{{line}}` | Copy / Adapt / Reference |
