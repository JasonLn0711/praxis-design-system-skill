# Source map

Browse the pinned skills, guides, datasets and examples. Taste v2.1.5 supplies the earlier direction and app style catalogs. [Local library](.upstream/) · [Source versions and credits](sources.lock.json)

| Source | Start here |
| --- | --- |
| UI/UX Pro Max | [Skill](.upstream/ui-ux-pro-max-skill/.claude/skills/ui-ux-pro-max/SKILL.md), [style database](.upstream/ui-ux-pro-max-skill/src/ui-ux-pro-max/data/styles.csv), [data and stack tables](.upstream/ui-ux-pro-max-skill/src/ui-ux-pro-max/data/), [quick reference](.upstream/ui-ux-pro-max-skill/.claude/skills/ui-ux-pro-max/references/quick-reference.md). Upstream advertises 80 searchable styles, with 51 active and 29 supplemental plus 9 deprecated records retained for compatibility. |
| Taste Skill | [Skill](.upstream/taste-skill/skills/taste-skill/SKILL.md), [11 hero compositions](.upstream/taste-skill/skills/taste-skill/assets/layout/heroes.json), [complete section recipes](.upstream/taste-skill/skills/taste-skill/references/sections-library.md), [type](.upstream/taste-skill/skills/taste-skill/library/type.json), [palettes](.upstream/taste-skill/skills/taste-skill/library/palettes.json), [motion](.upstream/taste-skill/skills/taste-skill/references/motion.md), [browser finish gate](.upstream/taste-skill/skills/taste-skill/references/gate.md). |
| Taste Skill v2.1.5 | [Earlier skill](.upstream/taste-skill-v2-1-5/skills/taste-skill/SKILL.md), [20 web art directions](.upstream/taste-skill-v2-1-5/skills/taste-skill/library/directions.json), [7 app styles, shells and screen patterns](.upstream/taste-skill-v2-1-5/skills/taste-skill/library/app.json), and [earlier layout, palette, type, motion, photo and site databases](.upstream/taste-skill-v2-1-5/skills/taste-skill/library/). |
| Impeccable | [Codex skill](.upstream/impeccable/.agents/skills/impeccable/SKILL.md), [craft floor](.upstream/impeccable/.agents/skills/impeccable/reference/craft-floor.md), [critique rubric](.upstream/impeccable/.agents/skills/impeccable/reference/critique-rubric.md), [audit](.upstream/impeccable/.agents/skills/impeccable/reference/audit.md), [polish](.upstream/impeccable/.agents/skills/impeccable/reference/polish.md), and [all command references](.upstream/impeccable/.agents/skills/impeccable/reference/). Prefer the written review guidance and local browser checks. Impeccable live Apply can invoke an unattended agent with elevated permissions. Keep that mode out of the Praxis workflow. |
| Diagram Design | [Skill](.upstream/diagram-design/skills/diagram-design/SKILL.md), [gallery with 52 types, static treatments and worked variants](.upstream/diagram-design/skills/diagram-design/assets/index.html), [type details and import/export contracts](.upstream/diagram-design/skills/diagram-design/references/), [output spec](.upstream/diagram-design/skills/diagram-design/references/output-spec.md), [third-party licenses](.upstream/diagram-design/THIRD_PARTY_LICENSES.md). |
| Design Pro | [Skill](.upstream/design-pro/skills/design-pro/SKILL.md), [20 style families](.upstream/design-pro/skills/design-pro/references/style-library.md), [36 decision resources](.upstream/design-pro/skills/design-pro/references/creative-library.md), [mobile QA](.upstream/design-pro/skills/design-pro/references/mobile-qa.md), [acceptance](.upstream/design-pro/skills/design-pro/references/acceptance.md). |
| Taste Skill Classics | [All seven skill entry points](.upstream/taste-skill-classics/README.md#skills), including high-end, minimalist, industrial brutalist, GPT Taste, Stitch and both earlier Taste versions. |
| RCS Frontend Skill | [Skill](.upstream/rcs-frontend-skill/SKILL.md), [12-style atlas](.upstream/rcs-frontend-skill/references/style-atlas.md), [composition](.upstream/rcs-frontend-skill/references/style-composition.md), [interaction](.upstream/rcs-frontend-skill/references/interaction-architecture.md), [3D and graphics](.upstream/rcs-frontend-skill/references/3d-and-graphics.md), [quality gates](.upstream/rcs-frontend-skill/references/testing-and-quality.md). |
| Frontend Codex Skills | [All ten skill entry points](.upstream/frontend-codex-skills/skills/), including [reverse engineering](.upstream/frontend-codex-skills/skills/web-ui-reverse-engineer/SKILL.md), [design](.upstream/frontend-codex-skills/skills/web-ui-designer/SKILL.md), [planning](.upstream/frontend-codex-skills/skills/frontend-design-planner/SKILL.md), [implementation](.upstream/frontend-codex-skills/skills/frontend-implementation/SKILL.md), and [acceptance review](.upstream/frontend-codex-skills/skills/frontend-acceptance-review/SKILL.md). |
| Refero official | [Skill](.upstream/refero_skill/skills/refero-design/SKILL.md), [offline craft references](.upstream/refero_skill/skills/refero-design/references/), and [Praxis integration decision](refero.md). |
| Google Modern Web Guidance | [Released skill](.upstream/modern-web-guidance/skills/modern-web-guidance/SKILL.md), [211 platform guides](.upstream/modern-web-guidance/skills/modern-web-guidance/guides/) and [official CLI](.upstream/modern-web-guidance-npm/skills/modern-web-guidance/modern-web.mjs). The npm distribution supplies the compiled CLI and search index. Its archive is pinned by registry URL and SHA-512 integrity in the lock. Code uses Apache-2.0 and guide documentation uses CC BY 4.0 with upstream credits. [License and attribution](.upstream/modern-web-guidance/README.md) · [GoogleChrome project](https://github.com/GoogleChrome/modern-web-guidance). |

## Search from any working directory

Set `PRAXIS_DIR` to this skill folder. The catalog lists entries for a named collection when you omit search words. It reports the upstream paths relative to the skill directory. It searches by names, IDs and descriptive terms, including UI/UX Pro Max's supplemental styles. Treat deprecated records as historical lookups and consult their replacement fields in the CSV. Use `--json` when consuming entries in a script.

Use `--show COLLECTION/ID` to read the exact record returned by a search. Depending on the source, this returns the full CSV row, JSON record, Markdown guide or diagram guidance with its three example paths. Collection names are listed by `--help`. The index covers the design and implementation references most useful in decisions. Other assets, demos and tooling are directly accessible in the full trees above.

```bash
PRAXIS_DIR="$PWD/.agents/skills/praxis-design-system"
python3 "$PRAXIS_DIR/scripts/catalog.py" -c ui-products "museum"
python3 "$PRAXIS_DIR/scripts/shortlist.py" museum-gallery --mode light --low-cost
python3 "$PRAXIS_DIR/scripts/catalog.py" --show ui-styles/minimalism-and-swiss-style
python3 "$PRAXIS_DIR/scripts/catalog.py" --show diagrams/swimlane
python3 "$PRAXIS_DIR/scripts/catalog.py" --show modern-web/light-dismiss-a-dialog
python3 "$PRAXIS_DIR/scripts/catalog.py" --collection ui-styles "glass"
python3 "$PRAXIS_DIR/scripts/catalog.py" --collection diagrams "swimlane"
python3 "$PRAXIS_DIR/scripts/catalog.py" --collection taste-heroes
python3 "$PRAXIS_DIR/scripts/catalog.py" --collection taste-v2-directions
python3 -B "$PRAXIS_DIR/references/.upstream/ui-ux-pro-max-skill/.claude/skills/ui-ux-pro-max/scripts/search.py" "accessible data tables" --domain ux --full
python3 -B "$PRAXIS_DIR/references/.upstream/ui-ux-pro-max-skill/.claude/skills/ui-ux-pro-max/scripts/search.py" "responsive interactive components" --stack svelte
```

For more precise style matching or a design system recommendation, use upstream's search tool. For broad browsing, use the catalog, the upstream docs, or the local galleries. Keep project outputs outside the snapshot. The installed package includes the references without network access. Optional upstream helpers may require a browser, an installed runtime, or external services.

Run `python3 "$PRAXIS_DIR/scripts/verify_sources.py"` to check all installed files and executable modes. The check compares the installed package with its locked source contents.

## Google web platform lookup

With Node 22 or later, run the bundled official CLI from the target project's working directory. Search one platform capability at a time, choose the matching ID, then retrieve its full guide. These commands use the pinned package and its local index. For current compatibility, consult the current official guide and the project's browser policy. The local Markdown catalog includes experimental material. A document's presence establishes availability for research.

```bash
PRAXIS_DIR="$PWD/.agents/skills/praxis-design-system"
WEB_GUIDANCE="$PRAXIS_DIR/references/.upstream/modern-web-guidance-npm/skills/modern-web-guidance/modern-web.mjs"
DISABLE_TELEMETRY=1 node "$WEB_GUIDANCE" search "light dismiss dialog" --skill-version 2026_11_16-268fb9ea
DISABLE_TELEMETRY=1 node "$WEB_GUIDANCE" retrieve light-dismiss-a-dialog
```
