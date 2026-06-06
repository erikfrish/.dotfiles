fish_add_path --path "$HOME/.local/bin"

alias luks-fido-open='luks-fido open'
alias luks-fido-mount='luks-fido open'
alias luks-fido-umount='luks-fido close'
alias luks-fido-unmount='luks-fido close'
alias luks-fido-close='luks-fido close'
alias luks-fido-status='luks-fido status'

set -gx EXTSSD_ID 'ffe33d05-bbf8-40ab-a24b-d7737c4dfe07'
set -gx EXTSSD_NAME 'extssd'
set -gx EXTSSD_MOUNTPOINT '/mnt/extssd'
alias extssd-open='luks-fido open --id "$EXTSSD_ID" --name "$EXTSSD_NAME" --mountpoint "$EXTSSD_MOUNTPOINT"'
alias extssd-mount='luks-fido open --id "$EXTSSD_ID" --name "$EXTSSD_NAME" --mountpoint "$EXTSSD_MOUNTPOINT"'
alias extssd-umount='luks-fido close --id "$EXTSSD_ID" --name "$EXTSSD_NAME" --mountpoint "$EXTSSD_MOUNTPOINT"'
alias extssd-unmount='luks-fido close --id "$EXTSSD_ID" --name "$EXTSSD_NAME" --mountpoint "$EXTSSD_MOUNTPOINT"'
alias extssd-close='luks-fido close --id "$EXTSSD_ID" --name "$EXTSSD_NAME" --mountpoint "$EXTSSD_MOUNTPOINT"'
alias extssd-status='luks-fido status --id "$EXTSSD_ID" --name "$EXTSSD_NAME" --mountpoint "$EXTSSD_MOUNTPOINT"'
