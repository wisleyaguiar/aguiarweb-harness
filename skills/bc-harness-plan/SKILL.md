---
name: bc-harness-plan
description: Create a formal GEARS feature specification, resolve ambiguities, and produce an architecture-aware PLAN.md, PHASES.md, and optional contracts under .spec/features/. Use when the user wants Beer and Code Harness feature planning without application-code implementation.
---

# Plan a feature

1. Resolve the plugin root as the directory two levels above this `SKILL.md`.
2. Read `<plugin-root>/commands/plan.md` completely and follow it.
3. Treat its leading `description`, `argument-hint`, and `allowed-tools` lines as Claude metadata.
4. Treat the text accompanying this skill invocation as `$ARGUMENTS`; when invoked implicitly, use the user's feature request.
5. Before each named-agent step, read the corresponding file completely:
   - `bc-harness:specifier` → `<plugin-root>/agents/specifier.md`
   - `bc-harness:clarifier` → `<plugin-root>/agents/clarifier.md`
   - `bc-harness:planner` → `<plugin-root>/agents/planner.md`
6. Delegate those roles to isolated subagents when the host supports them. Provide the role inputs required by the command and agent file. If subagents are unavailable, execute the same role sequentially in the main thread.
7. Keep all human checkpoints in the router. If a dedicated input tool is unavailable, ask in chat and stop until the user answers.

Use equivalent Codex tools for Claude tool names. Preserve the command's prohibition on application-code changes.
