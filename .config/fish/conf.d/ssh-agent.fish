set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"

if status is-interactive; and test -S "$SSH_AUTH_SOCK"; and test -x "$HOME/.ssh/scripts/start_ssh_agent"
    ssh-add -l >/dev/null 2>&1
    or "$HOME/.ssh/scripts/start_ssh_agent" >/dev/null 2>&1
end
