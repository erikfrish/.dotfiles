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

dotfiles_vpn_state_file() {
  printf '%s/waybar/%s-connection\n' "${XDG_STATE_HOME:-$HOME/.local/state}" "$1"
}

dotfiles_vpn_connection() {
  local slot="$1" connection state_file

  case "$slot" in
    vpn1) connection="${DOTFILES_VPN1_CONNECTION-vpnchik}" ;;
    vpn2) connection="${DOTFILES_VPN2_CONNECTION-wb}" ;;
    *) return 1 ;;
  esac

  state_file="$(dotfiles_vpn_state_file "$slot")"
  if [[ -n "$connection" && -r "$state_file" ]]; then
    connection="$(<"$state_file")"
  fi

  printf '%s\n' "$connection"
}
