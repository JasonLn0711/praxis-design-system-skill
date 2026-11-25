# Praxis Design System Skill

[繁體中文](README.zh-TW.md) · [Source catalog](skills/praxis-design-system/references/sources.md)

Praxis helps coding agents pick a visual direction from a brief, turn it into UI decisions, and check the result in the browser. Use it for a new interface, a focused improvement to an existing design system, or an HTML/SVG diagram that matches a project.

## Install

From the project where you use Codex, run:

```bash
npx skills add JasonLn0711/praxis-design-system-skill --skill praxis-design-system -a codex
```

Open Codex and invoke `$praxis-design-system`. Add `-g` to install for your user across projects. To install from a checkout, copy the whole [skill folder](skills/praxis-design-system/) into your project's `.agents/skills/`.

## Try it

- **Research site:** “Use `$praxis-design-system` to design a bilingual research archive. Compare two directions and show how a reader finds the evidence on mobile.”
- **Existing dashboard:** “Use `$praxis-design-system` to improve table density and keyboard navigation. Keep the site's tokens and check the rendered table.”
- **Diagram:** “Use `$praxis-design-system` to draw an HTML/SVG swimlane for this approval flow. Label who hands off each step.”

Praxis starts with the user task and available content. It explains which styles fit, connects the chosen direction to concrete typography, layout and interaction decisions, and tests the result against the brief.

## Explore the library

| Need | Sources |
| --- | --- |
| Product fit, palettes, typography and UX patterns | UI/UX Pro Max and Design Pro |
| Art direction, composition, motion and 3D | Taste Skill, Taste Skill Classics and RCS Frontend Skill |
| Interface analysis, polish and acceptance | Impeccable and Frontend Codex Skills |
| 52 diagram types, with light, dark and editorial examples | Diagram Design |
| Browser behavior, compatibility and fallbacks | Google Modern Web Guidance |
| Research methods and optional live reference search | Official Refero |

The offline index covers **5,227 records across 34 collections**. To query it directly, run these commands from a cloned repository with Python 3:

```bash
python3 skills/praxis-design-system/scripts/shortlist.py museum-gallery --mode light --low-cost
python3 skills/praxis-design-system/scripts/catalog.py --show diagrams/swimlane
```

[Browse sources and commands](skills/praxis-design-system/references/sources.md) · [繁體中文實作指南](skills/praxis-design-system/references/practice.zh-TW.md)

## License

Praxis-authored material uses the [MIT License](LICENSE). The bundled sources retain their own licenses and credits. [Third-party notices](THIRD_PARTY_NOTICES.md)
