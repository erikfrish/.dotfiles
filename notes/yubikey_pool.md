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

- `.gitconfig` - общие git-настройки: SSH signing, `core.sshCommand`, include локальных overrides.
- `.ssh/config` - общие SSH-настройки: YubiKey identity files, multiplexing, GitHub host policy, include локальных overrides.
- `.gitconfig.local.example` - пример локального git override.
- `.ssh/config.local.example` - пример локального SSH override.
- `.ssh/yubikeys.tsv` - пул известных аппаратных ключей: `serial`, `name`, `identity_file`, `public_key_file`.
- `.ssh/scripts/current_yubikey` - динамически выбирает подключенный ключ из пула.
- `.ssh/scripts/start_ssh_agent` - добавляет ключи из пула в активный SSH-agent.
- `.ssh/scripts/git_ssh` - git-only SSH wrapper; выбирает только активный YubiKey и не подмешивает весь пул `IdentityFile`.
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

Скрипт по умолчанию сначала пытается восстановить уже существующий resident key через `ssh-keygen -K`. Если подходящий ключ не найден, он создает новый resident key:

```sh
ssh-keygen -t ed25519-sk \
  -C "ssh:$(whoami)@<key-name>" \
  -f "$HOME/.ssh/id_ed25519_sk_rk_$(whoami)@<key-name>" \
  -O resident \
  -O "application=ssh:$(whoami)@<key-name>"
```

Если ключ уже создан или восстановлен через `ssh-keygen -K`, его можно только зарегистрировать:

```sh
yubikey-pool-add --skip-generate --serial 12345678 --identity '~/.ssh/id_ed25519_sk_rk_${USER}@yubik_5c_nfc' yubik_5c_nfc
```

Если нужно строго восстановить существующий resident key и не создавать новый:

```sh
yubikey-pool-add --extract-only --serial 12345678 yubik_5c_nfc
```

Имя можно не указывать, если resident key был создан по dotfiles-схеме с comment/application вида `ssh:$USER@$SSH_KEY_NAME`; скрипт восстановит файл с исходным basename и возьмет имя из comment/application:

```sh
yubikey-pool-add --extract-only --serial 12345678
```

Для PIN перед использованием ключа:

```sh
yubikey-pool-add --verify-required yubik_5c_nfc
```

## Как это связано с git и SSH

Setup и stow-managed `.gitconfig` выставляют общие git-настройки:

```ini
[commit]
  gpgsign = true
[gpg]
  format = ssh
[gpg "ssh"]
  sshProgram = ssh
  defaultKeyCommand = ~/.ssh/scripts/current_yubikey
[core]
  sshCommand = ~/.ssh/scripts/git_ssh
```

Wrapper нужен для IDE/Git: обычный SSH config содержит весь пул `IdentityFile`, поэтому OpenSSH может шуметь `device not found` для не вставленных SK-ключей. `git_ssh` берёт `current_yubikey --identity` и запускает gitlab/github только с одним активным ключом.

SSH получает список ключей через include-файл:

```sshconfig
Include ~/.ssh/config.local
Include ~/.ssh/wb/config
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
