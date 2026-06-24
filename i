#!/usr/bin/env bash
# Zero-state bootstrap for a fresh CachyOS / Arch login.
#
# Run this *before* you've cloned the repo. It installs git + stow, clones the
# dotfiles into ~/dotfiles (or pulls if it's already there), then hands off to
# install.sh.
#
# Named "i" rather than "bootstrap.sh" so it's painless to type on a Danish
# keyboard while the system keymap is still US (fresh CachyOS install pain).
#
# Usage:
#   curl -LO github.com/iliorn/dotfiles/raw/main/i
#   sh i
#
# Any flags passed to "sh i" are forwarded to install.sh, e.g.:
#   sh i --dry-run

set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/iliorn/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mXX \033[0m %s\n' "$*" >&2; exit 1; }

# Sanity checks ----------------------------------------------------------------
if [[ "$EUID" -eq 0 ]]; then
    die "Run as your normal user, not root (sudo is invoked where needed)."
fi
if ! command -v pacman >/dev/null 2>&1; then
    die "This script targets CachyOS / Arch (pacman not found)."
fi
if ! ping -c1 -W2 archlinux.org >/dev/null 2>&1; then
    die "No internet — connect to WiFi first (e.g. iwctl) and retry."
fi

# Install the minimum to clone the repo ----------------------------------------
log "Installing prerequisites: git, stow"
sudo pacman -S --needed --noconfirm git stow

# Clone or update --------------------------------------------------------------
if [[ -d "$DOTFILES_DIR/.git" ]]; then
    log "Updating existing $DOTFILES_DIR"
    git -C "$DOTFILES_DIR" pull --ff-only
else
    log "Cloning $REPO_URL → $DOTFILES_DIR"
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi

# Hand off ---------------------------------------------------------------------
log "Handing off to install.sh"
cd "$DOTFILES_DIR"
exec ./install.sh "$@"
