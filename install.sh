#!/usr/bin/env bash
# Symlink these dotfiles into $HOME. Safe to re-run.
#
#   ./install.sh            link everything
#   ./install.sh --dry-run  show what would happen, change nothing
#
# Anything already at a destination that isn't the right symlink is moved to
# ~/.dotfiles-backup/<timestamp>/ first - never deleted.
#
# This only links files and fetches tmux's plugin manager. It does not install
# packages, Oh My Zsh, fonts, or Neovim plugins (nvim does that itself on its
# first launch).
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
DRY=0

case "${1:-}" in
    "") ;;
    -n | --dry-run) DRY=1 ;;
    -h | --help)
        sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    *)
        echo "unknown option: $1 (try --help)" >&2
        exit 2
        ;;
esac

# "path in this repo:path relative to $HOME". Add a line here for new tools.
LINKS=(
    "nvim:.config/nvim"
    "tmux:.config/tmux"
    "ghostty:.config/ghostty"
    "helix:.config/helix"
    "zsh/.zshrc:.zshrc"
    "zsh/.zshenv:.zshenv"
    "zsh/.zprofile:.zprofile"
    "git/.gitconfig:.gitconfig"
    "clang-format/.clang-format:.clang-format"
    "clang-tidy/.clang-tidy:.clang-tidy"
)

# Runs a command unless this is a dry run.
run() {
    if [ "$DRY" = 0 ]; then
        "$@"
    fi
}

link() {
    local src="$DOTFILES/$1" dest="$HOME/$2"

    if [ ! -e "$src" ]; then
        echo "skip    $2 (no $1 in the repo)"
        return
    fi

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        echo "ok      $2"
        return
    fi

    if [ -L "$dest" ]; then
        echo "relink  $2 (was -> $(readlink "$dest"))"
        run rm "$dest"
    elif [ -e "$dest" ]; then
        echo "backup  $2 -> $BACKUP/$2"
        run mkdir -p "$(dirname "$BACKUP/$2")"
        run mv "$dest" "$BACKUP/$2"
    fi

    run mkdir -p "$(dirname "$dest")"
    run ln -s "$src" "$dest"
    echo "link    $2 -> $src"
}

if [ "$DRY" = 1 ]; then
    echo "DRY RUN: nothing is changed, lines below show what would happen."
fi
echo "dotfiles: $DOTFILES"
echo

for entry in "${LINKS[@]}"; do
    link "${entry%%:*}" "${entry#*:}"
done

# Ghostty has no per-OS config. ghostty/config includes an optional,
# gitignored local.conf; point it at this OS's file (ghostty/linux.conf on
# Linux), if there is one. Goes through ~/.config/ghostty, linked above.
os_conf="ghostty/$(uname -s | tr '[:upper:]' '[:lower:]').conf"
if [ -e "$DOTFILES/$os_conf" ]; then
    link "$os_conf" ".config/ghostty/local.conf"
fi

# tmux.conf runs ~/.config/tmux/plugins/tpm/tpm, which resolves to this path
# once ~/.config/tmux is linked. tmux/plugins/ is gitignored, so TPM itself
# isn't in the repo and has to be fetched on every new machine.
tpm_dir="$DOTFILES/tmux/plugins/tpm"
tpm_cloned=0
echo
if [ -d "$tpm_dir" ]; then
    echo "ok      tmux plugin manager (tpm)"
elif command -v git > /dev/null 2>&1; then
    echo "clone   tpm -> $tpm_dir"
    if run git clone --quiet --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"; then
        tpm_cloned=1
    else
        echo "warn    couldn't clone tpm (offline?) - rerun this script later" >&2
    fi
else
    echo "skip    tpm (git isn't installed)"
fi

echo
echo "done."
if [ "$tpm_cloned" = 1 ] && [ "$DRY" = 0 ]; then
    echo "- tmux: start it and press prefix + I (Ctrl-b, then Shift-i) to install its plugins."
fi
echo "- nvim: open it once; it installs its plugins, parsers and language servers itself."
