#!/usr/bin/env bash
set -euo pipefail

config_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_config="$config_dir/config.ini"
target_config="/etc/ly/config.ini"

if [[ ! -f "$source_config" ]]; then
  printf 'Missing source config: %s\n' "$source_config" >&2
  exit 1
fi

if [[ -f "$target_config" ]]; then
  backup_path="${target_config}.bak.$(date +%Y%m%d-%H%M%S)"
  sudo cp -a "$target_config" "$backup_path"
  printf 'Backed up %s to %s\n' "$target_config" "$backup_path"
fi

sudo install -Dm644 "$source_config" "$target_config"
printf 'Installed %s to %s\n' "$source_config" "$target_config"
printf 'Restart ly or reboot for changes to take effect.\n'
