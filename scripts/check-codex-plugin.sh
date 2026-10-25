#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])

def load_json(relative):
    path = root / relative
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)

claude = load_json(".claude-plugin/plugin.json")
codex = load_json(".codex-plugin/plugin.json")
hooks = load_json("hooks/hooks.json")

for field in ("name", "version", "description"):
    assert codex.get(field), f"missing Codex manifest field: {field}"
for field in ("name", "version"):
    assert codex[field] == claude[field], f"manifest drift: {field}"
marketplace = load_json(".claude-plugin/marketplace.json")
# plugin.json owns the plugin version; a second copy in the marketplace only drifts.
assert "version" not in marketplace.get("metadata", {}), "marketplace metadata must not carry a version"
for entry in marketplace["plugins"]:
    assert "version" not in entry, f"marketplace entry {entry['name']} must not carry a version"
released = re.search(r"^## \[(\d+\.\d+\.\d+)\]", (root / "CHANGELOG.md").read_text(encoding="utf-8"), re.MULTILINE)
assert released and released.group(1) == claude["version"], (
    f"CHANGELOG.md: latest release must be {claude['version']}, the manifest version"
)

assert codex.get("skills") == "./skills/", "Codex manifest must load ./skills/"
interface = codex.get("interface", {})
for field in (
    "displayName",
    "shortDescription",
    "longDescription",
    "developerName",
    "category",
    "capabilities",
    "defaultPrompt",
):
    assert interface.get(field), f"missing Codex interface field: {field}"

expected = {
    "bc-harness-ai-context",
    "bc-harness-init",
    "bc-harness-init-database-schema",
    "bc-harness-init-project-description",
    "bc-harness-init-project-phases",
    "bc-harness-init-user-stories",
    "bc-harness-plan",
    "bc-harness-retro",
}
skills_root = root / "skills"
actual = {path.name for path in skills_root.iterdir() if path.is_dir()}
assert actual == expected, f"skill set drift: expected {sorted(expected)}, got {sorted(actual)}"

for name in sorted(expected):
    skill = skills_root / name / "SKILL.md"
    text = skill.read_text(encoding="utf-8")
    assert text.startswith("---\n"), f"{name}: missing YAML frontmatter"
    frontmatter = text.split("\n---\n", 1)[0]
    assert re.search(rf"^name:\s*{re.escape(name)}$", frontmatter, re.MULTILINE), (
        f"{name}: frontmatter name mismatch"
    )
    assert re.search(r"^description:\s*\S", frontmatter, re.MULTILINE), (
        f"{name}: missing description"
    )
    assert "[TODO:" not in text, f"{name}: unresolved TODO placeholder"
    # Claude Code always loads skills/ next to commands/: the wrapper must stay out of its menu and context.
    for key in (r"disable-model-invocation:\s*true", r"user-invocable:\s*false"):
        assert re.search(rf"^{key}$", frontmatter, re.MULTILINE), f"{name}: wrapper frontmatter needs {key}"

    agent_yaml = skills_root / name / "agents/openai.yaml"
    agent_text = agent_yaml.read_text(encoding="utf-8")
    assert f"${name}" in agent_text, f"{name}: default prompt must mention the skill"
    assert re.search(r"^\s+allow_implicit_invocation:\s*false$", agent_text, re.MULTILINE), (
        f"{name}: Codex skill must be explicit-only (${name})"
    )

for prompt in interface["defaultPrompt"]:
    assert "$bc-harness-" in prompt, f"Codex defaultPrompt must name a skill explicitly: {prompt!r}"

def command_frontmatter(relative):
    return (root / relative).read_text(encoding="utf-8").split("\n---\n", 1)[0]

for name in ("init", "plan", "ai-context", "retro"):
    assert re.search(r"^disable-model-invocation:\s*true$", command_frontmatter(f"commands/{name}.md"), re.MULTILINE), (
        f"commands/{name}.md must be user-invoked"
    )
for path in sorted((root / "commands/init").glob("*.md")):
    # /init hops to these via the Skill tool; disable-model-invocation would block the hop.
    assert "disable-model-invocation" not in command_frontmatter(path.relative_to(root)), (
        f"{path.relative_to(root)} must stay reachable by /init"
    )

command = hooks["hooks"]["PreToolUse"][0]["hooks"][0]["command"]
assert "PLUGIN_ROOT" in command and "CLAUDE_PLUGIN_ROOT" in command, (
    "hook must support Codex and Claude plugin roots"
)

antigravity = load_json("plugin.json")
assert set(antigravity) <= {"$schema", "name", "version", "description"}, (
    "Antigravity manifest keeps only $schema, name, version, description"
)
for field in ("name", "version"):
    assert antigravity.get(field) == claude[field], f"manifest drift: Antigravity {field}"
agy_hooks = load_json("hooks.json")
agy_command = agy_hooks["sail-guard"]["PreToolUse"][0]["hooks"][0]["command"]
assert agy_command == "./scripts/sail-guard.sh --antigravity", (
    "Antigravity hook must run sail-guard relative to the plugin root"
)
for path in sorted((root / "agents").glob("*.md")):
    # Antigravity skips an agent whose tools is a comma-separated string; Claude Code takes both forms.
    assert re.search(r"^tools:[ \t]*(\[|$)", command_frontmatter(path.relative_to(root)), re.MULTILINE), (
        f"{path.relative_to(root)}: tools must be a YAML list for Antigravity"
    )

print("Codex and Antigravity plugin structure OK")
PY

# sail-guard --antigravity: deny vira JSON no stdout; passagem = stdout vazio
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/vendor/bin" && touch "$TMP/vendor/bin/sail"
agy_guard() {
  printf '{"toolCall":{"name":"run_command","args":{"CommandLine":"%s","Cwd":"%s"}}}' "$1" "$TMP" |
    "$ROOT/scripts/sail-guard.sh" --antigravity
}
agy_guard "php artisan migrate" | grep -q '"decision": *"deny"' ||
  { echo "sail-guard --antigravity did not deny host artisan" >&2; exit 1; }
[ -z "$(agy_guard "echo hi")" ] ||
  { echo "sail-guard --antigravity must stay silent on pass" >&2; exit 1; }
echo "sail-guard Antigravity mode OK"
