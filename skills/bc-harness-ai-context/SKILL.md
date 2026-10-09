---
name: bc-harness-ai-context
description: Generate or refresh the canonical AGENTS.md, CLAUDE.md, GEMINI.md, and docs/agents context tree from implemented repository code. Use when adopting Beer and Code Harness context documentation or when the existing agent context has drifted.
---

# Refresh the agent context tree

1. Resolve the plugin root as the directory two levels above this `SKILL.md`.
2. Read `<plugin-root>/commands/ai-context.md` completely and follow it.
3. Treat its leading `description`, `argument-hint`, and `allowed-tools` lines as Claude metadata.
4. Treat the text accompanying this skill invocation as `$ARGUMENTS`; use the current repository and no filters when no text was supplied.
5. Before each named-agent step, read the corresponding file completely:
   - `bc-harness:ai-context-inspector` → `<plugin-root>/agents/ai-context-inspector.md`
   - `bc-harness:ai-context-core` → `<plugin-root>/agents/ai-context-core.md`
   - `bc-harness:ai-context-docs` → `<plugin-root>/agents/ai-context-docs.md`
6. Delegate the inspector to an isolated subagent when supported. After receiving its digest, delegate both writers concurrently because their file sets are disjoint. If subagents are unavailable, execute the roles sequentially in the main thread.
7. Keep verification and reporting in the router.

Use the host's equivalent tools (Codex, Antigravity) for Claude tool names. Preserve the command's exclusion of planning artifacts and secrets.
