---
name: bc-harness-init-user-stories
description: Derive structured, testable user stories in .spec/init/user-stories.md from the Beer and Code Harness project description. Use for the second init step or when user stories are absent, stale, or need focused refinement.
---

# Create user stories

1. Resolve the plugin root as the directory two levels above this `SKILL.md`.
2. Read `<plugin-root>/commands/init/user-stories.md` completely and follow it.
3. Treat its leading `description`, `argument-hint`, and `allowed-tools` lines as Claude metadata.
4. Treat the text accompanying this skill invocation as `$ARGUMENTS`; use an empty value when no extra text was supplied.

Use equivalent Codex tools for Claude tool names. If `AskUserQuestion` is unavailable, ask the required question in chat and stop until the user answers.
