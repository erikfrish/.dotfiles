# Enable Powerlevel10k instant prompt. Keep this near the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="risto" # set by `omz`
plugins=(vscode git golang history sudo)

# Aliases
alias zshconfig="nvim ~/.zshrc"
alias vi="nvim"
alias path='echo "${PATH//:/$"\n"}"'
alias ttl='sudo sysctl -w net.inet.ip.ttl=65'

alias docker_clean_images='docker rmi $(docker images -a --filter=dangling=true -q)'
alias docker_clean_ps='docker rm $(docker ps --filter=status=exited --filter=status=created -q)'
alias dcoker_clean_cashe='docker system prune -a'
alias docker_clean_cache='docker system prune -a'

alias get_idf='. $HOME/esp/esp-idf/export.sh'
alias wake_homelab='wakeonlan -i 192.168.1.255 c8:ff:bf:04:e7:64'

alias ls='eza'
alias files='yazi'
alias goupdate='curl -sL https://raw.githubusercontent.com/DieTime/go-up/master/go-up.sh | bash'
alias oc='opencode'
alias tsh='tsh-17'
alias luks-fido-open='luks-fido open'
alias luks-fido-mount='luks-fido open'
alias luks-fido-umount='luks-fido close'
alias luks-fido-unmount='luks-fido close'
alias luks-fido-close='luks-fido close'
alias luks-fido-status='luks-fido status'

export EXTSSD_ID='ffe33d05-bbf8-40ab-a24b-d7737c4dfe07'
export EXTSSD_NAME='extssd'
export EXTSSD_MOUNTPOINT='/mnt/extssd'
alias extssd-open='luks-fido open --id "$EXTSSD_ID" --name "$EXTSSD_NAME" --mountpoint "$EXTSSD_MOUNTPOINT"'
alias extssd-mount='luks-fido open --id "$EXTSSD_ID" --name "$EXTSSD_NAME" --mountpoint "$EXTSSD_MOUNTPOINT"'
alias extssd-umount='luks-fido close --id "$EXTSSD_ID" --name "$EXTSSD_NAME" --mountpoint "$EXTSSD_MOUNTPOINT"'
alias extssd-unmount='luks-fido close --id "$EXTSSD_ID" --name "$EXTSSD_NAME" --mountpoint "$EXTSSD_MOUNTPOINT"'
alias extssd-close='luks-fido close --id "$EXTSSD_ID" --name "$EXTSSD_NAME" --mountpoint "$EXTSSD_MOUNTPOINT"'
alias extssd-status='luks-fido status --id "$EXTSSD_ID" --name "$EXTSSD_NAME" --mountpoint "$EXTSSD_MOUNTPOINT"'

# Shell integrations
ENABLE_CORRECTION="false"
[ -r /usr/share/cachyos-zsh-config/cachyos-config.zsh ] && source /usr/share/cachyos-zsh-config/cachyos-config.zsh
unsetopt correct correct_all 2>/dev/null
unset ENABLE_CORRECTION

[ -r /opt/esp-idf/export.sh ] && source /opt/esp-idf/export.sh > /dev/null 2>&1

# Environment
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin/:$PATH"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.cargo/bin"

# Prompt
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export LIBVIRT_DEFAULT_URI="qemu:///system"
export IDF_PATH=~/esp/esp-idf

___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"
if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then
  . "${___MY_VMOPTIONS_SHELL_FILE}"
fi

if [ -f "$HOME/.config/opencode/.env" ]; then
  set -a
  . "$HOME/.config/opencode/.env"
  set +a
fi

# Local overrides
[ -r "$HOME/.config/shell/theme.sh" ] && source "$HOME/.config/shell/theme.sh"
[ -r "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
