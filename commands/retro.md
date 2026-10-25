---
description: Retrospective on the last scripts/ralph.sh run — reads .phases/state/, .phases/prompts/ and .phases/logs/ and ranks changes to the agent's environment (phase document, test command, checks, AGENTS.md) that would make the next run smoother. Read-only; writes nothing.
allowed-tools: Read, Glob, Grep, Bash
disable-model-invocation: true
---

# retro

You run a retrospective on the last `scripts/ralph.sh` run in this repository. You read what the run left on disk, find where it lost fix cycles or drifted, and propose changes to the agent's **environment** — the phase document, the test command, mechanical checks, `AGENTS.md`/`CLAUDE.md` — so the next run passes sooner. You propose; the developer picks what to apply.

## Sources

ralph deletes `.phases/` at the start of every run, so everything below belongs to the **last run only**. A phase done in an earlier run shows as `done` with attempt `0`, one before `--from N` as `skipped`; neither has logs.

| Source | What it holds |
|---|---|
| `.phases/state/run.tsv` | Tab-separated. `META <key> <value>` — `status`, `engine`, `input`, `test_cmd` (`—` = none resolved), `last_error`<br>`PHASE <n> <status> <attempt> <gates> <title>` — `<gates>` is 4 words, gates 0–3, each `pending`/`run`/`pass`/`fail`/`skip`, **last cycle only**<br>`TASK <phase> <i> <status> <title>` |
| `.phases/manifest.txt` | `<slug>.md\|<n>\|<title>` — maps a phase number to the `<slug>` the files below are named after |
| `.phases/prompts/<slug>.cycle-<N>.txt`, N ≥ 2 | the fix prompt; its `## Motivo da falha (<gate>)` block is the real cause cycle N−1 failed |
| `.phases/logs/<slug>.verify-<N>.log` | gate 3 verdicts: `TASK <n>: DONE`/`INCOMPLETE — …`, `SCOPE: OK`/`WARN — …`, `STANDARDS: OK`/`WARN — …`. Codex echoes them more than once; the last one wins |
| `.phases/logs/<slug>.test-<N>.log` | gate 2 output |
| `.phases/logs/<slug>.cycle-<N>.log` | the engine session — large; grep it, read only the lines you need |
| `git log --oneline --grep '^wip(phase-'` | phases committed incomplete under `--keep-going` |

## Flow

### 1 — Locate the run

```bash
cat .phases/state/run.tsv 2>/dev/null || echo "no run state"
```

No `run.tsv` → report `No ralph.sh run found here — run scripts/ralph.sh first.` and stop.

### 2 — Collect the friction

```bash
grep -v '^#' .phases/manifest.txt
awk '/^## Motivo da falha/{p=1; print "== " FILENAME} /^## Fase a completar/{p=0} p' .phases/prompts/*.cycle-*.txt 2>/dev/null
# the verifier can echo or revise a verdict: keep the last one per task and axis
awk '{ sub(/^[ \t]+/, "") }
     /^(TASK [0-9]+|SCOPE|STANDARDS): / { last[FILENAME SUBSEP substr($0, 1, index($0, ":"))] = FILENAME ": " $0 }
     END { for (k in last) if (last[k] ~ /: (INCOMPLETE|WARN)/) print last[k] }' .phases/logs/*.verify-*.log 2>/dev/null | sort
git log --oneline --grep '^wip(phase-'
```

A phase has friction when its attempt is above 1, its status is `failed`, a gate reads `fail`, a task is not `done`, or a verify log of it carries a `WARN`. Open the test log or grep the cycle log of that phase only when the cause above does not explain it.

Done when every phase with friction has its cause written down next to the source path it came from.

### 3 — Classify

Turn each cause into one candidate. First match wins:

| Signal | Candidate |
|---|---|
| Phase `failed`, or a `wip(phase-N)` commit | Unfinished work. Name the tasks still open; they come first in the report. |
| `test_cmd` is `—` (gate 2 `skip` on every phase) | No test command resolved, so gate 3 held the line alone. Set `test_cmd` in the Stack Profile of `.spec/init/project-description.md`, or pass `--test-cmd`. |
| Gate 2 `fail` | Read the test log: a real bug the next cycle fixed, a flaky test, or a service, seed, or fixture the session could not reach (information access). |
| `TASK <n>: INCOMPLETE` across cycles | The phase or task is too big or too vague. Split the phase (10–15 tasks, one session) or sharpen the task in the phase document. |
| `STANDARDS: WARN` | A convention the implementer missed. A **mechanical** rule (banned API, import shape, file location, naming pattern) becomes a lint rule, hook, or test, which gate 2 then enforces on every phase. A **judgement** rule becomes one line in `AGENTS.md`/`CLAUDE.md`. |
| `SCOPE: WARN` | The session touched files no task names: a task is missing from the phase document, or its wording is too loose. |
| The cycle log shows the session searching for, or editing, the wrong files | A missing **navigation pointer**: add one line to `AGENTS.md` naming the file, or re-run `/ai-context`. |
| Gate 0 `fail` | The engine crashed or hit a limit. Environment, not instructions: note it, lowest severity. |

Before you propose a line for `AGENTS.md`/`CLAUDE.md`, read the file. A rule it already states means its wording failed: propose sharpening that line, not adding a second one. A line that would not change what the agent does by default is a **no-op**: drop the candidate.

### 4 — Report

Order candidates by severity: unfinished work, then cycles lost (most first), then warnings. One block per candidate:

- **Signal** — what happened, with the source path (e.g. `.phases/logs/03-auth.verify-2.log`).
- **Change** — the file to edit and the edit itself, in one or two lines.
- **Kind** — `phase document` / `test command` / `check` / `AGENTS.md` / `information access` / `engine`.

No phase has friction → report `Clean run — every phase passed on its first cycle with no warnings.`

## Rules

- **Read-only** — every change is a proposal; the developer applies it. Never Write, Edit, stage, or commit.
- **Evidence or nothing** — each candidate names the file its signal came from.
- **No secrets** — never read `.env` or equivalents.
