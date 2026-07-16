---
name: ticket-intake
phase: define
tags: [ticket, ac-validation, sc-tags, requirements, clickup, jira]
triggers:
  - Starting work on a new story from a ClickUp or Jira ticket
  - Before running /spec:full on a ticket-sourced story
related:
  - test-case-engineering
  - spec-driven-development
description: Reads a ClickUp or Jira ticket, validates AC completeness, enriches sparse tickets, and assigns SC tags to each acceptance criterion. Use when starting a new story from a ticket before running /spec:full.
---

# Ticket Intake

## Overview

Reads a ticket from ClickUp or Jira, validates that its acceptance criteria are specific and measurable, enriches any sparse ACs before proceeding, and produces a structured requirement block with SC tags assigned. The output feeds directly into `/spec:full`.

The AC field is load-bearing. A vague ticket produces a vague spec which produces wrong code. This skill enforces quality at the source — before any spec is written.

## When to Use

- Starting work on a new story from a ClickUp or Jira ticket
- Before running `/spec:full`
- When a PM or BA has written a ticket and you need to convert it into a traceable requirement block

**When NOT to use:** If requirements are already in a SPEC.md. Use `/spec:full` directly in that case.

## Source Detection

Detect the ticket source from the ID format passed in `$ARGUMENTS`:

| Format | Source | MCP tool |
|--------|--------|----------|
| Numeric string (`86abc123`), URL containing `/t/`, or `#XXXXXXXX` | ClickUp | `mcp__claude_ai_ClickUp__clickup_get_task` |
| `PROJECT-NNN` key (letters-hyphen-number, e.g. `PROJ-42`) | Jira | Atlassian MCP — note: requires `mcp__claude_ai_Atlassian__authenticate` if not already authenticated this session |

If the format is ambiguous, ask the user: "Is this a ClickUp ID or a Jira issue key?"

## Process

### Step 1: Fetch

**ClickUp:** Call `mcp__claude_ai_ClickUp__clickup_get_task` with the task ID. Extract:
- `name` → story title (must be user-story format: "As a … I want … so that …")
- `description` → detailed user flow
- `custom_fields` or `description` → acceptance criteria list
- Tags → scope hint (`fe`, `be`, `fullstack`) and batch name
- Attachments → wireframe/mockup URLs

**Jira:** Call the Atlassian MCP to fetch the issue. Extract equivalent fields. If auth is needed, stop and tell the user: "Run `/jira-auth` or authenticate via the Atlassian MCP first, then re-run `/ticket`."

### Step 2: Validate AC Completeness

For each AC, check:
- [ ] Has a measurable condition (not just "make it secure" or "improve performance")
- [ ] References a specific UI element, field, API response, or behaviour
- [ ] Is independently testable (can you write a Given/When/Then for it?)

**Sparse ticket rule:** If any AC fails the checks above, or AC count < 2:

```
SPARSE TICKET DETECTED

The following ACs need enrichment before a spec can be derived:

  AC 2: "Make the login more secure."
  → Problem: no measurable condition. What does "secure" mean here?
  → Suggestion: "Max 5 login attempts per IP per 15 min; return 429 with Retry-After header"

  AC 3: "Improve performance."
  → Problem: no threshold. Improve from what to what?
  → Suggestion: "Response time < 200ms at p95 under 100 concurrent users"

Please update the ticket ACs and re-run /ticket, or provide enriched versions here.
```

> [!WARNING]
> Do NOT proceed to SC tag assignment or output until all ACs are specific and measurable. A vague AC produces wrong code that passes review.

### Step 3: Validate Story Title

The title must follow the user-story format:
```
As a <role>, I want <capability>, so that <benefit>.
```

If it doesn't, suggest a rewrite and confirm with the user before proceeding.

### Step 4: Assign SC Tags

Assign SC tags in order of appearance:

```
First AC  → SC-01
Second AC → SC-02
Third AC  → SC-03
```

Tags are permanent. If an AC is later removed during spec review, mark it `Removed` — do not renumber remaining tags.

### Step 5: Determine Scope

Set scope from ticket tags:

| Ticket tag(s) | Scope |
|--------------|-------|
| `fe` only | `FE_ONLY` |
| `be` only | `BE_ONLY` |
| `fullstack`, both, or absent | `FULL_STACK` |

### Step 6: Output Structured Requirement Block

```markdown
## Ticket: <ID> — <Title>

**Source:** ClickUp | Jira
**Scope:** FE_ONLY | BE_ONLY | FULL_STACK
**Batch:** <batch-tag or "none">
**Attachments:** <URL(s) or "none">

### Story
As a <role>, I want <capability>, so that <benefit>.

### Description
<detailed user flow from the ticket — keep verbatim>

### Acceptance Criteria (SC-tagged)
- **SC-01:** <AC text — verbatim from ticket or enriched>
- **SC-02:** <AC text>
- **SC-03:** <AC text>

### API Spec (if present in ticket)
<endpoint definitions or "Not specified">

### Data Model (if present in ticket)
<schema hints or "Not specified">
```

Hand this block to `/spec:full` as input.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The ACs are good enough to start with" | If you can't write a Given/When/Then for an AC, neither can the agent. Fix it now. |
| "We'll clarify during implementation" | Clarifying during implementation means rework. The spec is cheaper to change than code. |
| "The title is close enough to user-story format" | The "so that" clause captures the business reason. Without it, the agent doesn't know what to trade off when ACs conflict. |
| "Let me just skip to the spec for a simple ticket" | Simple tickets are quick to validate. The check costs 30 seconds; a vague spec costs hours. |

## Red Flags

- Fewer than 2 ACs
- ACs containing "improve", "better", "faster", "more secure" with no measurable threshold
- No scope tag on a ticket that touches both FE and BE
- Story title in the format "{{Feature name}}" instead of "As a … I want … so that …"
- Attachments referenced in description but not linked

## Verification

After completing, confirm:

- [ ] Story title is in user-story format
- [ ] Every AC has a measurable condition
- [ ] SC tags assigned in order (SC-01, SC-02, …)
- [ ] Scope is set (FE_ONLY / BE_ONLY / FULL_STACK)
- [ ] Output block is ready to paste into `/spec:full`
- [ ] No sparse ACs remain

## See Also

- [[sc-tag-system]] — SC tag convention and traceability chain
- [[test-case-engineering]] — next skill after `/spec:full` completes
- `/spec:full` — next command after this skill produces its output block
- `pod/templates/SPEC.md` — the artifact `/spec:full` generates
