<img src="skills/praxis-design-system/assets/praxis.svg" width="48" height="48" alt="Praxis">

# Praxis Design System Skill

**Choose a design direction from the brief, then check it in the browser.**

[繁體中文](README.zh-TW.md) · [Quick start](#quick-start) · [Worked example](#worked-example) · [Diagram showcase](#diagram-showcase) · [Design library](#design-library)

[![Install for Codex](docs/badges/codex.svg)](#quick-start) [![194 product profiles](docs/badges/profiles.svg)](#worked-example) [![Offline library: 5,227 records](docs/badges/catalog.svg)](#design-library) [![52 diagram types](docs/badges/diagrams.svg)](#diagram-showcase) [![MIT License](docs/badges/license.svg)](LICENSE)

Praxis gives Codex a workflow for designing new interfaces, refining existing ones, and creating project-matched HTML/SVG diagrams.

## Quick start

Run this from the project where you use Codex:

```bash
npx skills add JasonLn0711/praxis-design-system-skill --skill praxis-design-system -a codex
```

Then invoke `$praxis-design-system` in Codex. Add `-g` to install across projects, or copy the [skill folder](skills/praxis-design-system/) into your project's `.agents/skills/`.

| If you want to… | Try asking |
| --- | --- |
| Design a new site | “Use `$praxis-design-system` to compare two directions for a bilingual research archive. Show how readers find the evidence on mobile.” |
| Improve an existing interface | “Use `$praxis-design-system` to improve table density and keyboard navigation. Reuse our design tokens.” |
| Explain a process | “Use `$praxis-design-system` to draw an HTML/SVG swimlane diagram for this approval flow. Show who handles each handoff.” |

## Worked example

> Design a light-mode museum gallery that runs smoothly on modest devices. Visitors should be able to browse the collection and open a work on their phones.

1. **Shortlist.** The gallery profile includes Minimalism & Swiss Style. Requiring light mode and low rendering cost screens out 3D & Hyperrealism.
2. **Design.** Put the artwork first. Keep the title and artist with each work, and reuse the site's typography and color tokens.
3. **Verify.** Open a work on mobile, then return to the same place in the collection. Check that keyboard users can follow the same path.

To reproduce the shortlist from a cloned repository, run:

```bash
python3 skills/praxis-design-system/scripts/shortlist.py museum-gallery --mode light --low-cost
```

## Diagram showcase

Eight fictional scenarios. Select any image to open the full-size SVG.

<p>
  <a href="docs/examples/exploded-sensor.svg"><img src="docs/examples/exploded-sensor.svg" width="395" alt="Axonometric teardown — How four components stack inside an air quality sensor."></a>
  <a href="docs/examples/service-blueprint-museum.svg"><img src="docs/examples/service-blueprint-museum.svg" width="395" alt="Service blueprint — Follow a museum loan from pickup to cleaning and recharging."></a>
</p>

<p>
  <a href="docs/examples/sankey-repair-cafe.svg"><img src="docs/examples/sankey-repair-cafe.svg" width="395" alt="Sankey diagram — Trace 100 repair items across four outcomes."></a>
  <a href="docs/examples/wardley-archive.svg"><img src="docs/examples/wardley-archive.svg" width="395" alt="Wardley map — See which archive capabilities to build and which to reuse."></a>
</p>

<p>
  <a href="docs/examples/event-modeling-publishing.svg"><img src="docs/examples/event-modeling-publishing.svg" width="395" alt="Event modeling — See how publishing commands update the review queue and public index."></a>
  <a href="docs/examples/traceability-accessibility.svg"><img src="docs/examples/traceability-accessibility.svg" width="395" alt="Requirement traceability — Find the exhibit’s missing accessibility verification."></a>
</p>

<p>
  <a href="docs/examples/schedule-touring-exhibit.svg"><img src="docs/examples/schedule-touring-exhibit.svg" width="395" alt="Schedule network — See which chain fixes the opening date and where there is float."></a>
  <a href="docs/examples/polar-library.svg"><img src="docs/examples/polar-library.svg" width="395" alt="Polar chart — Spot the busiest four-hour window at a 24-hour library."></a>
</p>

## Design library

| I'm looking for… | Where to start |
| --- | --- |
| Product patterns, palettes and typography | UI/UX Pro Max and Design Pro |
| Composition, motion and 3D | Taste Skill, Taste Skill Classics and RCS Frontend Skill |
| Interface analysis, polish and acceptance | Impeccable and Frontend Codex Skills |
| Diagram types, layout rules and examples | Diagram Design |
| Browser behavior, compatibility and fallbacks | Google Modern Web Guidance |
| A method for researching design references | Refero |

### Look up a diagram

Look up an exact record by ID. For example, `diagrams/swimlane` returns the swimlane specification and the light, dark and editorial examples.

```bash
python3 skills/praxis-design-system/scripts/catalog.py --show diagrams/swimlane
```

[Browse all sources and query commands](skills/praxis-design-system/references/sources.md) · [繁體中文實作指南](skills/praxis-design-system/references/practice.zh-TW.md)

## License

Praxis-authored material uses the [MIT License](LICENSE). Bundled sources retain their respective licenses and credits. [Third-party notices](THIRD_PARTY_NOTICES.md)
