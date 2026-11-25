# Contributing

## Principles

- Keep each skill focused on one workflow stage.
- Define clear entry, boundary, and handoff rules. Keep requested deliverable, artifact readiness, and blockers/assumptions separate.
- Start descriptions with `Use when`.
- Keep `SKILL.md` concise and move detailed guidance into `references/`.
- Do not include third-party skills without compatible licensing and attribution.
- Do not add placeholders, abbreviated code, or unresolved TODO text.

## Validation

Run before committing:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\validate.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\run-tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\evals\validate-evals.ps1
```

Validation, integration tests, and the eval contract must pass before committing. When routing, evidence, permissions, or handoff behavior changes, run the affected behavioral scenarios in isolated copies. Record unavailable executions as `NOT RUN`; static phrase checks do not substitute for outcome evaluation.

CI additionally installs pinned `PyYAML==6.0.3`, runs `scripts/validate-yaml.py`, and runs `tests/test_yaml_validation.py`. This is the narrow development/CI exception to the no-external-dependency rule. User-facing `install.ps1`, `validate.ps1`, `doctor.ps1`, and `tests/run-tests.ps1` remain PowerShell-only and offline.

## Adding a Skill

1. Create `skills/<skill-name>/SKILL.md`.
2. Add `agents/openai.yaml`.
3. Add only necessary references or scripts.
4. Add the skill to `skills.json` with `name`, `stage`, `output`, and a `requires` array. Use an empty array when it has no required skill dependencies. Add `optionalIntegrations` only for external skills that have a documented local fallback.
5. Document its role in `README.md`.
6. Declare every cross-skill Markdown reference in `requires`.
7. Run validation and integration tests.

## YAML Rules

- Codex supports additional frontmatter such as `metadata`; this package permits `name`, `description`, and optional `metadata` as a local convention.
- `name` and `description` must be non-empty strings. Use quoted or block scalars when a value contains `: `.
- Single-line, quoted, `|`, `>`, `|-`, and `>-` descriptions remain supported.
- Duplicate keys, unterminated quotes, invalid indentation, and scalar type mistakes fail validation.
- Quote string values in `agents/openai.yaml`; `policy.allow_implicit_invocation` is a YAML boolean when present.

## Infrastructure Changes

- Keep manifest, frontmatter, dependency, path, reference, and hashing logic in `scripts/SkillPack.Common.psm1` so the installer, validator, and doctor share one contract.
- Do not add external dependencies to user-facing PowerShell validation, installation, doctor, or integration tests. A pinned standard YAML parser is allowed only in the documented dev/CI check.
- Add negative coverage in `tests/run-tests.ps1` for new validation rules.
- Keep tests isolated to temporary copies; never modify active `%USERPROFILE%\.codex\skills` or `%USERPROFILE%\.agents\skills` roots.
