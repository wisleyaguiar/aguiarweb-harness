---
name: bc-harness-init-project-description
description: Discover a project's existing technology stack, interview the developer, and create or refresh .spec/init/project-description.md with a confirmed Stack Profile. Use for the first Beer and Code Harness init step or when the project description must be updated.
---

# Create the project description

1. Resolve the plugin root as the directory two levels above this `SKILL.md`.
2. Read `<plugin-root>/commands/init/project-description.md` completely and follow it.
3. Treat its leading `description`, `argument-hint`, and `allowed-tools` lines as Claude metadata.
4. Treat the text accompanying this skill invocation as `$ARGUMENTS`; use an empty value when no extra text was supplied.
5. Resolve any mentioned plugin-relative file, especially `profiles/`, from the plugin root found in step 1.

Use equivalent Codex tools for Claude tool names. If `AskUserQuestion` is unavailable, ask the required question in chat and stop until the user answers.
