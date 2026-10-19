#!/usr/bin/env bash
# Zero-state bootstrap for a fresh CachyOS / Arch login.
#
# It does the part that has to happen before anything else can: installs the
# handful of packages Ansible needs in order to reach this machine at all, and
# clones this repo. Ansible owns everything after that — the packages, the
# stow run, the keymap, the network, the services, the login shell. Pushing
# from hoth is the normal route; the Ansible repo's ONBOARDING.md has both it
# and the ansible-pull fallback for when hoth cannot be reached.
#
# Named "i" rather than "bootstrap.sh" so it's painless to type on a Danish
# keyboard while the system keymap is still US (fresh CachyOS install pain).
#
# Usage:
#   curl -LO github.com/iliorn/dotfiles/raw/main/i
#   sh i

set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/iliorn/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()  { printf '\033[1;32m ✓ \033[0m %s\n' "$*"; }
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

# Prerequisites ----------------------------------------------------------------
#
# git and stow to clone and link this repo, python because that is what Ansible
# runs on the far end of an SSH connection, tailscale because Ansible reaches
# the laptops over Tailscale SSH and nothing else. ansible-core is for the pull
# path only; it costs little and the machine that needs it is the one that
# cannot reach hoth to ask for it.
log "Installing prerequisites: git, stow, python, tailscale, ansible-core"
sudo pacman -S --needed --noconfirm git stow python tailscale ansible-core

# Clone or update --------------------------------------------------------------
if [[ -d "$DOTFILES_DIR/.git" ]]; then
    log "Updating existing $DOTFILES_DIR"
    git -C "$DOTFILES_DIR" pull --ff-only
else
    log "Cloning $REPO_URL → $DOTFILES_DIR"
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi

# The hook is this repo's own guardrail (syntax checks, no absolute /home
# paths, no machine state). Ansible's roles/shell sets this too, but the first
# commit made on a fresh machine may well happen before Ansible has run.
git -C "$DOTFILES_DIR" config core.hooksPath .githooks
ok "pre-commit hook active"

# Hand off ---------------------------------------------------------------------
cat <<'NEXT'

 ✓  Bootstrap done. Ansible takes it from here — three things it cannot do for
    you, because they need this machine's own keyboard and a browser:

    1. Give the machine ONE name, used as hostname, Tailscale name and
       inventory key:

           sudo hostnamectl set-hostname <name>
           # then fix the 127.0.1.1 line in /etc/hosts

    2. Join the tailnet and approve the login in the browser:

           sudo systemctl enable --now tailscaled
           sudo tailscale up --ssh

    3. On hoth, add the one line for <name> under `laptops:` in
       inventory.yml, then walk ONBOARDING.md from step 3:

           ansible <name> -m ping
           ansible-playbook site.yml --limit <name> --check --diff -K

    If hoth cannot be reached, ONBOARDING.md's "pull path" section runs the
    same playbook from this machine instead.

NEXT
