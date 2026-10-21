# Dotfiles

Personal configuration files for my CachyOS / Arch Linux setup, managed with [GNU Stow](https://www.gnu.org/software/stow/).

The machines themselves are owned by Ansible, in the private `Iliorn/ansible`
repo: it installs every package, runs stow, sets the login shell, seeds the
host-local files and enables the services. This repo holds the configs, and
`i` is the bootstrap that gets a blank machine far enough for Ansible to
reach it.

## From zero on a fresh install

### 1. Fix the keyboard

A fresh install often boots with a US keymap even on a Danish keyboard. Run
this before anything else; it is only letters and a space, so it is easy to
type with the wrong keymap:

```
sudo loadkeys dk
```

In a Wayland desktop, set the keyboard to Danish in system settings instead.

### 2. Get online

From the TTY, over WiFi:

```bash
iwctl
[iwd] station wlan0 scan
[iwd] station wlan0 get-networks
[iwd] station wlan0 connect "Your Network"
[iwd] exit
```

### 3. Run the bootstrap

Two short commands, with no pipes and no `https://`, because they have to be
typed on a keyboard that may still be wrong:

```
curl -LO github.com/iliorn/dotfiles/raw/main/i
sh i
```

`i` installs the few packages Ansible needs to reach the machine (`git`,
`stow`, `python`, `tailscale`, `ansible-core`), clones this repo to
`~/dotfiles` and activates the pre-commit hook. It then prints the three
steps only you can do: name the machine, join the tailnet, add it to the
inventory.

### 4. Let Ansible do the rest

Packages, the stow run, the TTY keymap, `iwd` and `resolv.conf`, tjek, Claude
Code, the GTK theme, the login shell, the services and the git hook are all
Ansible's. Its `ONBOARDING.md` is the procedure; read it there, so there is
one copy.

```bash
ansible-playbook site.yml --limit <name> --check --diff -K   # look first
ansible-playbook site.yml --limit <name> --tags packages -K  # then one tag at a time
```

Once a `--check` run reports `changed=0`, hoth's fleet-push keeps dotfiles,
settings and tjek current whenever the laptop is online.

### Three things only you can do

1. **Reboot once**, to pick up the TTY keymap (`KEYMAP=dk`) and the greeter.
2. **`rclone config`** to create the `dropbox` and `onedrive` remotes (the
   OAuth flow needs a browser), then
   `systemctl --user restart rclone-{dropbox,onedrive}.service`.
3. **The aerc Gmail password.** The tracked account file is only a template,
   and the secret must be created on each laptop. Enter the app password at
   the prompt rather than in the command:
   ```bash
   install -Dm600 ~/dotfiles/aerc/.config/aerc/accounts.conf.example \
                  ~/.config/aerc/accounts.conf
   secret-tool store --label="aerc Gmail" service aerc \
                     account markbauerruby@gmail.com
   stat -c '%a %n' ~/.config/aerc/accounts.conf   # should say 600
   ```
   Never rename the example to `accounts.conf` inside this repo or commit a
   password.

## Notes on what Ansible installs

Facts that are easy to trip over when doing a piece by hand:

- **AUR packages** are never built by Ansible, because `paru` runs its own
  interactive sudo, which Ansible cannot answer. The list is `packages_aur`
  in the Ansible repo, and Ansible reports on each run whether a build is
  behind. Build them yourself, e.g. `paru -S libsearpc seafile
  seafile-client`. Without `paru`, build it once from the AUR:
  `git clone --depth=1 https://aur.archlinux.org/paru.git /tmp/paru`, then
  `cd /tmp/paru && makepkg -si`.
- **cliphist** records nothing by itself: its two `wl-paste --watch`
  processes are started from Hyprland's autostart, so history begins at login.
- **`ly`** ships only the templated `ly@.service`, so `systemctl enable ly`
  fails; the unit is `ly@tty2`.
- **TLP must not be installed** beside `power-profiles-daemon`, which CachyOS
  ships active. They are mutually exclusive, and TLP would silently break the
  Waybar profile picker.
- **`ttf-jetbrains-mono-nerd` is required.** Without it Waybar's icons fall
  back to Adwaita's.
- **The icon theme** is `BeautyLine` (AUR: `beautyline`), set in
  `gtk-3.0/settings.ini`. dconf outranks `settings.ini` for many GTK apps, so
  also run `gsettings set org.gnome.desktop.interface icon-theme 'BeautyLine'`;
  that is per-user state this repo does not track.
- **`gnome-keyring`** backs `secret-tool`. Without it `secret-tool` fails
  with "The name is not activatable" and aerc cannot authenticate.
- **`iwd/main.conf`** is a system file, not stowed: it belongs at
  `/etc/iwd/main.conf` (Ansible copies it), and `iwd` needs a restart after.
- **tjek** is public and installs from a GitHub release
  (`gh release download --repo iliorn/tjek --pattern tjek --dir
  ~/.local/bin`, then `chmod +x`). `U` inside the app updates it. Waybar's
  tjek module reads `tjek stats --format=waybar` and refreshes when
  `tjek-waybar-refresh.path` sees `tasks.db` change, with a 5-minute poll as
  a fallback.

## Setup overview

| Component        | Program                  |
|------------------|--------------------------|
| Browser          | Zen Browser              |
| Window manager   | Hyprland                 |
| Terminal         | Alacritty                |
| Shell            | Fish                     |
| Editor           | Helix                    |
| File manager     | Superfile (in Alacritty) |
| App launcher     | Rofi                     |
| Status bar       | Waybar                   |
| Notifications    | Dunst                    |
| Wallpaper        | awww + waypaper          |
| Login manager    | Ly                       |
| Screen locker    | Hyprlock + Hypridle      |
| Screenshots      | Grim + Slurp + Satty     |
| Clipboard        | wl-clipboard + cliphist  |
| OSD              | SwayOSD                  |
| Colour picker    | Hyprpicker               |
| Bluetooth        | Blueman + bluetui        |
| WiFi             | iwd + systemd-resolved   |
| Cloud sync       | Rclone                   |
| Task manager     | tjek (Bubble Tea TUI)    |
| Mail             | aerc                     |
| AI CLI           | mods                     |
| Resource monitor | Btop                     |
| System info      | Fastfetch                |

## Palette and font

Every program in this repo is themed Nord, set in JetBrainsMono Nerd Font,
with a corner radius of 8. Anything added later should match these rather
than bring a new colour scheme. GTK apps get the same colours from
`gtk/.config/gtk-3.0/gtk.css` and `gtk/.config/gtk-4.0/gtk.css`.

| Role                  | Hex       |
|-----------------------|-----------|
| bg                    | `#2E3440` |
| bg-alt                | `#3B4252` |
| bg-sel                | `#434C5E` |
| muted                 | `#4C566A` |
| dim                   | `#6B7688` |
| fg                    | `#D8DEE9` |
| fg-soft               | `#E5E9F0` |
| fg-bright             | `#ECEFF4` |
| red                   | `#BF616A` |
| orange                | `#D08770` |
| yellow                | `#EBCB8B` |
| green                 | `#A3BE8C` |
| teal                  | `#8FBCBB` |
| cyan                  | `#88C0D0` |
| blue                  | `#81A1C1` |
| deep-blue             | `#5E81AC` |
| purple                | `#B48EAD` |

## Applying the configs with Stow

Ansible does this for you; by hand:

```bash
git clone https://github.com/Iliorn/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow --target="$HOME" aerc alacritty autostart btop codebook dunst fastfetch fish gtk helix hypr lazygit micro mimeapps mods obsidian rofi satty starship superfile swayosd systemd waybar waypaper wireplumber
```

or one package at a time, e.g. `stow --target="$HOME" hypr`. Stow symlinks
each package's files into `$HOME`. If a config already exists there, move it
aside first, or stow refuses.

### Host-local Hyprland config

Monitor layout and workspace pinning live in `~/.config/hypr/host.conf`, which
is gitignored because it differs per laptop. `hyprland.conf` sources it. On a
new machine Ansible seeds it from `hypr_host_conf` in its own `group_vars` and
never overwrites it afterwards. By hand:

```bash
cp hypr/.config/hypr/host.example.conf ~/.config/hypr/host.conf
$EDITOR ~/.config/hypr/host.conf
```

## Keybindings

| Shortcut                  | Action                                 |
|---------------------------|----------------------------------------|
| `Super + Q`               | Open terminal (Alacritty)              |
| `Super + W`               | Open browser (Zen Browser)             |
| `Super + E`               | Open file manager (Superfile)          |
| `Super + T`               | Open tjek                              |
| `Super + M`               | Open ncspot                            |
| `Super + Space`           | App launcher (Rofi)                    |
| `Super + C`               | Close active window                    |
| `Super + F`               | Fullscreen                             |
| `Super + V`               | Toggle floating                        |
| `Super + Escape`          | Lock screen + suspend                  |
| `Super + Shift + M`       | Exit Hyprland                          |
| `Super + Shift + N`       | Obsidian quick capture                 |
| `Super + H/J/K/L`         | Move focus (vim-style; arrow keys too) |
| `Super + Shift + H/J/K/L` | Resize window                          |
| `Super + 1–0`             | Switch workspace                       |
| `Super + Shift + 1–0`     | Move window to workspace               |
| `Super + S`               | Toggle scratchpad                      |
| `Super + Shift + S`       | Move to scratchpad                     |
| `Print`                   | Screenshot (full screen)               |
| `Shift + Print`           | Screenshot (select area)               |
| `Ctrl + Shift + Print`    | Screenshot to clipboard                |
| `Super + Print`           | Screenshot, select area and annotate   |
| `Super + Shift + V`       | Clipboard history (Alt+Delete removes) |
| `Super + Shift + C`       | Pick a colour to the clipboard         |
