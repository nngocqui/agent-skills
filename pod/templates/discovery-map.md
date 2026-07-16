---
# Discovery Map — {{feature_slug}}
# scope: BE_ONLY | FE_ONLY | FULL_STACK
# Fill this before running /impl:full. The impl command loads only the sections
# relevant to each story to avoid saturating the context window.
---

# Discovery Map: {{feature_slug}}

**Scope:** {{BE_ONLY | FE_ONLY | FULL_STACK}}  
**Feature slug:** {{feature_slug}}  
**SPEC.md:** `{{path/to/SPEC.md}}`

---

## BE Module Map
<!-- Skip this section entirely for FE_ONLY scope -->

### Domain module
- **Module file:** `src/{{domain}}/{{domain}}.module.ts`
- **Controller:** `src/{{domain}}/{{domain}}.controller.ts`
- **Commands:** `src/{{domain}}/commands/`
- **Queries:** `src/{{domain}}/queries/`
- **DTOs:** `src/{{domain}}/dto/`
- **Prisma model:** `prisma/schema.prisma` — `model {{ModelName}}`

### Related modules to read (for context, not to change)
- `src/auth/` — guard imports
- `src/common/guards/` — `JwtAuthGuard`, `RolesGuard`
- `src/common/interceptors/` — `TransformInterceptor` (response envelope)
- `src/common/filters/` — `GlobalExceptionFilter` (error codes)

### Prisma
- Schema file: `prisma/schema.prisma`
- Migration baseline: most recent migration in `prisma/migrations/`
- Seed: `prisma/seed.ts` (reference for insert patterns)

### Test files
- Unit: `src/{{domain}}/*.spec.ts`
- E2E: `test/{{domain}}.e2e-spec.ts`
- Test helper (app factory): `test/app.e2e-setup.ts` (if exists)

### Environment
- `DATABASE_URL` — from `.env.local` or Docker compose
- `JWT_SECRET`, `REFRESH_TOKEN_SECRET` — required for guard tests

---

## FE Module Map
<!-- Skip this section entirely for BE_ONLY scope -->

### Feature directory
- **Feature root:** `src/features/{{feature}}/`
- **Index component:** `src/features/{{feature}}/index.tsx`
- **API functions:** `src/features/{{feature}}/api/index.ts`
- **Types:** `src/features/{{feature}}/api/types.ts`
- **Components:** `src/features/{{feature}}/components/`
- **Hooks:** `src/features/{{feature}}/hooks/`
- **Schemas:** `src/features/{{feature}}/schemas/` ← Zod schemas (prop source of truth)

### Shared modules to read (for context, not to change)
- `src/lib/axios.ts` — HTTP client (do not create a new axios instance)
- `src/lib/query-client.ts` — QueryClient config (do not modify)
- `src/constants/QUERY_KEYS.ts` — add new keys here
- `src/store/auth-store.ts` — auth state (use `useAuthStore()`)
- `src/components/auth-guard.tsx` — wrap protected routes
- `src/locales/en.json`, `src/locales/th.json` — i18n keys

### Related routes
- Route definition: `src/App.tsx` — add lazy route here
- Protected route wrapper: `<AuthGuard>` in `src/components/auth-guard.tsx`

### Test files
- Unit: `src/features/{{feature}}/**/*.test.tsx`
- MSW handlers: `src/test/msw/handlers.ts` — add feature mocks here
- Storybook: `src/features/{{feature}}/**/*.stories.tsx`

### Environment
- `VITE_API_URL` — base URL for all API calls (via `src/lib/axios.ts`)
- OIDC vars: see `.env.example` (tests use MSW, not real OIDC)

---

## SC Tag → File Map

| SC Tag | AC Summary | BE file(s) | FE file(s) |
|--------|-----------|------------|------------|
| SC-01  | {{AC text}} | `src/.../...ts` | `src/.../...tsx` |
| SC-02  | {{AC text}} | — | `src/.../...tsx` |
| SC-03  | {{AC text}} | `src/.../...ts` | — |

Fill this table when `/plan:full` generates PLAN.md. The `/impl:full` command reads this map per story to load only the relevant files into context (JIT context loading).

---

## Notes

<!-- Anything that surprised you during discovery: migration blockers, deprecated patterns, non-obvious dependencies -->

- 
