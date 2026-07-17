---
description: Plan the visual design direction for a new UI — palette, type stack, layout, and signature element — with a built-in self-critique pass before any code is written.
---

Invoke the `frontend-design` skill.

Before starting the design plan, ask the user for any missing context:
1. **Subject** — what is being built and its primary purpose (the page's single job)
2. **Audience** — who will use it and what they associate with this subject
3. **Constraints** — existing brand guidelines, design system tokens, or aesthetic references to respect
4. **Scope** — new design from scratch, or a reshape of an existing UI

Do not proceed if the subject is unknown. A design plan without a grounded subject defaults to generic.

Run **Pass 1** (ground in subject → color tokens → type stack → layout wireframe → signature element) followed by **Pass 2** (self-critique: check each token against the brief, revise anything that could belong to a different project). Present the full plan to the user and get explicit approval before any implementation begins.

After approval, confirm that implementation will follow the `frontend-ui-engineering` skill using the token names defined in this plan.
