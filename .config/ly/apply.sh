#!/usr/bin/env bash
set -euo pipefail

config_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
theme_file="$config_dir/theme.ini"

merged_config() {
  local src="$1" theme="$2" dest="$3"

  if [[ ! -f "$theme" ]]; then
    cp "$src" "$dest"
    return
  fi

  awk '
    FNR == NR {
      if ($0 ~ /^[[:space:]]*#/ || $0 !~ /=/) next
      key = $1
      values[key] = $0
      next
    }
    {
      key = $1
      if (key in values) {
        print values[key]
        delete values[key]
      } else {
        print
      }
    }
    END {
      for (key in values) print values[key]
    }
  ' "$theme" "$src" > "$dest"
}

deploy() {
  local src="$1" dest="$2"
  if [[ ! -f "$src" ]]; then
    printf 'Missing source: %s\n' "$src" >&2
    exit 1
  fi
  if [[ -f "$dest" ]]; then
    local backup="${dest}.bak.$(date +%Y%m%d-%H%M%S)"
    sudo cp -a "$dest" "$backup"
    printf 'Backed up %s to %s\n' "$dest" "$backup"
  fi
  sudo install -Dm644 "$src" "$dest"
  printf 'Installed %s to %s\n' "$src" "$dest"
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
merged_config "$config_dir/config.ini" "$theme_file" "$tmp"
deploy "$tmp" "/etc/ly/config.ini"

printf 'Restart ly or reboot for changes to take effect.\n'
