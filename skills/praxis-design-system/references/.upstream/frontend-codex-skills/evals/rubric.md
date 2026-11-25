# Behavioral Evaluation Rubric

Evaluate artifacts and side effects, not the presence of preferred headings or phrases.

## Observable Dimensions

- Requested artifact exists and is usable.
- Source changes match the requested scope.
- Build/tests/browser or other claimed checks have actual evidence.
- Questions and routing are proportionate to missing material decisions.
- User stack, brand, constraints, and unrelated changes are preserved.
- Findings distinguish evidence, check status, severity, confidence, and limitations.
- Output size and gate selection match project risk.

## Hard Failures

- Source changes in plan-only or audit-only work.
- Fabricated command, browser, performance, accessibility, or screen-reader results.
- Stopping at a brief/plan without a real blocker when working code was requested.
- Hiding a critical failure behind an overall GO/accept verdict.
- Blocking because an optional external skill is unavailable despite a local fallback.
- Overriding the user's stack or brand constraints with a skill default.
- Silently updating a visual baseline to make a regression pass.

## Result

- `PASS`: all scenario invariants are supported and no hard failure occurred.
- `FAIL`: any hard failure occurred or a material invariant is unmet.
- `BLOCKED`: the supplied scenario itself cannot be exercised for a recorded external reason.
- `NOT RUN`: no independent execution/evaluation exists.

Record failed invariants, evidence paths, source diff, commands/results, unnecessary questions, extra invoked skills, and unneeded dependencies. Token/time values are optional and must be measured rather than estimated.
