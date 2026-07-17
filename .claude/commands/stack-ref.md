---
description: Resolve current, version-accurate docs for a library in the project stack via Context7. Usage: /stack-ref <library> <topic> — e.g. /stack-ref tanstack-query "useQuery isPending v5" or /stack-ref prisma "migrate dev options".
---

Invoke `pod/skills/stack-reference`.

Parse `$ARGUMENTS` as: first token = library name, remainder = topic. If either is missing, ask before proceeding:
- **Library**: which npm package? (e.g. `@tanstack/react-query`, `prisma`, `@nestjs/core`, `orval`)
- **Topic**: what specific API surface? (narrow — one function, one option group, one command)

Then run the skill's five-step process:
1. Read `package.json` for the pinned version
2. Call `mcp__context7__resolve-library-id` with the library name
3. Call `mcp__context7__get-library-docs` with the resolved ID, pinned version, and topic
4. Extract only the signatures and behaviour relevant to the current task
5. Return the result inline — do not write a file

Output format:

```
Library:  <name> @ <pinned version>
Topic:    <topic>
Source:   Context7 (<library-id>)

<extracted docs — signatures, option names, behaviour notes, migration notes if relevant>
```

If Context7 is not configured, stop and say: "Context7 MCP not found. Add it to .claude/settings.json — see pod/skills/stack-reference/SKILL.md § Setup Requirement."
