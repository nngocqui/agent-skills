---
description: Generate a 9-section SPEC.md from a ticket requirement block. Gate 1 requires explicit human approval before status advances to approved.
---

Invoke `agent-skills:spec-driven-development` for the general spec process, then apply the pod format and Gate 1 rules below.

## Input

`$ARGUMENTS` is either:
- The output block from `/ticket` (paste directly), or
- A ClickUp task ID / Jira issue key (the command will call `/ticket` internally to fetch it first)

If no arguments: look for a ticket output block in the current conversation. If none found, ask: "Please run `/ticket <id>` first and paste the output here."

## What this command produces

`SPEC.md` at the project root, generated from `pod/templates/SPEC.md`.

## Process

### 1. Parse ticket output

From the `/ticket` output block, extract:
- Ticket ID → `clickup_task` or `jira_issue` frontmatter field
- Scope tag → `scope` field (`FE_ONLY` / `BE_ONLY` / `FULL_STACK`)
- Batch tag → note in §1
- SC-tagged ACs → §1 Story Summary table
- Description → §1 and §6 State & Data Flow
- API Spec (if present) → §4 API Contract skeleton
- Data Model (if present) → §3 Data Model skeleton
- Attachments → §2 Prototype Analysis

### 2. Generate SPEC.md

Copy `pod/templates/SPEC.md` and fill every `{{...}}` placeholder. Apply scope guards:

| Scope | Skip sections |
|-------|--------------|
| `FE_ONLY` | §3 Data Model → mark `N/A — FE_ONLY scope`; §4 API Contract → `N/A` |
| `BE_ONLY` | §5 FE Component Tree → mark `N/A — BE_ONLY scope` |
| `FULL_STACK` | Fill all sections |

For skeleton-be (BE sections):
- §3: Prisma schema additions with `@db.*` attributes
- §4: NestJS `{ success: boolean, data: T }` response envelope; include 400/401/403/404 error table
- §7: cite `src/modules/{{module}}/` test files and `test/*.e2e-spec.ts`

For skeleton-fe (FE sections):
- §5: `src/features/{{feature}}/` structure; Zod 4 schema with `z.object()`
- §6: React Hook Form → TanStack Query mutation → NestJS → Prisma → invalidate cache flow
- §7: cite `src/features/{{feature}}/*.test.tsx` and `tests/*.spec.ts` (Playwright)

Save §8 Open Questions with any ambiguities discovered during generation. Mark each one `Open`.

### 3. Present draft

Show the full SPEC.md to the user. State clearly:

```
SPEC.md draft generated. Status: draft

§8 Open Questions:
  1. [Open] <question>  ← resolve before Gate 1

Gate 1: To approve this spec and proceed to /tc and /plan:full,
reply with: "approve", "yes", or "go".
Hedged responses ("looks OK", "I guess", "probably fine") do NOT advance status.
```

### 4. Gate 1 — Human approval

Wait for the user's response.

- **Unambiguous affirmative** ("approve" / "yes" / "go" / "approved"): set `status: approved` in SPEC.md frontmatter, save the file, confirm: "SPEC.md approved. Run `/tc` to generate test cases."
- **Hedged response** ("looks reasonable", "I guess", "seems fine"): do NOT change status. Reply: "Status remains `draft`. Please reply with 'approve', 'yes', or 'go' to advance."
- **Question or change request**: answer the question / update the spec; re-present the draft; repeat from Step 3.
- **Unresolved §8 question**: if the user tries to approve while a question is still `Open`, stop: "Cannot approve: §8 has 1 unresolved question. Please resolve it first."

### 5. Save approved SPEC.md

Write the final `SPEC.md` to the project root with `status: approved`. Confirm path.

## Upstream reuse

This command builds on `agent-skills:spec-driven-development` (the general spec process, anatomy of a good spec, and spec-vs-vibe-coding principles). The pod layer adds:
- The 9-section format tied to skeleton-be/fe stacks
- The YAML frontmatter block
- Gate 1 enforcement
- Scope guards

Do not duplicate the upstream skill — reference it.

## Rules

1. Status never advances to `approved` without an unambiguous human affirmative
2. §8 must have zero `Open` questions before approval
3. SC tags from the ticket are never renumbered in the spec
4. `clickup_task` or `jira_issue` frontmatter must be populated (not empty)
5. Scope-guarded sections are marked `N/A — <scope> scope`, not deleted
