# my configs

- `notes/yubikey_pool.md` - динамический пул аппаратных SSH/YubiKey ключей для git signing и SSH-доступа.
- `notes/thinkpad_setup_process.md` - актуальные заметки по Hyprland, Waybar и универсальной audio-схеме.

## Install

```sh
cd ~/.dotfiles
stow .
```

Machine-specific файлы не хранятся в git:

```text
~/.gitconfig.local
~/.ssh/config.local
~/.ssh/yubikeys.tsv
```

На машине с уже существующими `~/.gitconfig` или `~/.ssh/config` сначала перенеси их в local overrides:

```sh
mv ~/.gitconfig ~/.gitconfig.local
mv ~/.ssh/config ~/.ssh/config.local
cd ~/.dotfiles
stow .
```

## Audio

Управление громкостью универсальное для `laptopchik` и `compik`, не зависит от EasyEffects:

```sh
~/.config/desktop/scripts/volume --get
~/.config/desktop/scripts/volume --inc
~/.config/desktop/scripts/volume --dec
~/.config/desktop/scripts/volume --toggle
```

Основной backend: `wpctl`; fallback: `pactl`.
