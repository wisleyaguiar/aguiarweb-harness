---
name: bc-harness-retro
description: Run a read-only retrospective on the last Beer and Code Harness ralph.sh run from .phases/state/, .phases/prompts/, and .phases/logs/, and rank changes to the phase document, test command, checks, and AGENTS.md that would make the next run pass sooner.
disable-model-invocation: true
user-invocable: false
---

# Run a retrospective

1. Resolve the plugin root as the directory two levels above this `SKILL.md`.
2. Read `<plugin-root>/commands/retro.md` completely and follow it.
3. Treat its YAML frontmatter as Claude metadata.

Use equivalent Codex tools for Claude tool names. Preserve the command's read-only rule: propose changes, never apply them.
