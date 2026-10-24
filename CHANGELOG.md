# Changelog

All notable changes to bc-harness are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/). Each release is tagged `bc-harness--v<version>`.

## [Unreleased]

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
