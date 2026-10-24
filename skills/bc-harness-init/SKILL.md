---
name: bc-harness-init
description: Inspect and advance the Beer and Code Harness project-init chain under .spec/init/. Use when the user wants to initialize a project, check which init artifacts are absent or stale, or continue to the next project-description, user-stories, data-model, or project-phases step.
disable-model-invocation: true
user-invocable: false
---

# Advance the init chain

1. Resolve the plugin root as the directory two levels above this `SKILL.md`. Never assume the session working directory is the plugin root.
2. Read `<plugin-root>/commands/init.md` completely and follow its workflow.
3. Treat its YAML frontmatter as Claude metadata, not workflow instructions.
4. Map a requested `SlashCommand` to the matching sibling skill below. Read that `SKILL.md` completely and execute it in the current turn:
   - `init:project-description` → `../bc-harness-init-project-description/SKILL.md`
   - `init:user-stories` → `../bc-harness-init-user-stories/SKILL.md`
   - `init:database-schema` → `../bc-harness-init-database-schema/SKILL.md`
   - `init:project-phases` → `../bc-harness-init-project-phases/SKILL.md`
5. Preserve the command's one-hop rule. Execute at most one authoring step per invocation.

Use equivalent Codex tools for Claude tool names. If required user input cannot be collected with a dedicated input tool, ask in chat and stop until the user answers.
