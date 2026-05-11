export PATH="$HOME/.local/bin:$PATH"

___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Auto-add YubiKey SSH keys to agent on login (same logic as fish conf.d/ssh-agent.fish).
if [ -S "$SSH_AUTH_SOCK" ] && [ -x "$HOME/.ssh/scripts/start_ssh_agent" ]; then
    ssh-add -l >/dev/null 2>&1 || "$HOME/.ssh/scripts/start_ssh_agent" >/dev/null 2>&1
fi
