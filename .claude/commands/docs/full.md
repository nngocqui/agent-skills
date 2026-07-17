---
description: Shot 3 — gated documentation generation from implemented code. Gates: REVIEW.md verdict APPROVE + test coverage ≥ 85% on changed files. Writes README update, ARCHITECTURE.md ADR entry, and API_SPEC.md or COMPONENT_SPEC.md. Run in a fresh session after /review:full.
---

Read and follow `pod/skills/3-shot-docs/SKILL.md`.

## Session rule

Run in a **fresh Claude Code session** — never the same session as `/impl:full` or `/review:full`. Open a new terminal and execute `/docs:full` there.

## What this command does

1. **Gate A:** reads `REVIEW.md` — must have verdict `APPROVE` (or `MINOR` with confirmed fixes)
2. **Gate B:** runs coverage — changed files must all be ≥ 85%
3. **Reads code** from the filesystem (not chat history)
4. **Generates:**
   - `README.md` update — feature description from user perspective
   - `ARCHITECTURE.md` — new ADR entry with decisions and rationale
   - `API_SPEC.md` (BE) or `COMPONENT_SPEC.md` (FE) — interface spec from actual code

## Usage

```
/docs:full
```

No arguments. Reads all inputs from the project root.

## Gates (hard stops)

| Gate | Condition | Fail message |
|------|-----------|--------------|
| **A — Review** | `REVIEW.md` verdict is `APPROVE` | "REVIEW.md verdict is {{verdict}}. Fix issues and re-run /review:full." |
| **B — Coverage** | All changed files ≥ 85% statements | "Coverage gate failed: {{file}} at {{N}}%" |

Both gates must pass. Either failure stops the command immediately.

## Outputs

| Artifact | Where | What |
|----------|-------|------|
| `README.md` | project root | Feature section added/updated |
| `ARCHITECTURE.md` | project root | New ADR entry (create if missing) |
| `API_SPEC.md` | project root | BE: NestJS endpoints with DTOs (from actual code) |
| `COMPONENT_SPEC.md` | project root | FE: Components with Zod prop types, design tokens used, and motion/copy patterns (from actual code) |

## What docs must reflect

Docs are derived from the **implemented code**, not from:
- The SPEC.md contract (may have changed during implementation)
- Chat history or memory of the implementation session
- What you intended to build

If the implementation deviates from SPEC.md, flag it with `⚠️ Deviation from §N: ...` in the relevant artifact.

## FE: design plan in docs

If `design-plan.md` exists at the project root:

- **ARCHITECTURE.md ADR**: include a "Design decisions" subsection summarising the palette, type stack, and signature element chosen, with a one-sentence rationale for each. This captures *why* the design looks the way it does — the same information will be invisible from the code alone.
- **COMPONENT_SPEC.md**: for each component, list which design tokens it uses (`color-primary`, `color-surface`, etc.) and note any motion present (`prefers-reduced-motion` status). This makes token usage auditable without reading every CSS file.

If no `design-plan.md` exists and the feature contains new pages or views, add a `⚠️ No design plan found` note at the top of COMPONENT_SPEC.md.

## See Also

- [[3-shot-docs]] — full process (`pod/skills/3-shot-docs/SKILL.md`)
- [[3-shot-gates]] — Shot 2→3 gate conditions
- [[3-shot-loop|pod/docs/3-shot-loop.md]] — full loop map
- `agent-skills:documentation-and-adrs` — upstream ADR principles
