# Changelog

All notable changes to bc-harness are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/). Each release is tagged `bc-harness--v<version>`.

## [Unreleased]

## [0.11.0] - 2026-11-10

### Changed

- `/plan` costs less, after a real run took 2.1M subagent tokens and about 2h35 (13 agents) for an 11-item feature:
  - The router only runs `test -f` on the project docs and the init chain. It no longer reads them into its own context.
  - Clarification: when the SPEC has markers, the router asks them in the same round as the SPEC approval and runs the clarifier only to apply the answers. Each marker now carries an id (`M1`), its options, and a suggestion; a marker without options (an older SPEC) is asked as an open question. The analysis runs only on a SPEC with no markers, on `complete` or when the developer reports doubts. Applying answers never writes a new marker: a new doubt comes back as a `Q-new:` line, with one more resolve at most; later ones go to the plan checkpoint.
  - The specifier writes a code map, `.handoff/exploration.md`. The clarifier and the planner read it before the code, and the plan reviewer never sees it. Findings from helper agents enter the map marked `(?)` until the specifier confirms them. Regenerating the SPEC deletes the map. The specifier and the planner grep the init chain instead of reading all of it.
  - The specifier and the planner know what `ralph.sh` can do: no failing-test commit, no production or live data, no manual step inside a phase. A step only a person can do goes to the SPEC Scope and to a new PLAN section, `## Pré-requisitos manuais`. The router shows those steps at the plan checkpoint and before the ralph command, and the plan reviewer treats the files they produce as existing.
  - SPEC, PLAN, and PHASES anchor code by path and symbol, never by line number. Task fields fit one or two lines.
  - Tasks live only in PHASES.md. PLAN.md drops `## Tasks` (the run above wrote 945 lines across both) and keeps the TO BE diagram, the phase table, risks, prerequisites, open questions, and assumptions. Each PHASES task gains a `Risco:` line, which sets the Route and the `High` phase split; order replaces the dependencies field. Instead of comparing two task counts, the router checks each task: a unique `T0N` id, exactly one `Acceptance criteria:`, and one `Risco: Low|Medium|High`. It prints an `invalid:` line per bad task (or for a file with no task), and sends those lines to the planner's fix mode once, in the same call as any uncovered ids; what is left goes to the plan checkpoint. The old count check failed silently. Each ralph phase still reads PLAN.md, now without a second copy of the tasks.
  - PLAN.md drops its AS IS diagram: the SPEC already has one.
  - Fix mode: after a review, or for uncovered ids, the planner gets only the SPEC, PLAN, PHASES, and the report or ids, edits only the named tasks (it gains the `Edit` tool), and returns the `revised:` task ids. Review round 2 reads the round-1 report, the revised tasks, and the planner's answers, and keeps the round-1 paraphrase.
  - On Claude Code, the answer-applying clarifier and the planner's fixes run on `sonnet`. A model the developer named for a role wins, and a fix that must settle a decision left open inherits the main model.
  - Small ACs (≤ 2 files each, no schema, no route) count as one for the tier; this lowers `complete` to `standard` at most, never to `light`. Checkpoint 3 flags them so the developer can take them out of the feature.
  - A missing architecture source is no longer a marker: the specifier writes it in `## Metadata`, since the developer already chose at the architecture gate.
  - The router confirms with one Grep any code claim from another agent before it shows the claim to the developer.
- `/ai-context` re-runs edit `docs/agents/*.md` in place. For an owned doc, the docs writer checks each claim against this run's digest or a file it opens now, keeps the wording of what still holds, fixes what is wrong, deletes what nothing backs, adds what the code shows and the doc misses, and brings an older doc up to the current format. A doc citing a path that does not exist is never `unchanged`. It no longer rewrites all 8 docs from scratch, so the diff shows real drift. This saves output and review time, not reading: every claim is still checked. `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md` keep regenerating and byte-diffing.
- `/init:project-phases` drops "use the highest reasoning effort / do not rush", and no longer says "prefer more phases": each phase costs a ralph session plus its gates.

## [0.10.0] - 2026-11-09

### Added

- `/plan` checks whether the project is ready for an isolated ralph session (#17). At the decomposition checkpoint it asks one question: will ralph run the plan with `--engine claude`? If yes, the summary lists only what a PHASES.md task needs and the project lacks: an MCP server missing from `.mcp.json` (checked with `grep -q`, never printed, since its `env` can hold keys), a skill that is neither in `.claude/skills/` nor in a plugin the project enables, or a test command for gate 2. It ends with one line saying hooks and rules from `~/.claude` don't load, and never reads `~/.claude`. It only suggests: `/plan` still writes only under `.spec/features/<slug>/`. The handoff then shows `./ralph.sh --engine claude`, since ralph's default engine is `codex`. A live probe on Claude Code 2.1.319 decided the skill row: under the isolation flags, the project's `.claude/skills/` and `.claude/commands/` load, and so do the skills, commands, and agents of a plugin the project enables; `~/.claude/skills/` does not. The READMEs gain a `Session isolation (claude engine)` heading for the isolation notes, with this result.
- `/plan` shows when the context tree may be stale. At the architecture gate it lists up to 5 ralph commits (`feat(phase-N)` or `wip(phase-N)`) that are not ancestors of the last commit that touched `AGENTS.md` or `docs/agents/`, and says to re-run `/ai-context` if any changed architecture, rules, or contracts. It never blocks. It stays silent with no git, a tree never committed, no ralph commit since, or uncommitted edits to the tree. Limits: a squash merge drops the `feat(phase-N)` subjects, so the list misses those runs; and when `/ai-context` finds no drift it writes nothing, so the same list shows again until the next commit that touches the tree.
- `/ai-context` marks a deduced business rule. In `domain_rules.md`, a rule deduced from a pattern (names, repeated checks, comments), with no condition, validation, or constant in the code that states it, ends its heading with `(inferida)`. The specifier never puts such a rule in RIGID on its own: it confirms it in the code or marks `[NEEDS CLARIFICATION]`. The planner treats it as an assumption.

### Fixed

- The install instructions in both READMEs and the Codex manifest's `homepage` and `repository` point to this fork, `wisleyaguiar/aguiarweb-harness`, where the releases are. They pointed to `beerandcodeteam/beer-and-code-harness`, which has no release. Claude Code installs through `/plugin marketplace add` first: the `/plugin install bc-harness` the README showed found no marketplace. The READMEs now say the project is a fork.

## [0.9.0] - 2026-11-09

### Changed

- `ralph.sh` (claude engine): every session runs isolated from the user's `~/.claude/` config, with `--setting-sources project,local --strict-mcp-config`, plus `--mcp-config .mcp.json` when the project root has one. User plugins, MCP servers, hooks, settings (including `env` and `apiKeyHelper`), and `CLAUDE.md` no longer load. The project's `CLAUDE.md` and `.claude/settings*.json` still do, and bc-harness's `sail-guard` hook comes back through `--settings` when `sail-guard.sh` sits next to `ralph.sh`. A session goes from 676 tools and 29 MCP servers (#13) to 25 and 0 (live probe), and a user rule that called `advisor` no longer applies. Guard or notification hooks that live only in `~/.claude/settings.json` stop applying: move them to the project's `.claude/settings.json`, or set `RALPH_ISOLATE=0` to load everything as before.
- `/plan` planner: phases follow size, not dependency (#13). Dependent tasks share a phase, in order, because the ralph session runs them in order. A new phase opens only for `size` (10–15 tasks), a `High`-risk task, or a `checkpoint: T0N` that must land in its own commit. The PLAN's Execution Phases table names that reason in a new `Why a new phase` column, which replaces `Parallel-safe?`. #13 proposed a new phase whenever the route changes. Here only `High` splits: `Low` and `Medium` tasks share a phase at the higher route, because a phase's fixed cost (fresh session plus gates 2 and 3) is larger than the gap between `haiku` and `sonnet`. A phase made only of test or gate runs joins the last implementation phase. `plan-reviewer` reports a split with no valid reason as a Major.
- `ralph.sh` gate 3: a wrong acceptance criterion no longer looks like wrong code (#13). The verifier can emit `TASK <n>: BLOCKED — <criterion> contradicts <requirement>` when the criterion as written cannot be met without breaking the requirement, another task, or the spec, or without touching a file no task asks for. A `BLOCKED` ends the phase with no fix cycle. `run.tsv` records the phase and the task as `blocked`, the panel shows `⊗ Bloqueada`, and the run stops as `failed` like any failed phase. From cycle 2 on, `SCOPE: WARN` fails gate 3 instead of only warning. It covers every file the phase changed, so a file cycle 1 added outside scope fails cycle 2 too. The fix prompt forbids files outside the tasks' `Arquivos:` lines, when the phase has them. In #13, cycle 2 edited a component outside the phase just to make a number pass. `/retro` reads `BLOCKED` and sends you to fix the criterion, not the model.
- `/plan` planner: a position criterion between neighboring blocks compares their edges with `≥`/`≤` or says "não sobrepõe", never `>`, `<`, or `=` (#13). Stacked blocks touch, so `top da foto > base do texto` failed correct code in #13, and gate 3 now ends such a phase as `BLOCKED`. `plan-reviewer` reports `>`, `<`, or `=` between neighboring blocks as a Blocker, so the planner fixes it before the checkpoint.
- `/plan` tier also follows size, not only the requirement count (#13). A small surface (≤ 5 files touched, no schema or migration change, no new or changed API route) makes a story `light` whatever its RF count. It overrides the count only: multi-repo, contracts, messaging, and domain-heavy still raise the tier, and if any of the three facts is unknown the count decides. In #13, a 48-line UI change with 9 thin RFs came out `standard` with 5 phases. The input checkpoint shows the signal that set the tier and says you can correct it. `specifier` no longer reports a `tier_mismatch` on RF count alone for a `light` story.
- `/retro` always ends with a cost table, even on a clean run (#13). It reads the last `result` event of each `.phases/logs/*.cycle-*.log` (claude engine): duration, API time, `total_cost_usd`, and the cost per model from `modelUsage`, plus a total. It needs only awk (no jq or python), and it skips `model_usage_since_last_result`, which repeats the same models. In #13, phases 1 to 4 passed clean, so `/retro` had no failure to read, yet 72% of the implementation cost went to an `advisor` model no route named. Gate 3 verifier sessions log plain text, so they are not in the table. The "raise the `**Route:**`" candidate after a step-up now applies only when the cause was not a criterion or scope problem; otherwise the stronger model only got around the criterion.

### Fixed

- `ralph.sh` closes `run.tsv` as `failed` at once when it is stopped mid-session (#13). Claude Code's TaskStop sends TERM to the process group and SIGKILL about a second later. With the engine in the foreground, bash ran the trap only after the session ended, so SIGKILL came first and `run.tsv` stayed `META status running`. Engine sessions (all three engines, including the gate 3 verifier and the route decision) and the gate 2 test command now run in the background behind `wait`, which a signal interrupts at once. The trap then stops the session or test still running. A command started this way ignores SIGINT, so without that step a Ctrl-C would leave the engine editing the repo alone. A TERM sent to ralph alone also stops the session now, instead of letting it run to the end.

## [0.8.0] - 2026-11-04

### Added

- `TESTING.md`: a record of what ran on real hosts (version, date, what ran) and a list of what has not run live yet.
- `/ai-context` warns about file paths cited in the generated docs that do not exist in the repo (backticked paths with a `/` and an extension; globs, URLs, and placeholders are skipped). A warning never stops the run.
- `/plan` reviews the plan with a fresh-context agent, `plan-reviewer`, on `standard` and `complete` tiers. It reads only what a `ralph.sh` session reads (project docs, init chain, SPEC, PLAN, PHASES) and writes `.handoff/plan-review.md`: a paraphrase of the plan and the findings a fresh implementer would hit (decisions left open, missing files, acceptance criteria that cannot be checked). Blockers go back to the planner once; the checkpoint shows the paraphrase and what is still open.
- `/plan` checks that every RF and UI requirement in the SPEC's RIGID section is covered by a task in `PHASES.md`. It sends the uncovered ones back to the planner once, then asks you about any still left.

### Changed

- `ralph.sh`: when gate 3 fails a task that it passed in an earlier cycle, the fix prompt says the last fix broke it. The source is the earlier cycle's verifier log, not what the agent marked done.
- The three `/ai-context` agents start without your `CLAUDE.md` files (user, project, local) on Claude Code 2.1.271+ (`omitClaudeMd`). They read the project's `AGENTS.md` and `CLAUDE.md` from disk as the files to regenerate, never as instructions. Claude Code only; `agy plugin validate` accepts the key.
- `/plan` marks each file of a task as create, modify, or delete (`Arquivos: ... (criar)` in `PHASES.md`), searches the code for an existing module before it plans a new one, and leaves no design choice (schema, API path, dependency, edge case) to the session that implements the task.

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
