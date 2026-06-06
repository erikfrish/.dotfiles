#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
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

PS1='[\u@\h \W]\$ '
export LIBVIRT_DEFAULT_URI="qemu:///system"
export IDF_PATH=~/esp/esp-idf
___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
