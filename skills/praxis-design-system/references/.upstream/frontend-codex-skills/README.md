# Frontend Codex Skills

A collection of interconnected Codex skills covering Web/UI reverse engineering, design, technical planning, frontend code architecture, implementation, performance and accessibility auditing, prompt generation, and independent acceptance review.

## Skills

| Skill | Purpose |
|---|---|
| `web-ui-reverse-engineer` | Decomposes an existing website, mockup, Figma design, live URL, or frontend codebase into evidence-backed components, design tokens, layout grammar, responsive behavior, interactions, assets, technical architecture, confidence-rated unknowns, and redesign/rebuild handoff. |
| `web-ui-designer` | Creates a scenario-aware Web/UI design brief covering brief mode, audience, information architecture, first viewport, visual system, components, states, motion, responsiveness, accessibility, and handoff status. |
| `frontend-design-planner` | Converts a supplied or sufficiently defined design into a proportionate technical frontend plan covering stack, files, components, state/data, delivery, and verification. |
| `frontend-code-architecture` | Provides maintainable frontend code guardrails for component boundaries, file structure, hooks, utilities, state/data separation, styling tokens, feature folders, and safe refactors. |
| `frontend-implementation` | Delivers working frontend code, focused debugging, or concrete fixes while preserving the current stack and selecting verification by changed-surface risk. |
| `frontend-performance-audit` | Audits finished or near-finished frontends for Core Web Vitals, Lighthouse/PageSpeed evidence, bundle cost, JavaScript runtime work, media and font loading, animation cost, caching, budgets, and prioritized performance findings. |
| `frontend-accessibility-audit` | Audits finished or near-finished frontends for WCAG 2.2, keyboard navigation, focus, ARIA/name-role-value, semantic HTML, labels, landmarks, forms, contrast, motion, screen-reader flow, automated findings, and prioritized accessibility fixes. |
| `frontend-qa-orchestrator` | Coordinates frontend QA gates for finished or near-finished work, selecting smoke, acceptance, accessibility, performance, regression, and fix re-check passes with evidence, go/no-go status, and handoff routing. |
| `frontend-acceptance-review` | Independently compares the requirements, design, and finished implementation, producing a requirements matrix, evidence-backed findings, and an acceptance verdict. |
| `website-master-prompts` | Creates copy-ready website generation master prompts with prompt modes, generator targets, source handoff preservation, stack roles, first viewport, visual system, motion, responsive behavior, anti-generic constraints, and acceptance checks. |

## Workflow

```text
existing site / design / code
        |
        v
web-ui-reverse-engineer
        |
        +---- reconstruction ----> frontend-design-planner
        |
        `---- redesign context ---> web-ui-designer
                                      |
                                      v
                              frontend-design-planner
        |
        +---- architecture guardrails ----> frontend-code-architecture
        |                                      |
        |                                      v
        v
frontend-implementation
        |
        v
frontend-qa-orchestrator
        |
        +---- smoke / gate selection ----> frontend-implementation
        |
        +---- performance gate ---------> frontend-performance-audit
        |
        +---- accessibility gate -------> frontend-accessibility-audit
        |
        `---- acceptance gate ----------> frontend-acceptance-review
                                             |
                                             +---- findings ----> frontend-implementation
```

Specialist audit chain when QA orchestration is not needed:

```text
frontend-implementation
        |
        v
frontend-performance-audit
        |
        +---- performance findings ----> frontend-implementation
        |
        v
frontend-accessibility-audit
        |
        +---- accessibility findings ----> frontend-implementation
        |
        v
frontend-acceptance-review
        |
        +---- findings ----> frontend-implementation
```

Alternative prompt workflow:

```text
web-ui-reverse-engineer -> web-ui-designer -> website-master-prompts -> external AI generator
```

For a new product without an existing interface, start directly with `web-ui-designer`.

The diagram describes capabilities, not mandatory approval stops. The current request controls the final artifact:

- a build request may perform the minimum design and planning needed, then continue to code and verification;
- a narrow bugfix starts with reproduction and the affected code path;
- plan-only and audit-only requests do not edit source;
- audit-and-fix includes baseline, fixes, and relevant rechecks without a second authorization prompt.

Skills select compact, focused, or full modes according to scope and risk. They omit immaterial report sections instead of padding every response with a production-sized template.

## Installation

### Install all skills

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

### Install selected skills

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
  -Skills frontend-implementation
```

Required dependencies are read from `skills.json` and installed automatically before the requested skills. For example, selecting `frontend-implementation` also installs `web-ui-designer` and `frontend-code-architecture`. Required dependencies cannot be disabled.

`optionalIntegrations` lists external skills that can refine a workflow when they are already available. They are not installed automatically, do not affect dependency closure or doctor health, and always have a local fallback.

Both comma-separated and PowerShell-array input are supported:

```powershell
.\install.ps1 -Skills web-ui-designer,frontend-design-planner
.\install.ps1 -Skills @('web-ui-designer', 'frontend-design-planner')
```

### Update existing skills

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Force
```

Existing skill folders are preserved with a warning unless `-Force` is supplied. With `-Force`, each selected folder is fully replaced.

### Preview an installation

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 `
  -Skills frontend-implementation `
  -WhatIf
```

`-WhatIf` resolves and reports dependencies without creating or changing files.

By default, skills are installed into:

```text
%USERPROFILE%\.codex\skills
```

Restart Codex after installation.

## Manual Installation

The installer is preferred because it resolves required dependencies. If you install manually, copy the selected skill and every skill listed in its `requires` array in `skills.json`.

Copy the required folder from `skills/` into:

```text
C:\Users\<username>\.codex\skills
```

Example:

```powershell
Copy-Item -Recurse `
  .\skills\frontend-acceptance-review `
  "$env:USERPROFILE\.codex\skills\frontend-acceptance-review"
```

## Validation

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\validate.ps1
```

The validator checks:

- manifest SemVer, required fields, unique names, directories, dependencies, and cycles;
- the package's documented YAML subset for single-line, quoted, and multiline frontmatter, including malformed plain scalars;
- lower-kebab-case names, folder/name matching, and package-supported frontmatter keys;
- local and cross-skill Markdown references, path containment, and declared dependencies;
- quoted `agents/openai.yaml` interface metadata, description lengths, skill invocation, and the 180-character prompt limit;
- scaffold placeholders throughout every skill directory.

CI also runs an independent standard-parser check with pinned PyYAML 6.0.3. It is a development/CI check and is not required by the installer or doctor:

```powershell
python -m pip install -r requirements-dev.txt
python .\scripts\validate-yaml.py
python -m unittest .\tests\test_yaml_validation.py
```

## Doctor

Inspect active skill roots for duplicate names, file drift, missing required dependencies, and broken installed references:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\doctor.ps1
```

By default, the doctor scans existing `%USERPROFILE%\.codex\skills` and `%USERPROFILE%\.agents\skills` roots while excluding `.system` and plugin-cache content. It never changes files.

Scan explicit roots:

```powershell
.\doctor.ps1 -SkillRoots 'C:\path\one','C:\path\two'
```

Return stable machine-readable sections (`summary`, `duplicates`, `drift`, `dependencies`, and `references`):

```powershell
.\doctor.ps1 -Json
```

Exit codes are `0` for healthy, `1` for detected problems, and `2` for an invalid manifest or configuration.

## Integration Tests

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1
```

The test suite uses isolated temporary copies and removes them after the run. It does not mutate the repository or active skill roots. It retains the original 13 install/doctor scenarios and adds validation for the behavioral-eval contract.

## Behavioral Evals

`evals/` contains 20 outcome-based scenarios for task completion, narrow fixes, read-only boundaries, evidence integrity, optional-skill fallback, handoff readiness, proportional output, async state, and visual regression.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\evals\validate-evals.ps1
```

This command validates the catalog, fixtures, and results contract. It does not claim the model scenarios were executed. See `evals/README.md` for isolated baseline/revised runs and record unavailable cases as `NOT RUN`.

## Repository Structure

```text
frontend-codex-skills/
|-- skills/
|   |-- web-ui-reverse-engineer/
|   |-- web-ui-designer/
|   |-- frontend-design-planner/
|   |-- frontend-code-architecture/
|   |-- frontend-implementation/
|   |-- frontend-performance-audit/
|   |-- frontend-accessibility-audit/
|   |-- frontend-qa-orchestrator/
|   |-- frontend-acceptance-review/
|   `-- website-master-prompts/
|-- scripts/
|   |-- SkillPack.Common.psm1
|   `-- validate-yaml.py
|-- tests/
|   |-- run-tests.ps1
|   `-- test_yaml_validation.py
|-- evals/
|   |-- fixtures/
|   |-- results/
|   |-- scenarios.json
|   |-- rubric.md
|   `-- validate-evals.ps1
|-- .github/
|   `-- workflows/
|       `-- validate.yml
|-- install.ps1
|-- validate.ps1
|-- doctor.ps1
|-- skills.json
|-- requirements-dev.txt
|-- CONTRIBUTING.md
`-- LICENSE
```

## Scope

This repository contains only original frontend skills. Third-party collections such as GSAP and Taste skills are not bundled. When named in `optionalIntegrations`, they are used only if already available; their absence never blocks installation or normal skill execution.

## License

[MIT](LICENSE)
