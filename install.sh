#!/usr/bin/env bash
# Idempotent end-to-end bootstrap for this dotfiles repo on CachyOS / Arch.
#
# Designed so that on a brand-new install you can:
#   1. Log in (any DE, even bare TTY)
#   2. Open a terminal
#   3. Run this script
# and end up with the full Hyprland environment, Danish keyboard everywhere,
# fish as login shell, services enabled, and stow applied.
#
# Usage:
#   ./install.sh                 # full bootstrap
#   ./install.sh --no-packages   # skip pacman/paru, only apply configs
#   ./install.sh --dry-run       # print what would happen, do nothing
#   ./install.sh --skip <name>   # skip a named step (repeatable). Step names:
#                                #   keymap packages paru aur stow host iwd
#                                #   mtui taskr gsettings sysd-user sysd-system
#                                #   shell hooks
#
# Safe to re-run: pacman uses --needed, stow is restow, systemctl enable is
# idempotent, /etc/vconsole.conf is only written if missing or wrong, and
# host.conf is never overwritten once it exists.

set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
SKIP_PACKAGES=0
declare -A SKIP=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)     DRY_RUN=1; shift ;;
        --no-packages) SKIP_PACKAGES=1; shift ;;
        --skip)        SKIP["$2"]=1; shift 2 ;;
        -h|--help)
            sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "unknown flag: $1" >&2; exit 2 ;;
    esac
done

skipped() { [[ -n "${SKIP[$1]:-}" ]]; }

#--- logging -------------------------------------------------------------------
log()    { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()     { printf '\033[1;32m ✓ \033[0m %s\n' "$*"; }
warn()   { printf '\033[1;33m !!\033[0m %s\n' "$*" >&2; }
fatal()  { printf '\033[1;31mXX \033[0m %s\n' "$*" >&2; exit 1; }
run()    {
    if [[ $DRY_RUN -eq 1 ]]; then
        printf '   [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

#--- sudo keepalive ------------------------------------------------------------
# Ask for the sudo password once and keep the timestamp fresh in the background
# so individual sudo calls below never re-prompt mid-script.
keepalive_sudo() {
    [[ $DRY_RUN -eq 1 ]] && return
    sudo -v || fatal "sudo failed; aborting"
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

#--- pacman packages -----------------------------------------------------------
PACMAN_PACKAGES=(
    # Core Hyprland stack
    hyprland xdg-desktop-portal-hyprland hyprlock hypridle
    # Login manager
    ly
    # Terminal / shell / CLI ergonomics
    alacritty zellij fish fzf zoxide ripgrep fd bat eza atuin starship direnv lazygit
    # Editor + file manager
    helix yazi zathura zathura-pdf-mupdf codebook-lsp
    # Email
    aerc w3m libsecret gnome-keyring
    # Launcher / bar / notifications
    rofi-wayland waybar dunst
    # Wallpaper
    awww waypaper
    # Screenshots + clipboard
    grim slurp wl-clipboard
    # Audio
    pipewire pipewire-pulse wireplumber
    # Brightness, bluetooth, wifi
    brightnessctl blueman bluetui iwd
    # Cloud sync
    rclone
    # System utilities + misc
    ananicy-cpp ufw avahi snapper ttf-jetbrains-mono-nerd btop fastfetch micro 7zip
    # Music + Node (for Claude Code npm install)
    spotify-launcher nodejs npm
    # GitHub CLI (used to fetch taskr) + base-devel (used to build paru if missing)
    github-cli base-devel
    # Stow + git for everything else
    stow git
)

AUR_PACKAGES=(
    beautyline
    mods
    zen-browser-bin
)

install_packages() {
    if skipped packages || [[ $SKIP_PACKAGES -eq 1 ]]; then
        log "Skipping pacman packages"
        return
    fi
    log "Refreshing package databases"
    run sudo pacman -Syu --needed --noconfirm || warn "pacman -Syu had issues; continuing"
    log "Installing ${#PACMAN_PACKAGES[@]} pacman packages (--needed)"
    # Install in one go; on failure fall back to package-by-package so one bad
    # name doesn't kill the rest.
    if ! run sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"; then
        warn "bulk install failed — retrying package-by-package"
        for pkg in "${PACMAN_PACKAGES[@]}"; do
            run sudo pacman -S --needed --noconfirm "$pkg" \
                || warn "  skipped: $pkg"
        done
    fi
}

#--- paru bootstrap ------------------------------------------------------------
install_paru() {
    if skipped paru; then log "Skipping paru bootstrap"; return; fi
    if command -v paru >/dev/null 2>&1; then
        ok "paru already installed"
        return
    fi
    log "Bootstrapping paru from AUR (one-time build)"
    local tmp
    tmp=$(mktemp -d)
    run git clone --depth=1 https://aur.archlinux.org/paru.git "$tmp/paru" \
        || { warn "paru clone failed — AUR packages will be skipped"; return; }
    ( cd "$tmp/paru" && run makepkg -si --noconfirm ) \
        || warn "paru build failed — AUR packages will be skipped"
    rm -rf "$tmp"
}

install_aur() {
    if skipped aur; then log "Skipping AUR packages"; return; fi
    if ! command -v paru >/dev/null 2>&1; then
        warn "paru not available — skipping AUR packages: ${AUR_PACKAGES[*]}"
        return
    fi
    log "Installing AUR packages via paru"
    run paru -S --needed --noconfirm "${AUR_PACKAGES[@]}" \
        || warn "some AUR packages failed; check output above"
}

#--- keyboard / locale ---------------------------------------------------------
# /etc/vconsole.conf controls the TTY + Ly keymap. Hyprland sets its own via
# kb_layout=dk in hyprland.conf, so once you're in Hyprland this doesn't apply,
# but it fixes the "US keyboard at login screen" pain on a fresh install.
set_keyboard_layout() {
    if skipped keymap; then log "Skipping keymap"; return; fi
    local target="KEYMAP=dk"
    if [[ -f /etc/vconsole.conf ]] && grep -qx "$target" /etc/vconsole.conf; then
        ok "/etc/vconsole.conf already KEYMAP=dk"
        return
    fi
    log "Writing /etc/vconsole.conf (KEYMAP=dk) — fixes login-screen keyboard"
    run sudo install -m644 /dev/stdin /etc/vconsole.conf <<<"$target"
}

#--- stow ----------------------------------------------------------------------
STOW_PACKAGES=(
    aerc alacritty autostart btop claude codebook dunst fastfetch fish gtk
    helix hypr lazygit micro mimeapps mods obsidian systemd waybar waypaper yazi
)

apply_stow() {
    if skipped stow; then log "Skipping stow"; return; fi
    log "Applying stow packages (restow)"
    cd "$DOTFILES_DIR"
    for pkg in "${STOW_PACKAGES[@]}"; do
        if [[ ! -d "$pkg" ]]; then
            warn "stow package '$pkg' not found — skipping"
            continue
        fi
        run stow --restow --target="$HOME" "$pkg" \
            || warn "stow failed for $pkg — may have unmanaged files in target"
    done
    if [[ -d "$DOTFILES_DIR/taskwarrior" ]]; then
        run stow --restow --target="$HOME" taskwarrior || true
    fi
}

#--- host-local Hyprland -------------------------------------------------------
seed_host_conf() {
    if skipped host; then log "Skipping host.conf"; return; fi
    local host_conf="$HOME/.config/hypr/host.conf"
    local template="$DOTFILES_DIR/hypr/.config/hypr/host.example.conf"
    if [[ -f "$host_conf" ]]; then
        ok "host.conf already present"
        return
    fi
    log "Seeding $host_conf from template — edit for this machine's monitors"
    run mkdir -p "$(dirname "$host_conf")"
    run cp "$template" "$host_conf"
}

#--- system-level configs ------------------------------------------------------
install_iwd_config() {
    if skipped iwd; then log "Skipping iwd"; return; fi
    local src="$DOTFILES_DIR/iwd/main.conf"
    local dst="/etc/iwd/main.conf"
    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
        ok "iwd/main.conf already in place"
        return
    fi
    log "Installing iwd/main.conf"
    run sudo install -Dm644 "$src" "$dst"
    run sudo systemctl restart iwd 2>/dev/null || true
}

install_mtui() {
    if skipped mtui; then log "Skipping mtui"; return; fi
    local src="$DOTFILES_DIR/scripts/mtui.sh"
    local dst="$HOME/.local/bin/mtui"
    [[ -f "$src" ]] || return 0
    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
        ok "mtui already up to date"
        return
    fi
    log "Installing mtui to ~/.local/bin/mtui"
    run install -Dm755 "$src" "$dst"
}

# taskr is a private release; we can only fetch it if gh is authenticated.
install_taskr() {
    if skipped taskr; then log "Skipping taskr"; return; fi
    if ! command -v gh >/dev/null 2>&1; then
        warn "gh not installed — taskr install skipped"
        return
    fi
    if ! gh auth status >/dev/null 2>&1; then
        warn "gh not authenticated — run 'gh auth login', then re-run install.sh"
        return
    fi
    if [[ -x "$HOME/.local/bin/taskr" ]]; then
        ok "taskr already installed (run 'U' inside the TUI to self-update)"
        return
    fi
    log "Downloading taskr release via gh"
    run mkdir -p "$HOME/.local/bin"
    run gh release download --repo iliorn/taskr --pattern 'taskr' \
        --dir "$HOME/.local/bin" --clobber \
        || { warn "taskr download failed"; return; }
    run chmod +x "$HOME/.local/bin/taskr"
}

#--- Claude Code (npm global install in user prefix) --------------------------
# Installs to ~/.local/lib/node_modules with the binary symlinked at
# ~/.local/bin/claude — no sudo needed and stays out of /usr.
install_claude_code() {
    if skipped claude-code; then log "Skipping Claude Code"; return; fi
    if ! command -v npm >/dev/null 2>&1; then
        warn "npm not installed — Claude Code skipped"
        return
    fi
    if command -v claude >/dev/null 2>&1; then
        ok "Claude Code already installed ($(command -v claude))"
        return
    fi
    log "Configuring npm user prefix at ~/.local"
    run npm config set prefix "$HOME/.local"
    log "Installing @anthropic-ai/claude-code via npm"
    run npm install -g @anthropic-ai/claude-code \
        || warn "Claude Code install failed — run 'npm install -g @anthropic-ai/claude-code' manually"
}

#--- gsettings (GTK icon theme persisted via dconf) ---------------------------
apply_gsettings() {
    if skipped gsettings; then log "Skipping gsettings"; return; fi
    if ! command -v gsettings >/dev/null 2>&1; then
        warn "gsettings not installed — icon theme not set"
        return
    fi
    local current
    current=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo "")
    if [[ "$current" == "'BeautyLine'" ]]; then
        ok "GTK icon theme already BeautyLine"
        return
    fi
    log "Setting GTK icon theme to BeautyLine (dconf)"
    run gsettings set org.gnome.desktop.interface icon-theme 'BeautyLine'
}

#--- shell change --------------------------------------------------------------
set_login_shell_to_fish() {
    if skipped shell; then log "Skipping shell change"; return; fi
    if ! command -v fish >/dev/null 2>&1; then
        warn "fish not installed — cannot chsh"
        return
    fi
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [[ "$current_shell" == "/usr/bin/fish" || "$current_shell" == "$(command -v fish)" ]]; then
        ok "login shell already fish"
        return
    fi
    log "Changing login shell to /usr/bin/fish (requires password)"
    run chsh -s /usr/bin/fish "$USER" || warn "chsh failed; run manually later"
}

#--- systemd user services -----------------------------------------------------
enable_user_services() {
    if skipped sysd-user; then log "Skipping user services"; return; fi
    local services=(rclone-dropbox.service rclone-onedrive.service)
    log "Enabling systemd user services: ${services[*]}"
    run systemctl --user daemon-reload || true
    for svc in "${services[@]}"; do
        run systemctl --user enable --now "$svc" \
            || warn "  $svc failed — run 'rclone config' to set up the remote, then re-enable"
    done
}

enable_system_services() {
    if skipped sysd-system; then log "Skipping system services"; return; fi
    local services=(bluetooth iwd systemd-resolved ananicy-cpp ufw avahi-daemon)
    log "Enabling system services: ${services[*]}"
    for svc in "${services[@]}"; do
        run sudo systemctl enable --now "$svc" \
            || warn "  $svc enable failed"
    done
    run sudo systemctl enable ly@tty2 2>/dev/null \
        || warn "ly@tty2 enable failed (already enabled?)"
}

#--- git hooks -----------------------------------------------------------------
configure_git_hooks() {
    if skipped hooks; then log "Skipping git hooks"; return; fi
    local hooks_dir="$DOTFILES_DIR/.githooks"
    [[ -d "$hooks_dir" ]] || return 0
    log "Pointing git core.hooksPath at .githooks"
    run git -C "$DOTFILES_DIR" config core.hooksPath .githooks
}

#--- main ----------------------------------------------------------------------
main() {
    log "Bootstrapping dotfiles from $DOTFILES_DIR"
    if [[ $DRY_RUN -eq 0 ]] && [[ "${SKIP_PACKAGES:-0}" -eq 0 || -z "${SKIP[keymap]:-}" || -z "${SKIP[iwd]:-}" || -z "${SKIP[sysd-system]:-}" ]]; then
        keepalive_sudo
    fi

    install_packages
    install_paru
    install_aur
    set_keyboard_layout
    apply_stow
    seed_host_conf
    install_iwd_config
    install_mtui
    install_taskr
    install_claude_code
    apply_gsettings
    set_login_shell_to_fish
    enable_system_services
    enable_user_services
    configure_git_hooks

    cat <<'EOF'

==> Done. Manual follow-ups (script can't automate these):

  • Log out and back in for the fish shell change to take effect.
  • aerc Gmail: store the app password in the keyring (one time per machine):
        install -Dm600 ~/dotfiles/aerc/.config/aerc/accounts.conf.example \
                      ~/.config/aerc/accounts.conf
        secret-tool store --label="aerc Gmail" service aerc \
                          account markbauerruby@gmail.com
  • rclone: configure the dropbox + onedrive remotes (one time per machine):
        rclone config
        systemctl --user restart rclone-dropbox.service rclone-onedrive.service
  • Hyprland: review ~/.config/hypr/host.conf and adjust monitor names for
    this machine's hardware (`hyprctl monitors` shows the connector names).
  • Reboot once to pick up the new vconsole keymap and Ly login manager.
EOF
}

main
