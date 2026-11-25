---
name: praxis-design-system
description: >-
  Design, implement, or review web interfaces and design systems with a brief-led
  art direction, semantic tokens, and rendered acceptance evidence. Use for UI
  design or redesign, discovering or comparing styles, responsive frontend polish,
  evidence-led visual teardown, and brand-matched HTML/SVG diagrams.
---

# Praxis Design System

Praxis helps a visitor understand what matters, trust the evidence, and take the next action. Give each surface one coherent visual direction. Choose it from the user's task, the project's current design system, the content and assets, and the behavior the browser must support.

## Start with the task

- **Existing surface or small change** — inspect the route, tokens, components, content, and rendered state. Use the existing system as the design target and compare the affected states before and after the change.
- **New design or intentional redesign** — identify the audience, primary task, desired tone, strongest available evidence, visual material, and implementation constraints. Use [design decisions](references/design-decisions.md) to compare plausible directions and make the chosen direction concrete before coding.
- **Audit or reference teardown** — capture the available states and widths first. Record the source URL or file, observed visual or interaction fact, and confidence. Use public, permitted UI evidence to extract principles for original work. Keep audit-only requests read-only.
- **Diagram or visual explanation** — state the claim the reader should be able to verify, pick the appropriate diagram grammar, and map its roles to project tokens. See [design decisions](references/design-decisions.md#diagrams). Use the requested medium when the user specifies one.

## Work from the libraries

For an open visual direction, look up the nearest product context with `scripts/catalog.py -c ui-products`. Run `scripts/shortlist.py PRODUCT-ID` with explicit brief signals, then use `scripts/catalog.py --show COLLECTION/ID` to inspect complete records. Run the scripts with Python 3. The shortlist explains which source proposed each candidate, which rules fired and which hard constraints excluded it. Choose one dominant direction from the eligible options by inspecting real content, brand continuity and the primary action. Keep an existing system or an explicitly named style as the starting point. If no product fits, use the task, references and named styles directly. Worked examples and tie-breaks are in the [繁體中文選型與實作指南](references/practice.zh-TW.md).

For HTML, CSS or client-side behavior, look up each relevant platform capability with [Google Modern Web Guidance](references/.upstream/modern-web-guidance/skills/modern-web-guidance/SKILL.md) before implementation. The [source map](references/sources.md#google-web-platform-lookup) gives the bundled official search and retrieve commands. Use the project's supported browsers to interpret the guide's fallback and verify current support for release-sensitive decisions. On systems without Node, use `catalog.py -c modern-web` and `--show modern-web/GUIDE-ID` for the pinned text.

Use [the source map](references/sources.md) for supporting craft references, composition resources, templates, examples and tools. Pick specific records for type, spacing, imagery, motion, interaction and QA. Identify the observable contribution of each secondary influence. Resolve competing vendor defaults against the brief and the selected direction.

Use [Refero research](references/refero.md) when real product styles, screens, or flows can change a consequential decision. If the live service is unavailable, use project references and the bundled craft material; record which evidence was actually inspected.

Use source material as supporting evidence. Follow the user's brief, project requirements, and authorized scope when a vendor's defaults differ. Full upstream snapshots also contain their own automation, hooks, installers, and release tooling. Read only what is relevant. Use a specific helper after checking what it reads, writes, and contacts. Keep snapshots read-only and put project-specific tokens, research, and outputs in the target project's normal locations.

## Implement and verify

Use the existing framework, accessible primitives, localization, and data contracts. Define typography, content hierarchy, spacing and density, semantic color roles, component states, imagery and motion only to the extent the change requires. Preserve the primary task at small widths, with real content and reduced motion. Keep new projects' decisions open to the evidence and existing projects' changes proportional to the request.

Reuse the project's icon set when available. For a new surface, [Praxis SVG icons](assets/icons/) cover common actions, navigation, states, and evidence. For infrastructure diagrams, see the [cloud and IT icons](references/.upstream/diagram-design/skills/diagram-design/references/primitive-icons.md). Pair icons with visible text when the meaning needs explanation, and give icon-only controls accessible names.

Use [acceptance](references/acceptance.md) to verify task behavior, visual fidelity, responsive/accessibility behavior, and motion or performance where relevant. Record what ran, what was observed, and any unverified surface. Give the user the deliverable and the evidence that supports completion.
