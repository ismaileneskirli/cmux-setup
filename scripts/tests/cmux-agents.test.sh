#!/usr/bin/env bash
# Tests for scripts/cmux-agents. Run: scripts/tests/cmux-agents.test.sh
set -u

here=$(cd "$(dirname "$0")" && pwd)
agents="$here/../cmux-agents"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

now=1790000000
failures=0
check() { # name expected actual
  if [ "$2" = "$3" ]; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s\n     expected: %s\n     actual:   %s\n' "$1" "$2" "$3"; failures=$((failures + 1)); fi
}

cat > "$work/sessions.json" <<EOF
{"sessions": [
  {"surface_id": "S1", "workspace_id": "A", "agent": "claude", "agent_lifecycle": "needsInput", "updated_at_unix": $((now - 600)), "pid": 100},
  {"surface_id": "S2", "workspace_id": "A", "agent": "claude", "agent_lifecycle": "idle", "updated_at_unix": $((now - 3600)), "pid": 200},
  {"surface_id": "S2", "workspace_id": "A", "agent": "claude", "agent_lifecycle": "needsInput", "updated_at_unix": $((now - 7200)), "pid": 200},
  {"surface_id": "S3", "workspace_id": "B", "agent": "codex", "agent_lifecycle": "idle", "updated_at_unix": $((now - 3 * 86400)), "pid": 300},
  {"surface_id": "S4", "workspace_id": "B", "agent": "claude", "agent_lifecycle": "running", "updated_at_unix": $((now - 60)), "pid": 400},
  {"surface_id": "S5", "workspace_id": "B", "agent": "claude", "agent_lifecycle": "needsInput", "updated_at_unix": $((now - 5 * 86400)), "pid": 500},
  {"surface_id": "S6", "workspace_id": "B", "agent": "claude", "agent_lifecycle": "idle", "updated_at_unix": $((now - 60)), "pid": 600},
  {"surface_id": "S7", "workspace_id": "A", "agent": "opencode", "agent_lifecycle": "idle", "updated_at_unix": $((now - 60)), "pid": 700},
  {"surface_id": "S8", "workspace_id": "A", "agent": "claude", "agent_lifecycle": "needsInput", "updated_at_unix": $((now - 60)), "pid": 800},
  {"surface_id": "S9", "workspace_id": "A", "agent": "claude", "agent_lifecycle": "idle", "updated_at_unix": $((now - 60)), "pid": 900}
]}
EOF

cat > "$work/state.json" <<'EOF'
{"windows": [{"tabManager": {"workspaces": [
  {"workspaceId": "A", "customTitle": "guardrails", "panels": [
    {"id": "S1", "title": "✳ babysit-mr code review"}, {"id": "S2", "title": "⠂ Slack interactivity"},
    {"id": "S7", "title": "opencode"}, {"id": "S8", "title": "Claude Code"}, {"id": "S9", "title": "✳ Weekly report"}]},
  {"workspaceId": "B", "processTitle": "meta studio", "panels": [
    {"id": "S3", "title": "codex"}, {"id": "S4", "title": "✳ Running thing"}, {"id": "S5", "title": "✳ Old question"}]}
]}}]}
EOF

cat > "$work/prompts.json" <<'EOF'
{"S8": {"prompt": "create an mr to staging no preview", "at": 1789999940}}
EOF

# pid ppid rss(kB): S1 = 100 + child 101; S3 = 300 + child 301 + grandchild 302; S5 (pid 500) is gone.
cat > "$work/ps.txt" <<'EOF'
100 1 1000
101 100 500
200 1 700
300 1 2000
301 300 100
302 301 50
400 1 9999
800 1 10
900 1 20
EOF

export CMUX_AGENTS_SESSIONS_JSON="$work/sessions.json"
export CMUX_AGENTS_STATE_FILE="$work/state.json"
export CMUX_AGENTS_PROMPTS_FILE="$work/prompts.json"
export CMUX_AGENTS_PS_FILE="$work/ps.txt"
export CMUX_AGENTS_NOW="$now"
export CMUX_AGENTS_CURSOR_DIR="$work/cursor"

out=$("$agents" list --json)
check "list exits cleanly" "0" "$?"
check "waiting: needsInput within 48h, oldest first" "S1 S8" "$(printf '%s' "$out" | jq -r '[.waiting[].surface_id] | join(" ")')"
check "done: idle within 48h, newest first, duplicates collapse to the newest record" "S9 S2" "$(printf '%s' "$out" | jq -r '[.done[].surface_id] | join(" ")')"
check "stale: idle or waiting over 48h, oldest first" "S5 S3" "$(printf '%s' "$out" | jq -r '[.stale[].surface_id] | join(" ")')"
check "running, closed and non-coding-agent sessions are excluded" "0" "$(printf '%s' "$out" | jq '[.waiting, .done, .stale | .[] | select(.surface_id == "S4" or .surface_id == "S6" or .surface_id == "S7")] | length')"
check "workspace title from customTitle, falling back to processTitle" "guardrails|meta studio" "$(printf '%s' "$out" | jq -r '(.waiting[0].workspace) + "|" + (.stale[1].workspace)')"
check "tab title has leading status glyphs stripped" "babysit-mr code review" "$(printf '%s' "$out" | jq -r '.waiting[0].title')"
check "generic tab title falls back to the last prompt" "create an mr to staging no preview" "$(printf '%s' "$out" | jq -r '.waiting[1].title')"
check "age in seconds" "600" "$(printf '%s' "$out" | jq -r '.waiting[0].age')"
check "memory sums the agent's whole process tree" "1500" "$(printf '%s' "$out" | jq -r '.waiting[0].rss_kb')"
check "memory is 0 for an agent whose process is gone" "0" "$(printf '%s' "$out" | jq -r '.stale[0].rss_kb')"
check "stale memory total" "2150" "$(printf '%s' "$out" | jq -r '.stale_rss_kb')"

# `next` cycles through a bucket and asks cmux to select the workspace, then focus the tab.
cat > "$work/fake-cmux" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$work/cmux.log"
EOF
chmod +x "$work/fake-cmux"
export CMUX_AGENTS_CMUX="$work/fake-cmux"

"$agents" next waiting >/dev/null
check "next waiting jumps to the oldest waiting agent" "select-workspace --workspace A|focus-panel --panel S1 --workspace A" "$(paste -sd '|' "$work/cmux.log")"
: > "$work/cmux.log"; "$agents" next waiting >/dev/null
check "second next moves to the following agent" "focus-panel --panel S8 --workspace A" "$(tail -1 "$work/cmux.log")"
: > "$work/cmux.log"; "$agents" next waiting >/dev/null
check "next wraps around" "focus-panel --panel S1 --workspace A" "$(tail -1 "$work/cmux.log")"
: > "$work/cmux.log"; "$agents" next done >/dev/null
check "buckets keep separate cursors" "focus-panel --panel S9 --workspace A" "$(tail -1 "$work/cmux.log")"

printf '{"sessions": []}' > "$work/empty.json"
: > "$work/cmux.log"
CMUX_AGENTS_SESSIONS_JSON="$work/empty.json" "$agents" next waiting >/dev/null
check "an empty bucket notifies instead of jumping" "notify --title No agents waiting" "$(tail -1 "$work/cmux.log")"

"$agents" next bogus >/dev/null 2>&1
check "an unknown bucket is rejected" "2" "$?"

[ "$failures" -eq 0 ] && printf '\nall passed\n' || { printf '\n%s failed\n' "$failures"; exit 1; }
