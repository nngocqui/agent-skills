---
name: frontend-design
description: Guides agents through aesthetic direction and visual identity planning before writing UI code. Produces a design plan (palette, type stack, layout, signature element) with a self-critique pass to ensure choices are specific to the brief. Use when starting UI from scratch, reshaping an existing visual identity, or when the output needs to feel distinctive rather than templated. Run this before the `frontend-ui-engineering` skill.
---

# Frontend Design

## Overview

Produce a concrete design plan — palette, type stack, layout intent, and one signature element — then critique it for generic defaults before a single line of code is written. The goal is UI where every choice has a reason rooted in the brief, not UI that could belong to any project.

## When to Use

- Starting a new UI from scratch with no existing design system
- Reshaping an existing page or product's visual identity
- The brief gives aesthetic direction (a reference, a mood, a subject) but no concrete tokens
- The output needs to feel distinctive, not like an AI-generated default

**Not for:**
- Adding a component inside an existing locked design system (use `frontend-ui-engineering` directly)
- Bug fixes, refactors, or behavior changes with no visual scope
- Projects where brand guidelines already define all tokens

## Core Process

### Pass 1 — Build the Design Plan

Work through these four layers in order. Complete all four before moving to Pass 2.

**1. Ground it in the subject**

Before picking any color or typeface, state:
- The subject's physical world: its materials, textures, instruments, artifacts, vernacular
- The single job this page has to do
- The primary audience and what they already associate with this subject

Every token decision below must trace back to these answers. A music app should feel different from a finance app because their worlds are different — not because one got blue and one got green.

**2. Color (4–6 tokens)**

| Token name | Hex | Role |
|---|---|---|
| `color-primary` | `#…` | Brand, primary action |
| `color-surface` | `#…` | Page/card background |
| `color-surface-raised` | `#…` | Elevated surfaces |
| `color-text` | `#…` | Body text |
| `color-text-muted` | `#…` | Secondary/helper text |
| `color-accent` | `#…` | Signature color — used in one place only |

Verify minimum contrast before committing: 4.5:1 for body text, 3:1 for large text.

**3. Type (2–3 roles)**

| Role | Typeface | Weight/Style | Usage |
|---|---|---|---|
| Display | — | — | Headlines, hero |
| Body | — | — | Paragraphs, UI labels |
| Utility (optional) | — | — | Monospace, data, captions |

Pair faces deliberately. The display face should have character specific to the subject. Body must be legible at 16px on mobile. If using system fonts, name which ones and why.

**4. Layout + signature element**

One sentence describing the overall structure, then an ASCII wireframe for the primary view:

```
┌─────────────────────────────────┐
│  NAV                            │
├──────────────┬──────────────────┤
│  HERO        │  ASIDE           │
│              │                  │
├──────────────┴──────────────────┤
│  CONTENT                        │
└─────────────────────────────────┘
```

Then name the **signature element**: one thing that makes this design memorable and is defensible from the brief. It can be a type treatment, a color application, a structural device, a motion moment, or a copy approach. State it in one sentence.

> "Section numbers are set in the subject's native script alongside Latin numerals, because this is a language-learning product."

Spend visual boldness here. Keep everything else quiet.

---

### Pass 2 — Critique Against the Brief

Before writing any code, run this checklist:

- [ ] Could this palette belong to any generic SaaS? If yes, revise.
- [ ] Are the typefaces making a choice, or defaulting to Inter + system font without justification?
- [ ] Is the signature element specific to this brief, or is it "a gradient" or "big bold type"?
- [ ] Does the layout reflect the content's actual hierarchy, or is it a stock hero → cards → footer?
- [ ] Would swapping in a different brand name break anything? (If no: not specific enough.)

Revise any token that fails. Only move to build after at least 3 of 5 pass cleanly.

---

### Build

Hand the approved plan to the `frontend-ui-engineering` skill. Reference the token names defined here throughout implementation — don't reinvent values at the component level.

## Motion

If the design includes animation:

- Pick **one orchestrated moment** (hero entrance, page transition, key interaction). Commit to it.
- All other motion: simple opacity/transform, 150–200ms ease-out. Nothing more.
- Every animation must respect `prefers-reduced-motion`: skip or substitute a near-instant fade.
- Scattered micro-animations everywhere is an AI-generation tell. One well-placed moment reads as intentional.

## UX Copy

Copy is a design material. Apply the same intentionality as tokens:

- **Active voice, specific verbs**: "Save changes" not "Submit"; "Publish post" not "Confirm"
- **End-user vocabulary**: name things by what users recognize, not system internals ("Notifications" not "Webhook config")
- **Consistent action names**: the button, loading state, and success toast must use the same verb ("Publish" → "Publishing…" → "Published")
- **Edge cases are first-class**: error messages say what went wrong and how to fix it; empty states invite action; never apologize in UI copy

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The design system will define tokens later" | Without a plan, implementation defaults to AI aesthetic. Define tokens now, even if they get refined later. |
| "I'll use a clean, minimal style" | "Minimal" is not a design direction. Name specific choices: which typeface, which shade, which structural device. |
| "The signature element feels too risky" | One committed risk, executed well, reads as intentional. Playing it safe everywhere reads as generated. |
| "Pass 2 looks fine, I'll skip the checklist" | Generic defaults always look fine in isolation. They only read as generic when held against the brief. |
| "This is just a prototype, design doesn't matter yet" | Generic tokens become load-bearing technical debt. Replacing them after the fact costs 3× as much. |

## Red Flags

- Palette is purple/indigo/blue with no subject-grounded reason
- Display and body are the same typeface with no differentiation
- Signature element is "a gradient" or "large bold hero text" with no connection to the brief
- Layout is hero → 3-column cards → footer with no content-specific reasoning
- Pass 2 was skipped or completed without any revision
- Motion has more than one "featured" animation
- Error states say "Something went wrong" with no recovery guidance

## Verification

- [ ] Design plan has all four layers: color tokens, type roles, layout wireframe, signature element
- [ ] Every color token has a hex value and a stated role
- [ ] Signature element is defensible in one sentence tied to the brief
- [ ] Pass 2 critique ran and at least one revision was made
- [ ] If motion is present: single orchestrated moment identified; `prefers-reduced-motion` addressed
- [ ] UX copy uses active voice and consistent action naming
- [ ] Approved plan handed to `frontend-ui-engineering` for implementation
