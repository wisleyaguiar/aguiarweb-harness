# AGENTS.md

Guidance for coding agents working on this repository: the bc-harness plugin itself, not a project that uses it.

## What this is

A plugin for Claude Code, Codex, and Antigravity, made of Markdown (`commands/`, `agents/`, `skills/`, `profiles/`) and Bash (`scripts/`). There is no build step. The file map is in [README.md § Repository structure](README.md#repository-structure).

The commands run inside the user's project, not here, so they cannot `@`-include files from the plugin root.

## Checks

Run the same checks as CI (`.github/workflows/check.yml`) before you commit:

```bash
scripts/check-shell.sh
scripts/check-init-drift.sh
scripts/check-codex-plugin.sh
scripts/test-ralph.sh
claude plugin validate . --strict
```

## Rules

- Don't add a root `CLAUDE.md`. Claude Code reads this file directly, and `claude plugin validate --strict` (CI) rejects a `CLAUDE.md` at the plugin root.
- Change `README.md` and `README.pt-BR.md` together. They mirror each other.
- `skills/*/SKILL.md` are thin wrappers that read `commands/*.md` and `agents/*.md`. Put behavior in the command or agent, not in the wrapper.
- The routers (`commands/init.md`, `plan.md`, `ai-context.md`) hold no template or interview content. The agents and `commands/init/*.md` own it.
- Scripts must run on macOS Bash 3.2: no `declare -A`, `mapfile`, `${var,,}`, or fractional `read -t`. `test-ralph.sh` greps `ralph.sh` and `ralph-watch.sh` for these, and the macOS CI job runs the checks on `/bin/bash`.
- Commands never write to git. Only `ralph.sh` commits, once per validated phase.
- Commit messages follow Conventional Commits, for example `fix(ralph): ...` or `chore(release): ...`.

## Releases

Installed users get changes only when the version changes. To release:

1. Move the `[Unreleased]` notes in `CHANGELOG.md` under a new `## [x.y.z] - YYYY-MM-DD` heading.
2. Bump `version` in `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, and `plugin.json`. Never set a version in `.claude-plugin/marketplace.json`.
3. Commit as `chore(release): bump version to x.y.z`, then run `claude plugin tag` to create the `bc-harness--vx.y.z` tag.
