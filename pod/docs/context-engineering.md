# Context Engineering

How the harness manages what Claude Code sees per story to prevent context saturation and oracle collapse.

## The problem

A Claude Code session has a finite context window. In a multi-story implementation run (`/impl:full --auto`), loading the entire codebase upfront would:
1. Saturate the context window by story 3–4 of a 10-story plan
2. Cause the model to hallucinate connections between unrelated modules
3. Make `/review:full` score review-its-own-work (oracle collapse) if run in the same session

The harness uses three techniques to prevent this.

## Technique 1: JIT context loading per story

Instead of reading all relevant files at session start, `/impl:full` loads only the files needed for the current story:

1. Read PLAN.md to get the current task's `sc_refs`
2. Read SPEC.md §1 for only those SC tags' AC text
3. Read `pod/templates/discovery-map.md` (filled by the human or `/plan:full`) for the specific file paths that story touches
4. Read only those files — not the whole module

**Result:** each story starts with a focused, minimal context. The discovery map is the key to making this work.

## Technique 2: The discovery map

`pod/templates/discovery-map.md` is filled once per feature before implementation starts. It maps:
- Which PLAN.md tasks touch which source files
- Which SC tags are satisfied by which files
- Which shared modules need to be read as context (but not changed)

The map is created during `/plan:full` or filled manually in the discovery session before `/impl:full`. It is not generated during implementation — that would defeat its purpose.

**Format:** see `pod/templates/discovery-map.md` for the template.

**When to fill it:** after `/plan:full` completes, before the first `/impl:full` run.

## Technique 3: Session isolation (oracle collapse prevention)

Each shot runs in a fresh Claude Code session:

| Shot | Session | Why |
|------|---------|-----|
| `/impl:full` | Session 1 | Implementation context |
| `/review:full` | Session 2 (fresh) | Cannot review its own work |
| `/docs:full` | Session 3 (fresh) | Reads code, not memory |

A fresh session means:
- No memory of what was written in Session 1
- The model reads code from disk, not from context
- Review scores reflect the code, not the intent

**How to open a fresh session:** `Ctrl+N` in Claude Code desktop, or `claude` in a new terminal.

## What "context saturation" looks like

Symptoms that context is saturated (stop and start a fresh session):
- Model references code it hasn't been asked to read
- Model "recalls" an earlier error when none exists
- Review scores are inexplicably high (model knows it wrote the code)
- Fix loop doesn't converge — model applies the same wrong fix repeatedly

## How to use the discovery map in practice

### Step 1: After /plan:full

The discovery map template is at `pod/templates/discovery-map.md`. Copy it to the feature root:

```bash
cp "C:/Qui Nguyen/ai-pod/agent-skills/pod/templates/discovery-map.md" ./discovery-map.md
```

Fill the SC Tag → File Map section. This takes 5–10 minutes but saves context window per story.

### Step 2: Before /impl:full

Tell Claude Code:

> "Read discovery-map.md. We are implementing SC-01 only. Load only the files listed for SC-01 in the SC Tag → File Map."

### Step 3: Per story in /impl:full --auto

The `/impl:full` command reads the discovery map automatically (Step 3 of the per-story loop in `pod/skills/3-shot-docs/SKILL.md`). No manual intervention needed in auto mode.

## Discovery map is not an implementation plan

The discovery map tells you WHAT FILES are involved. PLAN.md tells you WHAT TO DO. Keep them separate:
- Discovery map: read-only context pointer (filled once, updated if files move)
- PLAN.md: task definitions with acceptance criteria and sc_refs

## BE vs FE context budgets

**BE stories (NestJS/Prisma):** a typical story touches 4–6 files (DTO, command/query, handler, controller, spec file, optional migration). Read only those.

**FE stories (React):** a typical story touches 3–8 files (schema, hook, component(s), story, test, locale key, route if new). The shared modules (axios, query-client, constants) are context-read but never modified within a story.

If a story touches more than 10 files, consider splitting it. The discovery map is the forcing function — if you can't write the map for a story, the story is too big.

## When not to use a discovery map

- One-off bug fixes (load the bug file + one context file)
- SPEC.md or PLAN.md generation (these read the ticket, not the codebase)
- `/review:full` (reads the diff, not individual files)

The discovery map is for multi-story feature implementation only.
