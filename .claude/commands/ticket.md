---
description: Fetch a ClickUp or Jira ticket, validate ACs, assign SC tags, and output a structured requirement block ready for /spec:full
---

Read and follow `pod/skills/ticket-intake/SKILL.md`.

`$ARGUMENTS` is the ticket ID or URL:
- ClickUp: numeric ID, `#XXXXXXXX`, or URL containing `/t/`
- Jira: `PROJECT-NNN` key (e.g. `PROJ-42`)

## What this command does

1. **Detects** the ticket source from the ID format
2. **Fetches** the ticket via MCP (ClickUp or Atlassian)
3. **Validates** every AC for specificity and measurability
4. **Stops** with an enrichment request if any AC is sparse (AC count < 2, or any AC lacks a measurable condition)
5. **Assigns** SC-01, SC-02, … to each AC in order
6. **Outputs** a structured requirement block ready to pass into `/spec:full`

## Usage

```
/ticket 86abc1234              # ClickUp task ID
/ticket PROJ-42                # Jira issue key
/ticket https://app.clickup.com/t/86abc1234
```

## Output

A markdown block:

```
## Ticket: <ID> — <Title>
Source / Scope / Batch / Attachments
Story (user-story format)
Description
Acceptance Criteria (SC-tagged)
API Spec (if present)
Data Model (if present)
```

Pass this block as input to `/spec:full` to generate the 9-section SPEC.md.

## Jira note

The Atlassian MCP requires authentication. If this is your first Jira ticket this session, you may be prompted to authenticate. Follow the prompt, then re-run `/ticket`.

## Sparse ticket behaviour

If ACs are too vague to test, this command stops and lists exactly which ACs need enrichment and why. It does **not** proceed to output until all ACs are specific and measurable. Update the ticket (or provide enriched versions in chat) and re-run.
