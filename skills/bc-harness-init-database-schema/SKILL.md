---
name: bc-harness-init-database-schema
description: Derive a database schema or CMS content model in .spec/init/database-schema.md from the Beer and Code Harness project description and user stories. Use for the third init step, including WordPress post-type, taxonomy, meta, and options modeling.
---

# Create the data model

1. Resolve the plugin root as the directory two levels above this `SKILL.md`.
2. Read `<plugin-root>/commands/init/database-schema.md` completely and follow it.
3. Treat its leading `description`, `argument-hint`, and `allowed-tools` lines as Claude metadata.
4. Treat the text accompanying this skill invocation as `$ARGUMENTS`; use an empty value when no extra text was supplied.

Use equivalent Codex tools for Claude tool names. If `AskUserQuestion` is unavailable, ask the required question in chat and stop until the user answers.
