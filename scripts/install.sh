#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
home_dir="${HOME:?HOME must be set}"
timestamp="$(date +%Y%m%d-%H%M%S)"

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf '%s\n' 'This setup currently targets macOS.' >&2
  exit 1
fi

cmux_bin="$(command -v cmux 2>/dev/null || true)"
if [[ -z "$cmux_bin" ]]; then
  printf '%s\n' 'cmux was not found on PATH. Install cmux and retry.' >&2
  exit 1
fi

backup_file() {
  local source="$1"
  if [[ -e "$source" ]]; then
    cp -p "$source" "${source}.bak-${timestamp}"
  fi
}

mkdir -p "$home_dir/.config/cmux" "$home_dir/.config/ghostty" \
  "$home_dir/.cmux/hooks" "$home_dir/.local/bin" "$home_dir/Library/LaunchAgents" \
  "$home_dir/Library/Sounds"

backup_file "$home_dir/.config/cmux/cmux.json"
backup_file "$home_dir/.config/ghostty/config"
backup_file "$home_dir/.local/bin/cmux-sidebar-dashboard"

sed "s|__HOME__|$home_dir|g" "$repo_root/config/cmux.json" > "$home_dir/.config/cmux/cmux.json"
cp "$repo_root/config/ghostty.config" "$home_dir/.config/ghostty/config"
cp "$repo_root/hooks/"*.sh "$home_dir/.cmux/hooks/"
cp "$repo_root/scripts/cmux-sidebar-dashboard" "$home_dir/.local/bin/cmux-sidebar-dashboard"
cp "$repo_root/assets/sounds/"*.wav "$home_dir/Library/Sounds/"
chmod +x "$home_dir/.local/bin/cmux-sidebar-dashboard" "$home_dir/.cmux/hooks/"*.sh

sed "s|__HOME__|$home_dir|g; s|__UID__|$(id -u)|g" \
  "$repo_root/launchd/com.eneskirli.cmux-sidebar-dashboard.plist.template" \
  > "$home_dir/Library/LaunchAgents/com.eneskirli.cmux-sidebar-dashboard.plist"

launchctl bootout "gui/$(id -u)/com.eneskirli.cmux-sidebar-dashboard" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$home_dir/Library/LaunchAgents/com.eneskirli.cmux-sidebar-dashboard.plist"
cmux reload-config

printf 'Installed cmux setup from %s\n' "$repo_root"
printf 'Backups use timestamp %s\n' "$timestamp"
