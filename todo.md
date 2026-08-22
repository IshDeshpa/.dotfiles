# Dotfiles and setup ideas

Tailored to this Arch + Niri + Waybar + Kitty + Bash + Neovim setup on
2026-08-11.

## My recommended order

| Priority | Addition | Effort | Why it fits this setup |
|---|---|---:|---|
| 1 | Repair the Niri session plumbing | 20 min | There are a few real Sway-era leftovers and broken links now. |
| 2 | Add `cliphist` + Fuzzel clipboard history | 15 min | This is the biggest missing everyday Wayland feature. |
| 3 | Turn on the already-installed `fzf` Bash integration | 5 min | Better history, file insertion, and directory jumping for almost no config. |
| 4 | Add Satty screenshot annotation | 20 min | The current recording/screenshot setup already has `grim` and `slurp`. |
| 5 | Add a dotfiles health-check command | 30 min | This repo has enough moving parts that automated validation will pay off. |
| 6 | Add Restic backups and a user timer | 45 min | Dotfiles are reproducible; personal data still needs actual backups. |
| 7 | Adopt `mise` for project toolchains | 30 min/project | Especially useful for Python, Node, Go, Rust, STM32, and course projects. |

## Fix these first

These are not glamorous, but they remove several sharp edges before adding more
features.

### 1. Add a Polkit authentication agent

No graphical Polkit agent is currently running. NetworkManager permits normal
network control, but system-wide profile changes still require authentication.
The same issue will affect other desktop tools that request elevated privileges.

`hyprpolkitagent` is in the Arch repositories and ships a systemd user unit. It
works outside Hyprland despite the name; its [official usage
page](https://wiki.hypr.land/Hypr-Ecosystem/hyprpolkitagent/) explicitly allows
starting it from other environments.

```bash
yay -S --needed hyprpolkitagent
systemctl --user add-wants niri.service hyprpolkitagent.service
```

This belongs beside the existing Mako, Waybar, Swayidle, and Nirinit units in
`systemd/user/niri.service.wants/`.

### 2. Repair the idle service

`systemd/user/swayidle.service` still calls `swaymsg`, which cannot control
Niri. Replace the DPMS commands with Niri IPC:

```text
timeout 360 'niri msg action power-off-monitors'
resume 'niri msg action power-on-monitors'
```

Also repair this broken symlink (it is missing `/.` between the username and
`dotfiles`):

```text
systemd/user/niri.service.wants/swayidle.service
  -> /home/ishdeshpa.dotfiles/systemd/user/swayidle.service
```

Prefer a relative link so the repository is less tied to one home directory:

```bash
ln -s ../swayidle.service systemd/user/niri.service.wants/swayidle.service
```

### 3. Remove old manual Xwayland startup

`niri/config.kdl` manually starts `xwayland-satellite`, but recent Niri versions
integrate it and launch it on demand. This machine has Niri 26.04 and
`xwayland-satellite-git` 0.8.1, so the old `spawn-at-startup` line should no
longer be needed. See the [Niri 25.08 integration
notes](https://github.com/YaLTeR/niri/discussions/2317).

### 4. Fix two small configuration mismatches

- Waybar requests a height of 20 px but reports that its modules need 29 px.
  Set `"height": 29` or remove the fixed height.
- The mic-mute binding uses the suspicious `pactl set-mute` form. Use
  `pactl set-source-mute @DEFAULT_SOURCE@ toggle` and verify the actual default
  source with `pactl get-default-source`.

### 5. Make bootstrap/restore trustworthy

The current install path calls missing `scripts/config-ln.sh`; the real script
appears to be `scripts/config.sh`. The package manifests also do not yet include
new additions such as Nirinit. Before trusting a reinstall:

- fix the stale script name;
- separate explicit repository packages and AUR packages;
- record Flatpaks separately;
- add a `restore --dry-run` or preflight mode;
- test bootstrap inside a disposable VM at least occasionally.

Suggested generated files:

```text
packages/repo.txt      pacman -Qqen
packages/aur.txt       pacman -Qqem
packages/flatpak.txt   flatpak list --app --columns=application
```

## High-delight additions

### 1. Clipboard history with `cliphist` and Fuzzel

This is the first feature I would add. `cliphist` stores text and images and is
deliberately picker-agnostic; its upstream documentation includes a Fuzzel
pipeline. [Cliphist documentation](https://github.com/sentriz/cliphist)

Install it:

```bash
yay -S --needed cliphist
```

Run these as Niri-scoped user services:

```bash
wl-paste --type text --watch cliphist store
wl-paste --type image --watch cliphist store
```

Then bind `Mod+Shift+V`:

```kdl
Mod+Shift+V {
    spawn-sh "cliphist list | fuzzel --dmenu --with-nth 2 | cliphist decode | wl-copy";
}
```

Useful companion actions:

```bash
cliphist list | fuzzel --dmenu --with-nth 2 | cliphist delete
cliphist wipe
```

Because clipboard history can capture passwords and tokens, add a convenient
wipe action and consider excluding sensitive workflows.

### 2. Activate the `fzf` features already installed

`fzf` 0.74.2 is installed but its Bash integration is not loaded. Add this near
the end of `.bashrc`:

```bash
eval "$(fzf --bash)"
```

That gives:

- `Ctrl+R`: fuzzy command history;
- `Ctrl+T`: insert files/directories into the current command;
- `Alt+C`: fuzzy `cd`.

Use the already-installed `fd` and `bat` for faster search and previews:

```bash
export FZF_CTRL_T_OPTS="--walker-skip .git,node_modules,target --preview 'bat -n --color=always {}'"
```

The options and bindings are documented in the [official fzf
README](https://github.com/junegunn/fzf).

### 3. Screenshot annotation with Satty

Satty adds arrows, blur, highlighting, cropping, text, and clipboard output.
`grim` and `slurp` are already installed, so this fills the one missing piece.
[Satty documentation](https://github.com/Satty-org/Satty)

```bash
yay -S --needed satty
```

Suggested Niri binding:

```kdl
Mod+Shift+Print {
    spawn-sh "grim -g \"$(slurp)\" -t ppm - | satty --filename - --copy-command wl-copy --early-exit";
}
```

An optional second action can run the captured region through Tesseract and
copy recognized text, which is surprisingly useful for screenshots, remote
desktops, and lecture slides.

### 4. Turn Fuzzel into a small command palette

Keep Fuzzel as the fast launcher, then add focused menus rather than replacing
the whole desktop shell:

- clipboard history;
- emoji/Unicode picker that writes to `wl-copy`;
- SSH host picker from `~/.ssh/config`;
- `man`/`tldr` page picker opened in Kitty;
- project picker that opens Kitty + tmux in the selected repository;
- power menu using the existing logout script;
- Bitwarden item picker using `rbw` if a CLI vault workflow is desirable.

Small scripts in `scripts/menu-*` will be easier to test than giant inline KDL
commands.

### 5. Better Waybar signals

Useful additions that match the existing bar:

- `power-profiles-daemon` module with click-to-cycle profiles;
- idle-inhibitor module for presentations and long builds;
- failed user-service count, opening `systemctl --user --failed` in Kitty;
- microphone-active/muted indicator;
- update count driven by the existing `aurveto` workflow;
- backup freshness indicator once Restic is configured.

Prefer event signals (`signal` or `exec-on-event`) over one-second polling. The
network module is currently set to a one-second interval and is a good candidate
for less frequent updates.

## Developer workflow upgrades

### 1. `mise` for per-project tools, environment, and tasks

The global shell currently hard-codes project paths for Pintos, Yash grading,
STM32CubeProgrammer, and the UV cache. Move project-specific settings into
project-local `mise.toml` files instead. `mise` manages tool versions, environment
variables, and tasks from one checked-in file. [Official mise
documentation](https://mise.jdx.dev/)

Example:

```toml
[tools]
python = "3.13"
node = "24"

[env]
UV_CACHE_DIR = "/mnt/.uvcache"

[tasks.test]
run = "pytest"

[tasks.debug]
run = "arm-none-eabi-gdb build/firmware.elf"
```

Then `.bashrc` only needs:

```bash
eval "$(mise activate bash)"
```

### 2. An embedded-development tmux launcher

The package lists show a strong STM32/ARM workflow. Add a project command that
creates a repeatable tmux workspace:

```text
┌ editor/build ──────────┬ serial monitor ┐
│ nvim                   │ picocom        │
├────────────────────────┼────────────────┤
│ openocd logs           │ arm-none-eabi-gdb
└────────────────────────┴────────────────┘
```

Make it data-driven (`.embedded.toml` or `mise.toml`) so board, serial device,
OpenOCD config, and ELF path vary by repository. This is more valuable than
adding another generic shell alias.

### 3. A nicer Git loop

Consider:

- `git-delta` for syntax-highlighted diffs and side-by-side review;
- `lazygit` for interactive staging/rebasing;
- a Fuzzel or fzf repository picker;
- `gh dash` for a terminal pull-request dashboard if GitHub work is frequent.

Do not alias away core Git commands immediately; add these as optional views
until the workflow feels natural.

### 4. Terminal file navigation

`yazi` fits Kitty especially well because it supports image previews and a shell
wrapper that can change the parent shell's directory. A small `y()` Bash function
is more useful than aliasing `cd` further. Pair it with:

- `btop` for system monitoring;
- `dust` for directory-size exploration;
- `duf` for filesystem usage;
- `procs` for interactive process inspection.

These are all available in the current Arch repositories.

## Reliability and security

### 1. Restic backups with systemd timers

The package manifests recreate software, but they do not protect documents,
projects, SSH material, or application data. Restic provides encrypted,
deduplicated snapshots and supports retention policies. Its docs recommend
preventing overlapping scheduled runs and provide `forget`/`prune` controls.
[Restic backup documentation](https://restic.readthedocs.io/en/stable/040_backup.html)

Create separate user units for:

- frequent backup (`restic-backup.timer`);
- periodic integrity sampling (`restic-check.timer`);
- retention/pruning (`restic-forget.timer`).

Back up at least:

```text
~/.dotfiles
~/mnt/Work
~/mnt/vault
~/.ssh
~/.local/share/atuin       # if Atuin is added without sync
~/.local/share/nirinit
```

Store repository credentials with systemd credentials, a password manager, or
SOPS—not as plaintext committed to this repository.

### 2. SOPS + age for encrypted machine secrets

If machine-specific tokens or environment files ever need to live alongside the
dotfiles, use SOPS with age rather than expanding `.gitignore`. SOPS encrypts
values while keeping YAML/JSON structure diffable and can pass decrypted data
directly to child processes. [SOPS documentation](https://github.com/getsops/sops)

Keep the age private key outside Git and back it up separately. Losing it means
losing access to the encrypted files.

### 3. Atuin for contextual shell history

Atuin stores shell history in SQLite with directory, exit status, duration, and
host context. Sync is optional and end-to-end encrypted; local-only mode is also
useful. [Atuin documentation](https://docs.atuin.sh/)

This overlaps with fzf's `Ctrl+R`. Start with free fzf integration first. Adopt
Atuin only if contextual search or cross-machine encrypted history is valuable.

### 4. Add a dotfiles health check

Create one command—perhaps `just check` or `scripts/check.sh`—that runs:

```bash
bash -n scripts/*.sh
shellcheck scripts/*.sh
niri validate -c niri/config.kdl
systemd-analyze --user verify systemd/user/*.service
git diff --check
```

Also verify:

- every script/config path referenced by Niri and Waybar exists;
- every symlink under `systemd/user/*.wants/` resolves;
- package lists are sorted and contain no duplicates;
- the restore script references only existing files;
- no likely secrets are staged.

Run it locally before commits and in GitHub Actions. This would have caught the
broken Swayidle link, missing `config-ln.sh`, and missing `volume.sh` immediately.

## Configuration-structure improvements

### 1. Stop linking every top-level directory into `~/.config`

`scripts/config.sh` currently loops over every top-level directory. That can
accidentally link non-config directories such as `scripts`, package metadata, or
future documentation. Replace it with an explicit manifest:

```bash
configs=(fastfetch fuzzel kitty mako niri nirinit nvim swaylock waybar)
```

Handle `.bashrc`, Starship, tmux, and systemd units explicitly. Explicit lists
are less magical and much safer during bootstrap.

### 2. Use relative paths or `$HOME` consistently

Many configs embed `/home/ishdeshpa`, while others use `~`. Absolute paths are
fine for this one machine but undermine restore testing. Prefer:

- relative symlinks inside the repository;
- `$HOME` in shell scripts;
- wrapper scripts when a config format does not expand environment variables;
- generated machine-local fragments for monitor layouts and hardware device
  names.

The hard-coded `amdgpu_bl1` backlight device and output names are good candidates
for a host-specific file.

### 3. Split large Niri and Waybar configs

Niri supports includes, so separate stable behavior from hardware-specific
output configuration and personal keybindings. For Waybar, keep one main file
but move custom module behavior into executable scripts.

Suggested layout:

```text
niri/
  config.kdl
  binds.kdl
  outputs/
    arch-fw.kdl
  rules.kdl
waybar/
  config.jsonc
  modules/
    backup-status
    service-health
    update-status
```

## A realistic first weekend

1. Fix Polkit, Swayidle, the broken symlink, Waybar height, and the stale
   bootstrap script reference.
2. Add `cliphist`, the Fuzzel picker, and a wipe binding.
3. Enable `fzf --bash` with `bat` previews.
4. Add Satty on `Mod+Shift+Print`.
5. Create `scripts/check.sh` and make it pass on the current repository.
6. Commit that stable baseline before starting Restic or `mise` migration.

That set would noticeably improve daily use without replacing the character of
the current setup.
