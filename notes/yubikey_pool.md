# YubiKey pool for SSH and git signing

## Что уже было настроено

Старая схема работала так:

- `~/.gitconfig` включает SSH-подпись коммитов: `commit.gpgsign = true`, `gpg.format = ssh`.
- Git не хранит фиксированный `user.signingKey`, а вызывает `gpg.ssh.defaultKeyCommand = ~/.ssh/scripts/current_yubikey`.
- `current_yubikey` смотрит `ykman list -s`, находит подключенный YubiKey по serial number и печатает `key::<public key>` для git.
- `~/.ssh/config` перечисляет оба аппаратных `IdentityFile`, поэтому SSH может использовать вставленный ключ.
- Активный SSH-agent socket лежит в env: `SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket`. Это продублировано в `.zprofile` и `.config/environment.d/profile.conf`.

Новая версия в dotfiles убирает хардкод serial number из скрипта. Доступные ключи лежат в пуле `~/.ssh/yubikeys.tsv`.

## Файлы

- `.ssh/yubikeys.tsv` - пул известных аппаратных ключей: `serial`, `name`, `identity_file`, `public_key_file`.
- `.ssh/scripts/current_yubikey` - динамически выбирает подключенный ключ из пула.
- `.ssh/scripts/start_ssh_agent` - добавляет ключи из пула в активный SSH-agent.
- `.local/bin/yubikey-pool-setup` - настраивает git, SSH include, env и user service для `ssh-agent`.
- `.local/bin/yubikey-pool-add` - создает или регистрирует новый resident hardware key и добавляет его в пул.
- `.config/systemd/user/ssh-agent.service` - user service с socket path `%t/ssh-agent.socket`.

## Установка на новой машине

```sh
cd ~/.dotfiles
stow .
yubikey-pool-setup
```

Если на машине уже есть обычные `~/.gitconfig` или `~/.ssh/config`, сначала сохранить их как локальные overrides:

```sh
mv ~/.gitconfig ~/.gitconfig.local
mv ~/.ssh/config ~/.ssh/config.local
cd ~/.dotfiles
stow .
```

Общие настройки лежат в stow-managed `~/.gitconfig` и `~/.ssh/config`. Локальные отличия машины лежат вне git:

```text
~/.gitconfig.local
~/.ssh/config.local
```

Если не нужно трогать systemd user service:

```sh
yubikey-pool-setup --no-systemd
```

Проверка ключа для подписи git:

```sh
current_yubikey --git
git config --global --get gpg.ssh.defaultKeyCommand
```

Проверка env с активным ключом:

```sh
current_yubikey --env
eval "$(current_yubikey --env)"
printf '%s\n' "$ACTIVE_HARDWARE_KEY_NAME"
```

## Добавление нового ключа

Вставить один YubiKey и выполнить:

```sh
yubikey-pool-add yubik_5c_nfc
```

Если вставлено несколько ключей, serial нужно указать явно:

```sh
yubikey-pool-add --serial 12345678 yubik_5c_nfc
```

Скрипт по умолчанию создает resident key:

```sh
ssh-keygen -t ed25519-sk \
  -C "ssh:$(whoami)@<key-name>" \
  -f "$HOME/.ssh/id_ed25519_sk_rk_$(whoami)@<key-name>" \
  -O resident \
  -O "application=ssh:$(whoami)@<key-name>"
```

Если ключ уже создан или восстановлен через `ssh-keygen -K`, его можно только зарегистрировать:

```sh
yubikey-pool-add --skip-generate --serial 12345678 --identity ~/.ssh/id_ed25519_sk_rk_erikfrish@yubik_5c_nfc yubik_5c_nfc
```

Для PIN перед использованием ключа:

```sh
yubikey-pool-add --verify-required yubik_5c_nfc
```

## Как это связано с git и SSH

Setup выставляет глобальные git-настройки:

```ini
[commit]
  gpgsign = true
[gpg]
  format = ssh
[gpg "ssh"]
  sshProgram = ssh
  defaultKeyCommand = ~/.ssh/scripts/current_yubikey
[core]
  sshCommand = env -u GIT_ASKPASS -u SSH_AUTH_SOCK SSH_ASKPASS=/bin/true SSH_ASKPASS_REQUIRE=never ssh -o StrictHostKeyChecking=yes -o UpdateHostKeys=no -o ControlMaster=auto -o ControlPath=~/.ssh/ssh-conn-%C -o ControlPersist=4h
```

SSH получает список ключей через include-файл:

```sshconfig
Include ~/.ssh/config.d/yubikey-pool.conf
```

`~/.ssh/config.d/yubikey-pool.conf` генерируется из `~/.ssh/yubikeys.tsv` и содержит `IdentityFile` для каждого ключа из пула.

SSH multiplexing включен для переиспользования уже открытой сессии:

```sshconfig
ControlMaster auto
ControlPath ~/.ssh/ssh-conn-%C
ControlPersist 4h
```

Для GitHub persist длиннее, для остальных хостов короче. Это снижает количество повторных YubiKey touch/password prompts.
