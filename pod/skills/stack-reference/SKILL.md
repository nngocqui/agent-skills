---
name: stack-reference
phase: build
tags: [context7, docs, library-reference, stack, api-lookup, version-accurate]
triggers:
  - About to use a library API that has changed between major versions
  - Hitting a type error or API mismatch that suggests stale training-data knowledge
  - Implementing a feature in a library where version-specific behaviour matters
related:
  - incremental-implementation
  - debugging-and-error-recovery
description: Resolves current, version-accurate documentation for a library in the project stack using Context7 MCP. Use when about to implement an unfamiliar API call, when a library has known major-version breaking changes, or when a type error suggests the training-data snapshot of an API is stale. Do NOT invoke for stable, well-known patterns (basic React hooks, standard Prisma CRUD) where training data is clearly sufficient.
---

# Stack Reference

## Overview

Fetches current documentation for a specific library at its pinned version before implementing an API call, using the Context7 MCP server. Prevents implementing against a stale training-data snapshot of a library that has since changed.

The skill is narrow and on-demand — it resolves one library + one topic per invocation. Do not use it as a general doc browser. Invoke it only when the implementation decision actually depends on version-specific behaviour.

## When to Use

- About to write a call to a library API that changed in a major version upgrade (see Known Gotchas below)
- A `tsc` error message references a type that looks unfamiliar or doesn't match expected shape
- A test failure message says a function or option does not exist
- Implementing a Prisma migration, NestJS guard, Orval-generated hook, or TanStack Query call where the exact signature matters

**When NOT to use:**
- Standard React patterns (`useState`, `useEffect`, basic JSX) — training data is sufficient
- Tailwind class names — stable; use IDE autocomplete
- Simple Prisma CRUD (`findMany`, `create`, `update`) with no relation or transaction complexity
- Any API you used successfully in a previous task in the same session — the result is already in context

## Setup Requirement

This skill requires the Context7 MCP server to be configured in `.claude/settings.json`:

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

If Context7 is not configured, fall back to the library's official docs URL and note: "Context7 not available — manual doc lookup required."

## Process

### Step 0 — Verify Context7 is available

Check `.claude/settings.json` for an `mcpServers.context7` entry. If it is absent or the MCP call fails:
- Note: "Context7 not configured — falling back to manual lookup."
- Find the library's official docs URL and read the version-specific section manually.
- Do not proceed with Steps 3–4; apply whatever you find to the implementation and note the limitation.

### Step 1 — Identify library + topic

From the current task, state precisely:
- **Library name**: the npm package name (e.g., `@tanstack/react-query`, `prisma`, `@nestjs/core`)
- **Topic**: the specific API surface needed (e.g., `useQuery options`, `migrate dev`, `UseGuards`)

Keep the topic narrow. "TanStack Query" is too broad. "useQuery v5 isPending vs isLoading" is right.

### Step 2 — Read the pinned version

Read the relevant `package.json` to get the exact installed version:

```
dependencies / devDependencies → "@tanstack/react-query": "^5.17.0"
```

Strip the `^` or `~` — use the numeric version (`5.17.0`) for the Context7 call.

### Step 3 — Resolve the library ID

Call `mcp__context7__resolve-library-id` with the library name:

```
tool: mcp__context7__resolve-library-id
args: { libraryName: "@tanstack/react-query" }
```

The response returns a Context7-compatible library ID (e.g., `/tanstack/query`). Use this ID in Step 4. If multiple matches are returned, pick the one whose description best matches the framework (React, not Svelte or Vue).

### Step 4 — Fetch docs

Call `mcp__context7__get-library-docs` with the resolved ID, pinned version, and narrow topic:

```
tool: mcp__context7__get-library-docs
args: {
  context7CompatibleLibraryID: "/tanstack/query",
  version: "5.17.0",
  topic: "useQuery isPending isLoading migration from v4"
}
```

### Step 5 — Extract and apply

From the returned docs, extract only the specific API signatures, option names, and behaviour relevant to the current task. Do not load the full doc dump into working context.

Apply immediately to the implementation. Do not invoke the skill again for the same library + topic in the same session — the result is already available.

## Known Gotchas by Library

High-value invocation targets — training data is most likely to be stale here:

| Library | Version change | What changed |
|---|---|---|
| `@tanstack/react-query` | v4 → v5 | `isLoading` renamed to `isPending`; `onSuccess`/`onError`/`onSettled` removed from `useQuery`; `cacheTime` renamed `gcTime`; `useQuery` options restructured |
| `@tanstack/react-query` | v4 → v5 | `QueryClient` constructor options changed; `keepPreviousData` → `placeholderData: keepPreviousData` |
| `prisma` | v4 → v5 | `rejectOnNotFound` removed; `findUnique` strictened; `jsonProtocol` default on |
| `@nestjs/core` | v9 → v10 | `@Module` circular dep resolution changed; some decorator metadata keys shifted |
| `orval` | any | Generated hook signatures depend entirely on the local `openapi.json` — always check `src/api/generated/` before writing a custom hook |
| `vitest` | v0 → v1 | Config file resolution changed; some matcher names updated |
| `playwright` | v1.3x → v1.4x | `page.locator` API recommended over `page.$`; `toHaveURL` matcher added |

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I know this library well enough" | TanStack Query v5 broke nearly every option name from v4. "Knowing the library" means knowing the version in `package.json`, not the version in training data. |
| "The type error will tell me if I'm wrong" | A wrong API call often compiles fine and fails at runtime or in tests. The type error is the recovery path, not the prevention. |
| "It's just one option name, I'll guess" | Guessing `cacheTime` instead of `gcTime` causes a silent no-op. The docs call costs 2 seconds; the debug session costs 20 minutes. |
| "I'll look it up if the test fails" | Invoking the skill before writing is cheaper than invoking it after a red test and a fix loop iteration. |

## Red Flags

- Implementing TanStack Query hooks without checking the v5 option names
- Writing Prisma queries with `rejectOnNotFound` (removed in v5)
- Writing a custom hook when an orval-generated one exists and covers the endpoint
- Using `page.$` in Playwright tests (deprecated in favour of `page.locator`)
- A fix-loop iteration whose root cause is "wrong option name" — this skill should have been invoked before step C

## Verification

After fetching docs and applying them:

- [ ] Library ID resolved from `package.json` version, not assumed
- [ ] Topic was narrow enough to return actionable docs (not the whole library reference)
- [ ] Implementation uses the API signatures from the returned docs, not from training memory
- [ ] No second invocation for the same library + topic in this session
