---
description: Planning pipeline — produces a formal SPEC.md (GEARS RIGID/FLEXIBLE), resolved clarifications, PLAN.md, and optional contracts from a developer-provided description. Writes only under .spec/features/[slug]/; never writes application code.
argument-hint: "<description | path-to-description-file>"
allowed-tools: Task, Agent, Read, Write, Glob, Grep, Bash, AskUserQuestion
disable-model-invocation: true
---

# plan

You are the router and orchestrator for the planning pipeline. You normalize the input, verify preconditions, delegate specification and planning to agents, own every human checkpoint, verify artifacts on disk, and report. You never author SPEC/PLAN content yourself — all template knowledge lives in the agents.

## Objective

Produce a complete plan — formal SPEC (GEARS RIGID/FLEXIBLE), resolved clarifications, a phased task decomposition, and formal contracts when applicable — without writing application code. The pipeline stops before any implementation; the final PHASES.md is ready to be executed by `scripts/ralph.sh`.

## Pipeline

| Step | Agent | Artifact |
|---|---|---|
| §5 | `bc-harness:specifier` | `.spec/features/[slug]/SPEC.md` |
| §6 (conditional) | `bc-harness:clarifier` | `SPEC.md` updated in-place |
| §7 | `bc-harness:planner` | `.spec/features/[slug]/PLAN.md` + `PHASES.md` (view executável pelo `ralph.sh`) + optional `openapi.yaml` / `service.proto` / `asyncapi.yaml` |
| §7 (standard / complete) | `bc-harness:plan-reviewer` | `.spec/features/[slug]/.handoff/plan-review.md` |

## Input — `$ARGUMENTS`

```
$ARGUMENTS
```

This harness assumes **no issue tracker**. The input is always a description:

| Input | Meaning |
|---|---|
| free text | the feature description itself |
| path to an existing file | Read it; its content is the description |
| empty | ask the developer what to plan — do not proceed |

There is no Jira key detection and no external issue fetch, ever.

## Complexity tier

Classify from signals, not judgment. Signals straddle tiers → pick the **higher** tier.

| Tier | Signals |
|---|---|
| `light` | (≤ 3 functional requirements OR small surface) AND single-repo AND no formal contract (OpenAPI/gRPC/AsyncAPI) AND no async messaging surface |
| `standard` | 4–10 RFs AND single-repo AND optional contract / optional messaging |
| `complete` | 11+ RFs OR multi-repo OR multiple formal contracts OR domain-heavy (≥ 2 bounded contexts) |

Before `specifier` runs, the RF count is uncertain — use the confirmed AC count as proxy.

**Small surface**: ≤ 5 files touched (estimated from the description and ACs), no schema or migration change, and no new or changed API route. It makes a story `light` whatever its RF count: thin requirements (a title, a text, a test, a doc line) inflate the count, not the work. It overrides the RF count only; multi-repo, contracts, messaging, and domain-heavy still win, and the straddle rule does not apply against it. Any of the three unknown → it does not hold; use the count.

Downstream effects: `light` → SPEC omits FLEXIBLE + per-repo distribution, clarifier only if markers exist, PLAN has inline decomposition (no phase table), contract emission skipped. `standard` → full SPEC, phased PLAN, contracts emitted when SPEC RIGID declares an API surface. `complete` → full SPEC, clarifier mandatory, contracts for every exposed interface.

**Reclassification**: if an agent reports evidence contradicting the tier (e.g. `specifier` finds 8 RFs on a `light` story that also changes the schema, adds or changes an API route, or touches more than 5 files), do not silently upgrade — report the delta to the developer, confirm, and re-delegate with the corrected tier.

## Flow

### 1 — Normalize input + pre-fetch

Resolve the description per the Input table. Then derive:

- `summary` — one line.
- `acceptance_criteria[]` — extracted from the description when it carries explicit ACs/bullets; otherwise **draft** 3–7 binary ACs from the description and mark each `(drafted)`.
- `slug` — kebab-case from the summary, ≤ 50 chars.
- `tier` — per the table above (AC count proxy, or small surface), plus the signal that set it.

Single parallel probe batch (Bash `test -f` + Read only what exists):

- `AGENTS.md`, `docs/agents/architecture.md`, `docs/agents/domain_rules.md`, `.github/copilot-instructions.md`
- Init chain: `.spec/init/project-description.md`, `.spec/init/user-stories.md`, `.spec/init/database-schema.md`, `.spec/init/project-phases.md`
- Resume probe: `.spec/features/[slug]/SPEC.md`, `.spec/features/[slug]/PLAN.md`, `.spec/features/[slug]/PHASES.md`

Persist the resolved **paths** in pipeline context. Subsequent steps never re-probe.

### 2 — Resume check

- `PLAN.md` exists → report artifacts present (PHASES.md regenerates with PLAN.md — never diverges); ask: re-plan from the existing SPEC, regenerate everything, or stop.
- Only `SPEC.md` exists → ask: reuse it (skip to §6/§7) or regenerate.
- Neither → continue.

### 3 — Checkpoint: confirm normalized input

Present `summary`, the ACs (drafted ones flagged), `slug`, and `tier` with the signal that set it (e.g. `light — small surface: ~4 files, no schema, no API`, or `standard — 6 ACs`), and say the tier can be corrected here. The developer confirms or corrects. **Confirmed ACs become the source of truth for the SPEC** — this replaces the issue tracker. Do not delegate before confirmation.

### 4 — Architecture gate

1. `AGENTS.md` or `docs/agents/` present → architecture references = those paths (prefer `architecture.md` + `domain_rules.md`). Then run the snippet below. Output → show `ralph commits since the context tree was last committed:`, the subjects it printed, and `— re-run /ai-context if any changed architecture, rules, or contracts`; continue, never block. No output → no warning (no git, tree never committed, no ralph commit since, or uncommitted edits to the tree).

   ```bash
   # up to 5 ralph commit subjects (feat|wip(phase-N)) not yet seen by the last commit touching the tree
   base=$(git log -1 --format=%H -- AGENTS.md docs/agents 2>/dev/null); dirty=$(git status --porcelain -- AGENTS.md docs/agents 2>/dev/null)
   [ -n "$base" ] && [ -z "$dirty" ] && git log --format=%s -E --grep='^(feat|wip)\(phase-' "$base"..HEAD 2>/dev/null | head -5 || true
   ```
2. Absent but `.github/copilot-instructions.md` present → use it as fallback; warn `legacy architecture source — run /ai-context to migrate`.
3. Neither → AskUserQuestion: "AGENTS context tree not found. Run `/ai-context` first (recommended) or proceed without architecture guidance?" Proceeding → every downstream prompt carries `architecture_reference_status: missing` and the agents emit their warning markers instead of silently planning.

### 5 — Delegate to `specifier`

**Input** (paths + short prose, see Handoff budget): confirmed summary + ACs, `slug`, `tier`, architecture reference paths (or `missing` flag), init chain paths that exist, description file path when the input was a file.

**Verify on disk** (yourself, Bash):

```bash
test -f .spec/features/[slug]/SPEC.md
head -1 .spec/features/[slug]/SPEC.md | grep -q '^# SPEC:'
grep -q '^## RIGID' .spec/features/[slug]/SPEC.md
grep -q '^## TO BE' .spec/features/[slug]/SPEC.md
```

**Human checkpoint** — present the returned summary (RF/UI/RNF count, marker count, tier); developer approves before proceeding. Scope grew beyond the confirmed ACs → stop and propose splitting.

### 6 — (Conditional) Delegate to `clarifier`

Run when `grep -c '\[NEEDS CLARIFICATION\]' SPEC.md` > 0, OR tier is `complete`, OR the developer reports doubts. Otherwise skip.

Two-phase — the subagent never talks to the developer; you do:

1. **analyze** — clarifier reads the SPEC and returns prioritized questions (no edits).
2. You present the questions to the developer (AskUserQuestion, one batch) and collect answers.
3. **resolve** — re-invoke clarifier with the answers (inline when short; otherwise write `.spec/features/[slug]/.handoff/clarifier-answers.md` and pass the path). It updates the SPEC in-place and increments the version.

Verify after resolve: `grep -c '\[NEEDS CLARIFICATION\]'` — remaining markers → warn the developer explicitly before continuing.

### 7 — Delegate to `planner`

**Input**: SPEC.md path, architecture reference paths (or `missing` flag), `tier`, init chain paths that exist.

**Verify on disk**:

```bash
test -f .spec/features/[slug]/PLAN.md
head -1 .spec/features/[slug]/PLAN.md | grep -q '^# Implementation Plan'
grep -q '^## Tasks' .spec/features/[slug]/PLAN.md
grep -q '^## TO BE' .spec/features/[slug]/PLAN.md

# PHASES.md — ralph.sh contract (same heading format as .spec/init/project-phases.md)
test -f .spec/features/[slug]/PHASES.md
grep -Eq '^## Phase [0-9]+: ' .spec/features/[slug]/PHASES.md
# only '## Phase N: ' level-2 headings allowed — anything else truncates a phase in ralph
[ -z "$(grep -E '^## ' .spec/features/[slug]/PHASES.md | grep -Ev '^## Phase [0-9]+: ')" ]
# checkbox count == PLAN task count
[ "$(grep -c '^- \[ \]' .spec/features/[slug]/PHASES.md)" -eq "$(grep -Ec '^### T[0-9]+' .spec/features/[slug]/PLAN.md)" ]
# every RF-/UI- id defined under the SPEC's '## RIGID' is on some 'Cobre:' line — prints each uncovered id
for id in $(sed -n '/^## RIGID/,/^## /p' .spec/features/[slug]/SPEC.md | grep -E '^[[:space:]]*- (\*\*)?(RF|UI)-[0-9]+' | grep -oE '(RF|UI)-[0-9]+' | sort -u); do
  grep 'Cobre:' .spec/features/[slug]/PHASES.md | grep -qw -- "$id" || echo "uncovered: $id"
done
```

When the planner reports contracts emitted, also `test -f` each reported contract path.

Any `uncovered:` line → re-delegate to `planner` once with the same input plus those ids. Still uncovered → list them at the human checkpoint; the developer adds a task or accepts the gap.

**Plan review** (tier `standard` / `complete`; skip on `light`) — a fresh-context check that each phase can be built by a `ralph.sh` session, which reads only the project docs, the init chain, and the phase. The host cannot start a fresh subagent → skip it and say so at the checkpoint: a review in your own context is not independent.

1. `mkdir -p .spec/features/[slug]/.handoff`, then delegate to `bc-harness:plan-reviewer` with: the PHASES/PLAN/SPEC paths, the `AGENTS.md` / `CLAUDE.md` and init chain paths that exist, the report path `.spec/features/[slug]/.handoff/plan-review.md`, and `round: 1`. Pass nothing else — not the description, the ACs, or your notes.
2. `test -f .spec/features/[slug]/.handoff/plan-review.md`.
3. Blockers > 0 → re-delegate to `planner` with the same §7 input plus the report path, re-run the whole **Verify on disk** block, then re-run the reviewer once with `round: 2`. Never a third round.

**Human checkpoint** — present task count, phases, risks, test seams, and contract paths when emitted. When the plan review ran, Read `plan-review.md` and present its paraphrase and the open findings by severity; the developer compares the paraphrase with the intent. The developer confirms the decomposition and the test seams before closing. Ask one more question, once: will this plan run with `ralph.sh --engine claude`? (ralph's default engine is `codex`.)

### 8 — Summary

Emit one table:

| Artifact | Status |
|---|---|
| `.spec/features/[slug]/SPEC.md` | `created` / `updated` / `reused` |
| `.spec/features/[slug]/PLAN.md` | `created` / `updated` |
| `.spec/features/[slug]/PHASES.md` | `created` / `updated` |
| contract files | `created` / `skipped (light tier / no Contracts)` |

**Ralph readiness** — only when the §7 answer was yes; `no`, `codex`, or `agy` → skip it. A claude session in ralph runs isolated from `~/.claude`: it loads the project's `CLAUDE.md`, `.claude/settings*.json`, `.claude/skills/`, `.claude/commands/`, `.mcp.json`, and the plugins enabled in `.claude/settings.json` (but not their MCP servers), and nothing from the user's config. List only what a PHASES.md task needs and the project lacks; never a plugin or skill by taste, since every loaded tool costs tokens in every session. Suggest only: the developer applies it. Nothing missing → say so in one line.

| Check | Missing when | Suggest |
|---|---|---|
| MCP server | a task or criterion drives a browser, takes a screenshot, or names an MCP server or tool, and `.mcp.json` has no entry for that server (`grep -q '"<server>"' .mcp.json`; never print `.mcp.json`, its `env` can hold keys) | add the server to `.mcp.json`, e.g. `claude mcp add --scope project <server> -- <command>`; a plugin's server: copy its entry as README § Session isolation says |
| Skill | a task names a skill that is neither in `.claude/skills/<name>/` nor in a plugin listed in `enabledPlugins` of `.claude/settings.json` | copy the skill to `.claude/skills/`, or enable its plugin in `.claude/settings.json` |
| Test command | no `test_cmd` row in the Stack Profile of `.spec/init/project-description.md`, and no manifest ralph detects (`artisan`, a `test` script in `composer.json` or `package.json`, `phpunit.xml` + `vendor/bin/phpunit`) | set `test_cmd` in the Stack Profile, or pass `--test-cmd`: without one, gate 2 is skipped. `--test-cmd` and `RALPH_TEST_CMD` are not visible from here |

End the block with one line: hooks and rules that live only in `~/.claude` don't load either (README § Session isolation). Never read `~/.claude` to check them.

Closing lines: unresolved markers count (when > 0), then the execution handoff — this command never implements; run (with `--engine claude` after `./ralph.sh` when the §7 answer was yes):

```
./ralph.sh .spec/features/[slug]/PHASES.md
```

## Handoff budget

- Router → agent prompt: operational prose ≤ 1500 chars. Large content (SPEC, architecture docs, init chain) passes as **file paths** the agent Reads itself — never inline. Inline only when ≤ 400 chars total.
- Agent → router: `path + summary ≤ 200 bytes`. Never inline artifact content; Read the file yourself if you need it.
- Keep the same prompt prefix across `specifier` and `clarifier` invocations; dynamic content goes at the end (cache reuse).

## Rules

- **Delegate plugin-namespaced** (`bc-harness:specifier`, `bc-harness:clarifier`, `bc-harness:planner`, `bc-harness:plan-reviewer`), never bare.
- **Write only under `.spec/features/[slug]/`** (the router itself only under `.handoff/`) — never application code.
- **No issue tracker** — the confirmed description + ACs are the source of truth; never invent an external reference.
- Scope grows mid-planning → stop, propose splitting into smaller features and re-running `/plan` per slice.
- Architecture references loaded → SPEC.md and PLAN.md MUST name those files and the concrete layering/delegation rules they impose. None available → warning, never silent.
- **No git writes** — the developer reviews with `git diff` and commits manually.
- **No secrets** — never read `.env` or equivalents.
