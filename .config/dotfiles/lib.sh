#!/usr/bin/env bash

dotfiles_load_machine_config() {
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  local config_file="$config_home/dotfiles/machine.conf"

  if [ -f "$config_file" ]; then
    # shellcheck disable=SC1090
    . "$config_file"
  fi
}

dotfiles_runtime_dir() {
  printf '%s\n' "${XDG_RUNTIME_DIR:-/tmp}"
}

dotfiles_wob_fifo() {
  printf '%s/niri.wob\n' "$(dotfiles_runtime_dir)"
}
