# Stack Conventions

Shared naming and style conventions for projects using the NestJS + React skeleton stack.
Project-specific rules in each project's `CLAUDE.md` take precedence over anything here.

## Package manager

Use **pnpm** for all installs. Never commit a `package-lock.json` or `yarn.lock`.

```bash
pnpm install
pnpm add <pkg>
pnpm add -D <pkg>
```

## Naming conventions

| Item | Convention | Example |
|------|-----------|---------|
| Files | `kebab-case` | `user.service.ts` |
| Folders | `kebab-case` | `user-profile/` |
| Classes | `PascalCase` | `UserService` |
| Interfaces | `PascalCase` | `UserRepository` |
| Types | `PascalCase` | `CreateUserDto` |
| Enums | `PascalCase` | `UserRole` |
| Enum values | `UPPER_SNAKE_CASE` | `ADMIN`, `SUPER_ADMIN` |
| Variables | `camelCase` | `currentUser` |
| Functions | `camelCase` | `findUserById()` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT` |
| Database tables | `snake_case` (plural) | `users`, `order_items` |
| Database columns | `snake_case` | `created_at` |
| Prisma models | `PascalCase` (singular) | `User`, `OrderItem` |
| Environment variables | `UPPER_SNAKE_CASE` | `DATABASE_URL` |

Additional rules:
- Do not prefix interfaces with `I` — `UserRepository` not `IUserRepository`
- Boolean variables use `is` / `has` / `can` prefix — `isAuthenticated`, `hasPermission`
- Generic type params: single uppercase letter or descriptive noun — `T`, `TData`, `TError`

## Git commit format

```
<type>(<scope>): <short description> [SC-01, SC-02]
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.
Scope: feature slug or module name (e.g., `auth`, `user-profile`, `dashboard`).
SC tags required when a PLAN.md task is in scope.

---

## Backend (NestJS) naming

### Files

All files use `kebab-case` with a dot-separated type suffix:

```
user.module.ts
user.controller.ts
user.service.ts
user.repository.ts          # optional repository layer
create-user.dto.ts
update-user.dto.ts
user-response.dto.ts
jwt-payload.type.ts
roles.guard.ts
current-user.decorator.ts
create-user.command.ts
create-user.handler.ts
get-users.query.ts
get-users.handler.ts
user.spec.ts                # unit test alongside source
user.e2e-spec.ts            # e2e test under test/
```

### Classes and CQRS

| Construct | Pattern | Example |
|-----------|---------|---------|
| Module | `<Entity>Module` | `UserModule` |
| Controller | `<Entity>Controller` | `UserController` |
| Service | `<Entity>Service` | `UserService` |
| Repository | `<Entity>Repository` | `UserRepository` |
| Request DTO | `<Action><Entity>Dto` | `CreateUserDto`, `UpdateUserDto` |
| Response DTO | `<Entity>ResponseDto` | `UserResponseDto` |
| Command | `<Action><Entity>Command` | `CreateUserCommand` |
| Query | `<Action><Entity>Query` | `GetUsersQuery`, `GetUserByIdQuery` |
| Handler | `<Action><Entity>Handler` | `CreateUserHandler`, `GetUsersHandler` |
| Event | `<Entity><Action>Event` | `UserCreatedEvent` |
| Exception | `<Entity><Reason>Exception` | `UserNotFoundException` |

### Database (Prisma)

- Model names: `PascalCase` singular — `User`, `RefreshToken`
- Table names: Prisma defaults to `snake_case` plural — `users`, `refresh_tokens`
- Column names: `snake_case` in the DB; Prisma maps to `camelCase` in code via `@map`/`@@map` when needed
- Relations: named after the related model, camelCase — `user`, `posts`

---

## Frontend (React) naming

### Files and directories

```
src/features/<feature-name>/          # kebab-case feature directory
  index.tsx                           # default export: <FeatureName> (PascalCase)
  api/
    index.ts                          # named exports: getUser(), createUser()
    types.ts                          # FeatureDto types
  components/
    <component-name>.tsx              # kebab-case file, PascalCase export
    index.ts                          # barrel re-export
  hooks/
    use-<hook-name>.ts                # kebab-case file
    index.ts
  schemas/
    <feature-name>.schema.ts          # Zod schemas
```

### Components and pages

| Construct | File name | Export name |
|-----------|-----------|-------------|
| Component | `user-card.tsx` | `UserCard` |
| Page/route | `user-profile-page.tsx` | `UserProfilePage` |
| Layout | `dashboard-layout.tsx` | `DashboardLayout` |
| Provider | `theme-provider.tsx` | `ThemeProvider` |

### Hooks

File: `use-<name>.ts` → export: `use<Name>`

```ts
// use-user-profile.ts
export function useUserProfile(userId: string) { ... }
```

### Zustand stores

File: `<name>-store.ts` → export: `use<Name>Store`

```ts
// auth-store.ts
export const useAuthStore = create<AuthState>(...)
```

### Types and interfaces

Suffix with the role of the type:

| Role | Suffix | Example |
|------|--------|---------|
| API response shape | `Dto` | `UserDto` |
| API request payload | `Payload` | `CreateUserPayload` |
| Component props | `Props` | `UserCardProps` |
| Zustand state | `State` | `AuthState` |
| Table row | `Row` | `UserTableRow` |
| Form values | `FormValues` | `LoginFormValues` |

### Constants

```ts
// src/constants/QUERY_KEYS.ts
export const QUERY_KEYS = {
  USERS: ['users'] as const,
  USER_BY_ID: (id: string) => ['users', id] as const,
}

// src/constants/ROUTES.ts
export const ROUTES = {
  HOME: '/',
  USERS: '/users',
  USER_DETAIL: (id: string) => `/users/${id}`,
}
```

Module-level constants that are not route/query-key objects: `UPPER_SNAKE_CASE`.

### Test files

| Test type | Location | File name |
|-----------|----------|-----------|
| Unit / component | Co-located with source | `user-card.test.tsx` |
| Playwright E2E | `e2e/` at project root | `user-profile.spec.ts` |
| Storybook | Co-located with component | `user-card.stories.tsx` |
