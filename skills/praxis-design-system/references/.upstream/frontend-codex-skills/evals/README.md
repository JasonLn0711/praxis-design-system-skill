# Behavioral Evals

These evals measure observable skill behavior. They complement `validate.ps1` and `tests/run-tests.ps1`; passing static or packaging checks does not prove behavioral quality.

## Run Procedure

1. Pick a scenario from `scenarios.json` and copy its fixture to a clean temporary workspace.
2. Give the executor only the scenario `prompt`, copied fixture, invocation mode, tools, and constraints. Do not provide invariants, hard-failure rules, or the expected result.
3. Record model, reasoning settings, skill-pack commit/version, tool availability, start/end time, transcript link, source diff, commands, and artifact paths.
4. Give the evaluator the raw run artifacts plus the scenario entry and `rubric.md`.
5. Write the result into a copy of `results-template.json`. Use `PASS`, `FAIL`, `BLOCKED`, or `NOT RUN`; never infer an unexecuted result.
6. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\evals\validate-evals.ps1 -ResultsPath <results.json>`.

Run baseline and revised versions with the same model, reasoning settings, invocation mode, fixture, and tools. Routing/authorization scenarios should use 2–3 repetitions when resources permit. Test both explicit and implicit selection where the scenario lists both; if only explicit invocation is available, mark implicit routing `NOT RUN`.

## Artifacts

- `scenarios.json`: executor input plus evaluator-only expectations.
- `rubric.md`: outcome and side-effect scoring.
- `fixtures/`: deliberately small disposable frontend inputs.
- `results-template.json`: result contract.
- `results/current.json`: status for this repository revision; it remains `NOT RUN` until real independent executions are recorded.

Do not run fixes directly in these checked-in fixtures. Every executor receives a temporary copy.
