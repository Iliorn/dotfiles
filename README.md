# Dotfiles

Personal configuration files for my CachyOS / Arch Linux setup, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Setup overview

| Component       | Program          |
|----------------|-----------------|
| Browser         | Zen Browser     |
| Window manager  | Hyprland        |
| Terminal        | Kitty           |
| Shell           | Fish            |
| Editor          | Helix           |
| File manager    | Yazi (in Kitty) |
| App launcher    | Rofi            |
| Status bar      | Waybar          |
| Notifications   | Dunst           |
| Wallpaper       | awww + waypaper |
| Login manager   | Ly              |
| Screen locker   | Hyprlock + Hypridle |
| Screenshots     | Grim + Slurp    |
| Bluetooth       | Blueman + bluetui |
| WiFi            | iwd + systemd-resolved |
| Cloud sync      | Rclone          |
| Task manager    | taskmanager (custom Bubbletea TUI)          |
| AI CLI          | mods            |
| Resource monitor| Btop            |
| System info     | Fastfetch       |

---

## 1. Install dependencies

### Core Hyprland stack
```bash
sudo pacman -S hyprland xdg-desktop-portal-hyprland
```

### Login manager
```bash
sudo pacman -S ly
sudo systemctl disable sddm  # if previously enabled
sudo systemctl enable ly@tty2
```

Ly is a minimal TUI display manager. Its config lives at `/etc/ly/config.ini` — defaults work fine for Hyprland. One recommended tweak:

```ini
allow_empty_password = true
```

This lets you log in without a password if your account has none set (common on single-user setups). Edit with:
```bash
sudo nano /etc/ly/config.ini
```

Ly picks up Wayland sessions from `/usr/share/wayland-sessions/`, so Hyprland will appear in the session list automatically.

> **Note:** `ly` only ships `ly@.service` (a templated unit). `systemctl enable ly` will fail — always use `ly@tty2`.

### Terminal & shell
```bash
sudo pacman -S kitty fish
chsh -s /usr/bin/fish
```

### Editor & file manager
```bash
sudo pacman -S helix yazi
```

### App launcher
```bash
sudo pacman -S rofi-wayland
```

### Status bar & notifications
```bash
sudo pacman -S waybar dunst
```

### Wallpaper
```bash
sudo pacman -S awww
sudo pacman -S waypaper
```

`awww` is the animation/rendering daemon. `waypaper` is a GUI wallpaper picker that persists the last selection — Hyprland runs `waypaper --restore` on login to reload it.

### Screen lock
```bash
sudo pacman -S hyprlock hypridle
```

Hypridle dims the screen after 5 min, locks after 10 min, and suspends after 15 min. It starts automatically with Hyprland.

### Screenshots
```bash
sudo pacman -S grim slurp wl-clipboard
```

### Audio (PipeWire)
```bash
sudo pacman -S pipewire pipewire-pulse wireplumber
```

### Brightness control
```bash
sudo pacman -S brightnessctl
```

### Bluetooth
```bash
sudo pacman -S blueman bluetui
sudo systemctl enable --now bluetooth
```

Blueman provides a system tray applet (`blueman-applet`) that starts automatically with Hyprland. To pair a device for the first time, run `blueman-manager`. The Waybar bluetooth widget opens `bluetui` for a quick TUI overview.

### WiFi
```bash
sudo pacman -S iwd
sudo systemctl enable --now iwd systemd-resolved
```

Apply the iwd config (enables IP configuration and uses systemd-resolved for DNS):
```bash
sudo cp ~/dotfiles/iwd/main.conf /etc/iwd/main.conf
sudo systemctl restart iwd
```

To connect to a WiFi network:
```bash
iwctl
[iwd] station wlan0 scan
[iwd] station wlan0 get-networks
[iwd] station wlan0 connect "Network Name"
```

### Cloud sync (Dropbox + OneDrive)
```bash
sudo pacman -S rclone
```

Create the mount point directories:
```bash
mkdir -p ~/Dropbox ~/OneDrive
```

Configure the remotes interactively (requires a browser for OAuth):
```bash
rclone config
```

For **Dropbox**: choose `n` (new remote), name it `dropbox`, type `dropbox`, follow the OAuth flow.

For **OneDrive**: choose `n` (new remote), name it `onedrive`, type `onedrive`, follow the OAuth flow.

The mounts are launched automatically by Hyprland on login (see `hyprland.conf` autostart). To test them manually:
```bash
rclone mount dropbox: ~/Dropbox --vfs-cache-mode full --daemon
rclone mount onedrive: ~/OneDrive --vfs-cache-mode full --daemon
```

### Power management (TLP)
```bash
sudo pacman -S tlp tlp-rdw
sudo systemctl enable --now tlp
```

TLP handles battery optimization and power saving automatically on laptops.

### Performance (ananicy-cpp)
```bash
sudo pacman -S ananicy-cpp
sudo systemctl enable --now ananicy-cpp
```

Automatically adjusts process priorities for better responsiveness.

### Firewall (ufw)
```bash
sudo pacman -S ufw
sudo ufw enable
sudo systemctl enable --now ufw
```

### mDNS / local network discovery (avahi)
```bash
sudo pacman -S avahi
sudo systemctl enable --now avahi-daemon
```

### BTRFS snapshots (snapper)
```bash
sudo pacman -S snapper
```

Snapshots are managed automatically via `limine-snapper-sync`.

### Fonts
```bash
sudo pacman -S ttf-jetbrains-mono-nerd
```

> **Note:** `waybar/style.css` uses `JetBrainsMono Nerd Font`. Without this package, Nerd Font icons (Bluetooth, etc.) fall back to Adwaita 3D icons.

### Task management

`taskr` is a custom Bubbletea TUI for managing tasks. The repo is private, so installation requires `gh` auth.

```bash
gh release download --repo iliorn/taskr --pattern 'taskr' --dir ~/.local/bin
chmod +x ~/.local/bin/taskr
```

Run with `taskr`. Press `U` inside the app to self-update.

### AI CLI (mods)
```bash
paru -S mods
```

`mods` is Charm's AI CLI tool. Config is managed by Stow — see `mods/` in this repo. After stowing, edit `~/.config/mods/mods.yml` to set your API key and preferred model.

### Musik (Spotify)
```bash
sudo pacman -S spotify-launcher
```

### Utilities
```bash
sudo pacman -S btop fastfetch micro
```

---

## 2. Clone and apply with Stow

```bash
git clone https://github.com/iliorn/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Apply all configs at once:
```bash
stow --target="$HOME" btop dunst fastfetch fish helix hypr kitty micro mods waybar waypaper
```

Or apply individually, e.g.:
```bash
stow --target="$HOME" hypr
stow --target="$HOME" kitty
```

> **Note:** Stow creates symlinks from `~/.config/<app>` to the corresponding folder in this repo. If a config already exists, remove or back it up first.

### System-level configs (not managed by Stow)

These files live under `/etc/` and must be copied manually with sudo:

```bash
# WiFi (iwd)
sudo cp ~/dotfiles/iwd/main.conf /etc/iwd/main.conf
sudo systemctl restart iwd
```

---

## 3. Keybindings

| Shortcut             | Action                        |
|---------------------|-------------------------------|
| `Super + Q`         | Open terminal (Kitty)         |
| `Super + W`         | Open browser (Zen Browser)    |
| `Super + E`         | Open file manager (Yazi)      |
| `Super + Space`     | App launcher (Rofi)           |
| `Super + C`         | Close active window           |
| `Super + F`         | Fullscreen                    |
| `Super + V`         | Toggle floating               |
| `Super + Escape`    | Lock screen + suspend         |
| `Super + Shift + M` | Exit Hyprland                 |
| `Super + H/J/K/L`   | Move focus (vim-style)        |
| `Super + Shift + H/J/K/L` | Resize window           |
| `Super + 1–0`       | Switch workspace              |
| `Super + Shift + 1–0` | Move window to workspace    |
| `Super + S`         | Toggle scratchpad             |
| `Super + Shift + S` | Move to scratchpad            |
| `Print`             | Screenshot (full screen)      |
| `Shift + Print`     | Screenshot (select area)      |
| `Ctrl + Shift + Print` | Screenshot to clipboard    |

---

## mtui — Music TUI for BluOS

Terminal interface for BluOS/Bluesound devices.

**Requirements:** `python`, `fzf`, `curl`

```bash
sudo pacman -S python fzf curl
cp ~/dotfiles/scripts/mtui.sh ~/.local/bin/mtui
chmod +x ~/.local/bin/mtui
```

Create config:
```bash
mkdir -p ~/.config/mtui
nano ~/.config/mtui/config
```

```bash
NODE_IP="192.168.x.x:11000"     # Your BluOS device IP
SERVER_IP="YOUR_COMPUTER_IP:8000"
MUSIC_DIR="/home/YOUR_USERNAME/Music"
PLAYLIST_DIR="/tmp/mtui-playlists"
```

Allow firewall access from the BluOS device:
```bash
sudo ufw allow from 192.168.x.x to any port 8000
```

Run: `mtui`

---

## Claude Code (AI assistant in the terminal)

Install via npm:
```bash
sudo pacman -S nodejs npm
npm install -g @anthropic-ai/claude-code
```

Then run `claude` in any project directory. On first run it will ask you to log in with your Anthropic account.
