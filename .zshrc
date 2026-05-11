# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="fishy" # set by `omz`
ZSH_THEME="risto" # set by `omz`
# ZSH_THEME=random

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" "fishy" "lukerandall" "mlh" "intheloops")
# ZSH_THEME_RANDOM_CANDIDATES=( "risto" "fishy" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Command auto-correction is intentionally disabled.

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

plugins=(vscode git golang history sudo)
# plugins=(macos brew iterm2 chucknorris)


alias zshconfig="nvim ~/.zshrc"
alias vi="nvim"
alias path='echo "${PATH//:/$"\n"}"'
alias ttl='sudo sysctl -w net.inet.ip.ttl=65'
alias docker_clean_images='docker rmi $(docker images -a --filter=dangling=true -q)'
alias docker_clean_ps='docker rm $(docker ps --filter=status=exited --filter=status=created -q)'
alias dcoker_clean_cashe='docker system prune -a'
alias get_idf='. $HOME/esp/esp-idf/export.sh'
alias wake_homelab='wakeonlan -i 192.168.1.255 c8:ff:bf:04:e7:64'
alias ls='eza'
alias files='yazi'
# alias cat='bat'
alias goupdate='curl -sL https://raw.githubusercontent.com/DieTime/go-up/master/go-up.sh | bash'
alias oc='opencode'
alias tsh='tsh-17'

ENABLE_CORRECTION="false"
source /usr/share/cachyos-zsh-config/cachyos-config.zsh
unsetopt correct correct_all 2>/dev/null
unset ENABLE_CORRECTION
source /opt/esp-idf/export.sh > /dev/null 2>&1

# User configuration
# source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
# source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zstyle :omz:plugins:iterm2 shell-integration yes
# export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"
# export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

export GOPATH="$HOME/go"
export PATH="$GOPATH/bin/:$PATH"
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:/home/erikfrish/.cargo/bin"
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export LIBVIRT_DEFAULT_URI="qemu:///system"
export IDF_PATH=~/esp/esp-idf
___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi

if [ -f "$HOME/.config/opencode/.env" ]; then
  set -a
  . "$HOME/.config/opencode/.env"
  set +a
fi
