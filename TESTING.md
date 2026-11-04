# Testing

The offline checks (shell, init drift, manifests, the ralph suite, `claude plugin validate --strict`) are listed in [AGENTS.md § Checks](AGENTS.md#checks). CI runs them on every pull request.

This file records what ran on a real host, and what has not run yet. A check that did not run is not a pass.

## Host test record

Add a row for each run. Name the version, the date, and exactly what ran.

| Host | Version | Date | What ran | Result |
|---|---|---|---|---|
| GitHub Actions: `check` (Ubuntu) and `bash32` (macOS, `/bin/bash` 3.2) | — | 2026-11-04 | CI on PRs #5–#10 (`wisleyaguiar/aguiarweb-harness`) | pass |
| Local macOS: bash 5 and `/bin/bash` 3.2 | — | 2026-11-04 | `scripts/test-ralph.sh` (327 asserts; case 50 red without its `ralph.sh` change, green with it), `scripts/check-shell.sh`, `scripts/check-init-drift.sh`, `scripts/check-codex-plugin.sh` | pass |
| Claude Code | 2.1.318 | 2026-11-04 | `claude plugin validate . --strict` with `omitClaudeMd` on the three `ai-context-*` agents and the new `plan-reviewer` | pass |
| Antigravity (agy CLI) | 1.5.0 | 2026-11-04 | `agy plugin validate .` with the same changes | pass, `agents 7`, the 3 known warnings (`AGENTS.md`, `commands/`, `hooks/hooks.json`) |
| Antigravity (agy CLI) | 1.4.7 | 2026-10-24 | Workspace skill and a temporary plugin with `disable-model-invocation`: the model does not see the skill; the user runs it as `/<plugin>:<skill>` | pass |
| Codex CLI | 0.164.0 | 2026-10-24 | `codex exec` with bc-harness installed from a local-path marketplace: the sail-guard hook blocked `php artisan --version` | pass |

## Not run live yet

- `/init` hopping to an `init:*` command through the Skill tool in Claude Code.
- `/plan` with the planner rules (file actions, reuse, no decision left open), the RIGID coverage check, and `plan-reviewer` on a `standard` feature.
- `omitClaudeMd` keeping `CLAUDE.md` and `AGENTS.md` out of an agent's starting context.
- `ralph.sh` writing the regression note on a real run.
- `/ai-context` listing `missing path:` warnings on a real repo.
- Codex install from the GitHub marketplace.
