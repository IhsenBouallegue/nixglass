# nixglass

NixOS + flakes + Home Manager config. Single-user developer workstation: 49" ultrawide (Samsung Odyssey G9, 5120x1440@240), AMD GPU. Bare-metal install running **mango + DankMaterialShell (DMS) + Ghostty + Zen**.

## Status

Bare-metal NixOS 25.11. Hostname `nixglass`, user `ihsen`. Daily-driver apps (bitwarden-desktop, anki, discord, code-cursor, bambu-studio, spotify) and the gaming stack (Steam at system level, Lutris + winetricks + mangohud in home) all run. DMS provides the bar, spotlight launcher, control center, dashboard, notifications, and lock — driven from `programs.dank-material-shell` and spawned via mango's `exec-once=dms run`. The G9 output is `DP-1` 5120x1440@240 + VRR.

System layer: AMD GPU + 32-bit Vulkan + `xdg.portal` (**gtk + wlr**, NOT gnome — see below) + polkit (lxqt agent autostarted from mango) + dconf + gvfs. Ghostty is pinned to upstream HEAD (1.3.2-dev) because nixpkgs-25.11 stable is on 1.3.1.

### Previous compositor stack (historical)

This config initially ran **niri + Noctalia** during the omarchy-customizer migration. The switch to mango + DMS happened post-install; older git history and any lingering references to niri/noctalia in comments are stale. There is no `niri.nix` in `home-manager/` anymore.

### Repo location

Repo lives at `~/nixglass` (user-owned, so git/edits don't need sudo). `/etc/nixos` is a symlink to it so `nixos-rebuild switch` works from either path. Public repo: `IhsenBouallegue/nixglass`, pushed via SSH.

## xdg.portal — the "GTK app slow launch" trap

Wlroots-family compositors (mango, sway, Hyprland, dwl) do NOT want the GNOME portal backend listed. With `extraPortals = [gtk gnome]` and `config.common.default = ["gnome" "gtk"]`, every GTK4 app launch blocks for ~50s waiting for `org.freedesktop.impl.portal.desktop.gnome` to activate over D-Bus — there's no gnome-session to provide it, so `StartServiceByName` times out for both the settings proxy and the file chooser proxy (25s each).

Symptom: Ghostty / Zen / any GTK4 app takes up to a minute to open a window; non-GTK apps (foot, alacritty) are instant. Diagnose with:

```
systemctl --user is-active xdg-desktop-portal        # "activating" = stuck
journalctl --user -u xdg-desktop-portal -n 50        # look for StartServiceByName timeouts
```

Current correct config (see `nixos/configuration.nix`):

```nix
xdg.portal = {
  enable = true;
  extraPortals = with pkgs; [ xdg-desktop-portal-gtk xdg-desktop-portal-wlr ];
  config.common = {
    default = ["gtk"];
    "org.freedesktop.impl.portal.Screenshot" = ["wlr"];
    "org.freedesktop.impl.portal.ScreenCast"  = ["wlr"];
  };
};
```

## Overlay pattern — pulling select packages from nixpkgs-unstable

`overlays/default.nix` has a `modifications` overlay that imports `inputs.nixpkgs-unstable` once and inherits specific packages from it:

```nix
modifications = final: prev: let
  unstable = import inputs.nixpkgs-unstable {
    system = final.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in {
  inherit (unstable) claude-code gh;
};
```

Reason: nixpkgs-25.11 stable lags upstream for several CLIs (claude-code, gh) by many versions. Cherry-picking from unstable lets us keep stable as the base. `lutris` and `zellij` use the older `unstablePkgs.X` inline pattern from `home-manager/home.nix` (legacy — fine to migrate to the inherit pattern as the list grows).

The `unstable-packages` overlay also patches `openldap` with `doCheck = false` to skip a flaky syncrepl test that otherwise blocks lutris's dep tree.

## Sudo askpass

`home.sessionVariables.SUDO_ASKPASS` points at a zenity wrapper script. Combined with `sudo -A`, GUI password prompts work from any context (Claude Code's Bash tool, scripts triggered by mango keybinds, anything without a tty) without falling back to the broken "sudo: a terminal is required" failure mode. Regular `sudo` in the terminal still works as normal.

## Topology — ONE host, not two

There is **one** `nixosSystem` named `nixglass`. The VM is **not** a separate host — it's the `.vmVariant` automatically derived from the same config. Used heavily during initial scaffolding; less so now that we're on bare metal, but kept for testing risky changes.

```
# VM (throwaway test rig)
nixos-rebuild build-vm --flake ~/nixglass#nixglass && ./result/bin/run-nixglass-vm
```

VM-specific overrides (qemu mem/disk, virgl `-device virtio-vga-gl`, GTK display, autologin, throwaway password) go in a `virtualisation.vmVariant = { ... }` block inside `nixos/configuration.nix`. **Do not split into two hosts** — they would drift.

## Target stack

| Layer | Tool | Notes |
|---|---|---|
| Compositor | **mango** | dwl-fork wlroots compositor. Launched via greetd autologin (`command = mangowc/bin/mango`). Reads `~/.config/mango/config.conf` (no merge with `/etc/mango/config.conf` — full replacement). |
| Bar / launcher / shell | **DankMaterialShell (DMS)** | quickshell + QML. Flake input `github:AvengeMedia/DankMaterialShell` + companion `dgop` CLI for system widgets. Spawned via mango's `exec-once=dms run`; spotlight launcher via `dms ipc call spotlight toggle`. |
| Terminal | Ghostty | Upstream-flake build (1.3.2-dev); colour palette and keybinds declarative in `home-manager/ghostty.nix`. Mango spawns the HM-configured package, NOT `pkgs.ghostty` — see below. |
| Browser | Zen | Theming needs `toolkit.legacyUserProfileCustomizations.stylesheets = true`. Mozilla Sync handles extensions + state — no declarative `extensions.packages` needed. |
| Editor | Neovim | Full config declarative; catppuccin-mocha colorscheme. |
| Gaming | Steam + Lutris (Proton) | `programs.steam.enable = true`; `allowUnfree = true`. AMD is plug-and-play. |

## Ghostty: use the HM-configured package in mango

`home-manager/mango.nix` binds `Alt+Return` to `${lib.getExe config.programs.ghostty.package}`, NOT `pkgs.ghostty`. The HM module configures the upstream-flake build (1.3.2-dev); if mango launched `pkgs.ghostty` (stable 1.3.1) instead, the two binaries register on D-Bus as the same application ID and fight on every spawn — windows take long enough to feel broken. The fix is to share one binary across both code paths.

Do NOT pass `--gtk-single-instance=false` — single-instance mode is the *fast* path (subsequent windows are forwarded over D-Bus to the existing process, no fresh GTK init).

## Reference: source config we ported from

`~/Documents/repos/omarchy-customizer/` — the Arch dotfile repo used pre-migration. Modular `install.sh` that symlinks configs into `~/.config/`. Already ported (or knowingly skipped):

- `configs/hypr/` → mango (upstream defaults + matte-candy palette + bind/exec-once overrides)
- `configs/waybar/` → DMS bar
- `configs/ghostty/config` → declarative HM module
- `configs/zellij/` → declarative HM module
- `configs/mako/` → DMS notifications
- `theme/matte-candy/colors.toml` → palette inlined in `home-manager/ghostty.nix` and `home-manager/mango.nix`
- `packages.txt` → system packages list

The bambustudio/cursor/discord packages are unfree — `allowUnfree = true` is already set.

## Commands

```
nix flake check                                                # validate flake (skip --no-build for full check)
nix flake update                                               # bump all inputs
nix fmt                                                        # alejandra formatter
sudo nixos-rebuild switch --flake ~/nixglass#nixglass          # main rebuild (or: nh os switch)
nixos-rebuild build-vm --flake ~/nixglass#nixglass             # build VM
./result/bin/run-nixglass-vm                                   # boot VM (qemu)
home-manager switch --flake ~/nixglass#ihsen@nixglass          # home-only iteration (HM standalone)
```
