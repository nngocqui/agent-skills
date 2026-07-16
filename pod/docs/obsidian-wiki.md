# Obsidian Wiki Conventions

This harness uses Obsidian-inspired conventions for skill/rule/command authoring. The goal: every file is a self-contained note with explicit, navigable connections to related notes.

---

## Core Concept

Obsidian treats a folder of Markdown files as a **vault** where notes are connected by links. The value isn't in any single note — it's in the graph of connections. Applied here:

- Skills, rules, commands, and docs are **atomic notes** (one concern per file)
- The connections between them are **explicit** (wikilinks, not prose mentions)
- The [[3-shot-loop]] doc is the **MOC** (Map of Content) — the entry point for navigation
- Frontmatter properties make the graph **machine-queryable**

---

## Applied Patterns

### 1. Rich Frontmatter

Every pod skill carries structured properties beyond `name` and `description`:

```yaml
---
name: skill-name
phase: define | plan | build | verify | review | ship
tags: [keyword, keyword, ...]
triggers:
  - Condition that activates this skill
  - Another trigger condition
related:
  - other-skill-name
  - another-skill-name
description: ...
---
```

**`phase`** — which SDLC phase this skill belongs to. Enables filtering by phase.  
**`tags`** — searchable keywords. Use nouns and verbs that appear in task descriptions.  
**`triggers`** — condensed version of "When to Use". Structured for programmatic matching.  
**`related`** — explicit list of related skill slugs. Makes the graph bidirectional.

### 2. Wikilinks `[[name]]`

Use `[[slug]]` in See Also sections and cross-references instead of backtick paths.

```markdown
<!-- Before -->
- `pod/rules/3-shot-gates.md` — gate conditions

<!-- After -->
- [[3-shot-gates]] — gate conditions
```

**Rules:**
- `[[slug]]` — matches the `name:` frontmatter field of the target note
- `[[path/to/file|Display Text]]` — use for templates or files without a `name:` field
- Upstream skills: keep `agent-skills:skill-name` convention (they're outside our vault)
- Commands: keep `/command:subcommand` format (they're invocable, not notes)

### 3. Callout Blocks

Use Obsidian/GitHub callout syntax for critical information:

```markdown
> [!WARNING]
> Hard stop — do not proceed past this point.

> [!IMPORTANT]
> Mandatory rule with no exceptions.

> [!NOTE]
> Contextual information that aids understanding.

> [!TIP]
> Best practice or recommended approach.
```

**When to use each:**
- `[!WARNING]` — hard stops, pre-flight failures, gate violations
- `[!IMPORTANT]` — mandatory rules (session isolation, commit discipline)
- `[!NOTE]` — context, nuance, "this is the MOC" notices
- `[!TIP]` — optional best practices, performance hints

Don't callout-ify everything. Reserve callouts for information where missing it causes real damage (wrong verdict, skipped gate, context rot). Overuse defeats the purpose.

### 4. MOC (Map of Content)

The [[3-shot-loop]] doc is the hub note. It links to every skill, command, artifact, and rule in the loop. When adding a new skill or command:

1. Add it to the loop doc's Skills or Commands table
2. Add a `[[3-shot-loop]]` link in the new skill's See Also section
3. Add the skill slug to `related:` in any directly connected skill's frontmatter

### 5. Atomic Notes

Each file covers one concern. Cross-reference rather than duplicate:

```markdown
<!-- Don't copy rules between skills — reference them -->
See [[3-shot-gates]] for gate conditions.

<!-- Don't explain SC tags in every skill — link to the reference -->
SC tags follow the [[sc-tag-system]] convention.
```

---

## What NOT to use

| Obsidian feature | Status | Reason |
|------------------|--------|--------|
| `![[embed]]` transclusion | Not used | Claude Code reads it as literal text, not an include |
| Canvas | Not applicable | Visual-only, no text representation |
| Dataview queries | Not used | Claude Code can't execute them |
| Graph view | Not applicable | For human Obsidian users, not agents |
| `#inline-tags` | Not used | Prefer YAML `tags:` for consistency |

---

## See Also

- [[3-shot-loop]] — the MOC this convention powers
- `docs/skill-anatomy.md` — upstream skill format requirements (superset of frontmatter rules here)
