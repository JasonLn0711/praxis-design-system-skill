# Praxis design decisions

## A direction the project can test

1. Express the task as one sentence: “For [audience], this surface makes [action or understanding] easier by making [evidence or affordance] visible.” Record existing constraints, the relevant route and content, and which decisions the user delegated.
2. On an existing interface, inspect live project code, current usage, and rendered behavior. Record implementation and intended direction separately if they diverge. For a new visual direction, compare candidates on primary-task fit, brand/content fit, readability and accessibility, available assets, maintenance, and mobile behavior. Remove directions that fail a hard requirement. Use a distinct expressive feature only where it helps.
3. Lock the observable target before implementing. A compact record is sufficient: audience and primary action, dominant visual thesis, supporting source and its relevant trait, composition at wide and narrow widths, token roles, evidence and asset treatment, state or motion behavior, and the smallest test that can disconfirm the decision. Compare explicit variants when exploration is the deliverable.
4. Reuse project primitives. For a new system, connect raw values to semantic roles, then to components. Start with the requirements below and use the linked upstream material for specifics.

| Area | Record when it shapes the result |
| --- | --- |
| Type and copy | Reading roles, scales and fallback coverage, multilingual wrapping, CTA verbs, meaningful labels, and what the user should remember. |
| Layout and density | Reading order, measure, grid and spacing rhythm, responsive priority and overflow, long labels and data. |
| Color and surfaces | Background, surface, text, secondary text, border, action, evidence or status, and focus. Verify paired contrast and add text or shape to essential color distinctions. |
| Components | Reuse decision, content contract, keyboard behavior, default, hover, focus-visible and active states, then disabled, pending, empty, error and success as relevant. |
| Media and motion | Role, crop and loading behavior, source rights, what motion communicates, static and reduced-motion behavior, input alternatives and performance cost. |

For an existing project, use its own names and canonical files. For a recurring design system, store shared token decisions once in the project's accepted design document and keep page-level exceptions near their owner.

## Select references by question

- Product fit and implementation constraints → UI/UX Pro Max product, style, UX, accessibility, and framework data. Its default search ranks active styles and exact or explicit searches reach supplemental styles.
- Layout, type, imagery, rhythm, and polished composition → Design Pro's families and decision catalog, Taste's actual hero files, type and palette entries, Impeccable's focused craft rule. For an app screen or a particular early Taste direction, use v2.1.5's dedicated app or art-direction library.
- Expressive motion and 3D → RCS style atlas and creative technology details. Add actual keyboard, touch, no-WebGL and reduced-motion paths where applicable.
- A named aesthetic or legacy Taste behavior → opt into that specific Classics skill. Keep the upstream's exact name in decision evidence.
- Patterns in real products → official Refero styles or screens, and flows when ordering or recovery matters. Frontend Codex's reverse-engineering skill can structure an evidence-backed UI teardown.
- Verification → use the project's checks first, then relevant upstream review or test guidance from [the source map](sources.md).

## Diagrams

Translate the claim into a relation before choosing the visual form. Use sequence for ordered messages, state for allowed transitions, architecture for components and connections, swimlanes for responsibility, a line chart for trend, and a table when exact lookup matters. For quantitative encodings, confirm the underlying units and totals. For biological or other scientific diagrams, confirm the actual source evidence and use the terminology, scope, and visualization format appropriate to the request.

For editorial HTML/SVG, select the Diagram Design gallery type by name and read its type reference, output contract and a representative example. Map paper, ink, muted, accent and links to the project's semantic roles. Check label legibility, connection direction, clipping, contrast, accessible name and description, and a meaningful structure or text alternative. For responsive exports, inspect the narrow view and the actual requested file. A Mermaid or plain SVG deliverable can use the same evidence and composition decisions through its requested format.

## Living Research Atlas example

For Jason's research site, prioritize the visitor's question, Jason's contribution, the closest public evidence, the claim boundary and a low-pressure next step. A research entry can use an editorial or cultural-archive approach and borrow technical-utility patterns for metadata only. Use the current shared CSS token file, layout and content model in the repository. Earlier design records inform an explicitly scoped redesign. For bilingual content, verify both language paths, long titles and reading order on narrow screens. Check reduced motion where a visual change introduces or modifies movement.
