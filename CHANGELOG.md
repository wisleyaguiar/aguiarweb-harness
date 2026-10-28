# Changelog

All notable changes to bc-harness are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/). Each release is tagged `bc-harness--v<version>`.

## [Unreleased]

## [0.7.0] - 2026-10-28

### Added

- `ralph.sh` picks the model and effort of each phase on the claude engine: `--model`, `--effort` (or `RALPH_MODEL`, `RALPH_EFFORT`), or a `**Route:** sonnet/high` line in the phase preamble. From cycle 2 on, each fix cycle steps up one level, except what came from a flag. Codex and Antigravity keep the plain loop.
- `ralph.sh --route auto` decides model and effort for phases with no flag and no complete hint, before the run: one cheap claude call for all phases, or the OpenAI Decisions API or Jev (from TypeSafe or OpenRouter) with `RALPH_ROUTE_API`, `RALPH_ROUTE_KEY`, and `RALPH_ROUTE_URL`. Only phase and task titles go to the API. A failed decision falls back to claude, then to the engine default, and never stops the run.
- `/plan` and `/init:project-phases` write the `**Route:**` line from the phase's riskiest task.
- `ralph-watch.sh` shows a **Modelo** column when the run has a route, with `↑` on a stepped-up phase. `/retro` flags phases that only passed after a step-up.

### Changed

- `ralph.sh --help` prints the whole header, including the environment variables.

## [0.6.0] - 2026-10-24

### Added

- `/plan` lists the test seams (the public interfaces the tests drive) in `PLAN.md` and asks you to confirm them with the decomposition.
- `ralph.sh` gate 3 also judges scope (files no task asks for) and standards (`AGENTS.md`/`CLAUDE.md` rules). A `SCOPE` or `STANDARDS` warning shows up in the log and never fails the phase.
- The `/init:*` interviews give a suggested answer with every question, so you can confirm or correct it.
- CI job on macOS that runs the checks with `/bin/bash` 3.2.
- `/retro` reads what the last `ralph.sh` run left in `.phases/` and ranks the changes that would make the next run pass sooner: the phase document, the test command, a check, or a line in `AGENTS.md`. It only proposes; you apply.

### Fixed

- Antigravity loads the 6 agents. Their `tools` field is now a YAML list; Antigravity skipped the comma-separated string.
- `ralph-watch.sh` (and `ralph.sh --dashboard`) runs on macOS's `/bin/bash` 3.2. It crashed there before. On Bash 3.2, holding a scroll key redraws once per key instead of batching, and `--interval` rounds down to whole seconds (minimum 1). A phase written `Phase 08` shows as `F8`.
- `/init` hands off to the next step with the `Skill` tool. It named `SlashCommand`, which Claude Code replaced when it merged commands into skills.

## [0.5.0] - 2026-10-24

### Changed

- `/init`, `/plan`, and `/ai-context` are user-invoked only: Claude no longer starts them on its own. `/init` still runs the `/init:*` steps itself.
- The 7 skill wrappers no longer show up in Claude Code next to the commands. They stay for Codex and Antigravity.
- Codex skills are explicit-only: start them with `$bc-harness-*`.
- The plugin version lives only in the plugin manifests. `marketplace.json` no longer carries one, and the Antigravity `plugin.json` now declares it.

### Added

- GitHub Actions CI: shell checks, init drift, manifests, the `ralph.sh` suite, and `claude plugin validate --strict`.
- `AGENTS.md` for agents working on this repository, and this changelog.

## [0.4.0] - 2026-10-09

### Added

- Antigravity plugin support: root `plugin.json`, `hooks.json`, and `sail-guard.sh --antigravity`.
- `ralph.sh --engine agy` for the Antigravity CLI.
- `/ai-context` writes a `GEMINI.md` that imports `AGENTS.md`.
- `ralph-watch.sh` live panel with per-task progress, fed by `RALPH-TASK <n> START|DONE` lines.

### Changed

- The gate 3 verifier runs on Sonnet.

### Fixed

- `ralph.sh` runs on macOS Bash 3.2.
- The generated `CLAUDE.md` imports `AGENTS.md` with `@` instead of linking it.
- Gate 0 read `is_error` from the whole conversation instead of the final result.
- `ralph.sh` also recognizes the Claude Code session-limit messages, not just `usage limit reached`.
- The gate 3 verifier never runs commands in the background.
- Live panel rendering: scrolling, resize leftovers, terminal width, and row highlight.

## [0.3.0] - 2026-07-27

### Added

- `/init` diagnostic router, plus `check-init-drift.sh` to keep the rules shared by the `/init:*` steps in sync.
- `/plan` pipeline with the `specifier`, `clarifier`, and `planner` agents.
- Stack profiles (`profiles/laravel.md`, `wordpress.md`, `generic.md`). Gate 2 takes its test command from the Stack Profile and detects `vendor/bin/phpunit`.
- `sail-guard` hook: in Laravel Sail projects, blocks host-side PHP and database commands and suggests the Sail equivalent.
- Codex plugin: `.codex-plugin/plugin.json`, 7 skill wrappers, and `check-codex-plugin.sh`.
- Claude Code marketplace (`.claude-plugin/marketplace.json`).
- `test-ralph.sh` suite with mock engines, and `check-shell.sh`.
- README in English and Brazilian Portuguese.

### Removed

- The Mira plugin.

### Fixed

- `argument-hint` values are quoted, so Copilot CLI 1.0.65 and later loads every skill.
- Gate 3 counts distinct tasks, and `ralph.sh` works with BSD tools.

## [0.2.0] - 2026-07-08

### Added

- `/ai-context` with the `ai-context-inspector`, `ai-context-core`, and `ai-context-docs` agents: writes `AGENTS.md`, `CLAUDE.md`, and `docs/agents/*.md` from the implemented code.

## [0.1.0] - 2026-07-08

### Added

- `/init:project-description`, `/init:user-stories`, `/init:database-schema`, and `/init:project-phases`.
- `scripts/ralph.sh`, the phase-by-phase execution orchestrator.
