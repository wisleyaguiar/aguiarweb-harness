---
name: bc-harness-init-project-phases
description: Turn the Beer and Code Harness init artifacts and optional designs into numbered, agent-ready implementation phases at .spec/init/project-phases.md. Use for the final init step or when project phases are absent, stale, or need focused replanning.
---

# Create project phases

1. Resolve the plugin root as the directory two levels above this `SKILL.md`.
2. Read `<plugin-root>/commands/init/project-phases.md` completely and follow it with high planning rigor.
3. Treat its leading `description`, `argument-hint`, and `allowed-tools` lines as Claude metadata.
4. Treat the text accompanying this skill invocation as `$ARGUMENTS`; use an empty value when no extra text was supplied.
5. Resolve any mentioned plugin-relative profile from `<plugin-root>/profiles/`.

Use equivalent Codex tools for Claude tool names. If `AskUserQuestion` is unavailable, ask the required question in chat and stop until the user answers.
