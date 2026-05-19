# nixglass

NixOS + flakes + Home Manager config. Single-user developer workstation: 49" ultrawide (Samsung Odyssey G9, 5120x1440@240), AMD GPU. Bare-metal install running niri + Noctalia + Zen + Ghostty.

## Status

Bare-metal NixOS 25.11. Hostname `nixglass`, user `ihsen`. The full daily-driver app set runs (bitwarden-desktop, anki, discord, code-cursor, bambu-studio, spotify) plus the gaming stack (Steam at system level, Lutris + winetricks + mangohud in home). Noctalia bar (Catppuccin-Lavender) renders fine; niri keybinds cover screenshot (`Mod+Shift+S`, plus `Print` / `Mod+Print` / `Ctrl+Print` for region/screen/window — all via `niri msg action`), audio (`wpctl`), brightness (`brightnessctl`), media (`playerctl`), and Noctalia lock (`Mod+Ctrl+L`). The G9 output is pinned `DP-1` 5120x1440@240 + VRR.

System layer: AMD GPU + 32-bit Vulkan + `xdg.portal` (gnome+gtk) + polkit (lxqt agent autostarted from niri) + dconf + gvfs. Ghostty is pinned to upstream HEAD (1.3.2-dev) for the ext-background-effect-v1 protocol; niri is pinned to flake HEAD for the same reason.

### Repo location

Repo lives at `~/nixglass` (user-owned, so git/edits don't need sudo). `/etc/nixos` is a symlink to it so `nixos-rebuild switch` works from either path. Public repo: `IhsenBouallegue/nixglass`, pushed via SSH.

### Outstanding

- **Noctalia `mkOutOfStoreSymlink`**: `~/.config/noctalia` is still a `/nix/store` symlink (read-only). Settings GUI edits silently vanish on next HM activation. See [§The mkOutOfStoreSymlink rule](#the-mkoutofstoresymlink-rule).
- **Nvim colorscheme not generated from Matte-Candy**: hard-coded catppuccin-mocha. Wire a Noctalia user-template so nvim/zellij track the bar preset.

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

`home.sessionVariables.SUDO_ASKPASS` points at a zenity wrapper script. Combined with `sudo -A`, GUI password prompts work from any context (Claude Code's Bash tool, scripts triggered by niri keybinds, anything without a tty) without falling back to the broken "sudo: a terminal is required" failure mode. Regular `sudo` in the terminal still works as normal.

## Topology — ONE host, not two

There is **one** `nixosSystem` named `nixglass`. The VM is **not** a separate host — it's the `.vmVariant` automatically derived from the same config. Used heavily during initial scaffolding; less so now that we're on bare metal, but kept for testing risky changes.

```
# VM (throwaway test rig)
nixos-rebuild build-vm --flake ~/nixglass#nixglass && ./result/bin/run-nixglass-vm
```

VM-specific overrides (qemu mem/disk, virgl `-device virtio-vga-gl`, SDL+GL display, autologin, throwaway password) go in a `virtualisation.vmVariant = { ... }` block inside `nixos/configuration.nix`. **Do not split into two hosts** — they would drift.

### qemu SDL controls (no menubar like GTK)

- **Ctrl+Alt+G** — release captured keyboard/mouse
- Close the SDL window or `pkill qemu-system-x86_64` to quit
- The display is SDL not GTK because qemu's GtkGLArea path fails on this Wayland host. SDL+GL works fine.

## Target stack

| Layer | Tool | Notes |
|---|---|---|
| Compositor | **Niri** | Scrollable tiling; fits ultrawide. Via `sodiboo/niri-flake`. No native session restore — use `spawn-at-startup` + window rules. |
| Bar + theming engine | **Noctalia** | Replaces waybar. Flake input `github:noctalia-dev/noctalia-shell`; not in nixpkgs. Add via `inputs.noctalia.homeModules.default`. PAM entry for lock screen is NOT auto-configured — add manually. |
| Terminal | Ghostty | Non-color config declarative; colors come from Noctalia. |
| Browser | Zen | Theming needs `toolkit.legacyUserProfileCustomizations.stylesheets = true` in about:config. Mozilla Sync handles extensions + state — no declarative `extensions.packages` needed. |
| Editor | Neovim | Full config declarative. |
| Gaming | Steam + Lutris (Proton) | `programs.steam.enable = true`; `allowUnfree = true`. AMD is plug-and-play. |

## The Nix-vs-Noctalia ownership boundary (critical)

Two layers, do not mix:

- **Nix manages:** software install, all non-color config (keybinds, plugins, fonts, packages, niri config, nvim config).
- **Noctalia manages at runtime:** all color theming. Its Python template processor reads `~/.config/noctalia/colors.json` and writes themed config files for:
  - Ghostty, Zen (userChrome.css + userContent.css), GTK3/4, Qt, niri borders → auto-themed (native templates).
  - **Neovim is NOT in the native list.** Use a colorscheme plugin (tokyonight/catppuccin) matched to the Noctalia preset, or write a user template in `~/.config/noctalia/user-templates.toml`.

### Current state (carried over from VM-scaffolding phase)

`programs.noctalia-shell.settings` is declared via the home module, which means home-manager writes `~/.config/noctalia/settings.json` as a `/nix/store` symlink. Noctalia's runtime edits to settings.json are silently dropped (the file is read-only).

This is the **opposite** of the ownership boundary above, but it was necessary during scaffolding because:

- Noctalia with empty settings registers no bar widgets and creates no layer-shell surface (`niri msg layers` returns empty).
- `mkOutOfStoreSymlink` to `${repo}/dotfiles/noctalia/` only resolved on the bare-metal host — the VM had no such path.

**Next step on bare-metal**: switch to mkOutOfStoreSymlink and seed `dotfiles/noctalia/settings.json` from the current declarative version as a starting point. See below.

### The mkOutOfStoreSymlink rule

Noctalia writes back to its own config dir at runtime (`settings.json`, generated theme files). If Home Manager places those from `/nix/store` they are read-only and Noctalia silently fails to edit them.

**Fix:** mount `~/.config/noctalia` as a writable symlink into this repo, not a store path:

```nix
home.file.".config/noctalia".source =
  config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/nixglass/dotfiles/noctalia";
```

The directory `dotfiles/noctalia/` is git-tracked (custom `colorschemes/matte-candy.json` lives there), but Noctalia is free to edit `settings.json` and the generated files inside it. Declarative + GUI-editable.

Reference: https://github.com/noctalia-dev/noctalia-shell/issues/2214

### Things to NOT manage declaratively

- `~/.config/noctalia/settings.json` (Noctalia rewrites it)
- Themed ghostty config, `gtk.css`, Qt color files, Zen `userChrome.css`/`userContent.css`, niri border colors — all auto-generated by Noctalia.

### Things to manage declaratively

- niri config (via `niri-flake` module)
- ghostty non-color config
- nvim full config
- Custom Noctalia colorscheme JSON in `dotfiles/noctalia/colorschemes/` (static, read-only from Noctalia's POV)
- All packages, system services, fonts

## Reference: source config we ported from

`~/Documents/repos/omarchy-customizer/` — the Arch dotfile repo used pre-migration. Modular `install.sh` that symlinks configs into `~/.config/`. Already ported (or knowingly skipped):

- `configs/hypr/` → niri (different config language entirely — translated, not transliterated)
- `configs/waybar/` → noctalia bar layout
- `configs/ghostty/config` → non-color bits as nix module; colors come from Noctalia
- `configs/zellij/` → declarative via home-manager
- `configs/mako/` → noctalia notification handler
- `theme/matte-candy/colors.toml` → `dotfiles/noctalia/colorschemes/Matte-Candy/Matte-Candy.json` (subdir layout — Noctalia's `ColorSchemeService` scans with `-mindepth 2 -name "*.json"`, a flat `matte-candy.json` will not be picked up)
- `packages.txt` → system packages list

The bambustudio/cursor/discord packages are unfree — `allowUnfree = true` is already set.

## Migration plan

1. ✅ Install Nix (Determinate official upstream installer) on the Arch host.
2. ✅ Scaffold flake from Misterio77 standard. Rename, fill FIXMEs.
3. ✅ Add niri-flake input + greetd autologin + vmVariant overrides. VM boots to empty niri session.
4. ✅ Add noctalia input, plus home modules for ghostty, zen, neovim, zellij, and niri keybinds/spawn-at-startup. AMD GPU + portal + polkit + gaming stack at the system level. VM builds; all daily-driver apps land.
5. ✅ Boot NixOS installer ISO on this box, generate hardware-config, `nixos-install`. Output connector is `DP-1` as predicted.
6. ⏳ Post-install iteration. Outstanding: switch Noctalia to `mkOutOfStoreSymlink` + seed `dotfiles/noctalia/settings.json`; wire a Noctalia user-template for nvim/zellij so the colorscheme tracks the bar preset (currently the catppuccin-mocha nvim scheme is a hard-coded best-fit, not generated from Matte-Candy).

## Commands

```
nix flake check                                                # validate flake (skip --no-build for full check)
nix flake update                                               # bump all inputs
nix fmt                                                        # alejandra formatter
sudo nixos-rebuild switch --flake ~/nixglass#nixglass          # main rebuild
nixos-rebuild build-vm --flake ~/nixglass#nixglass             # build VM
./result/bin/run-nixglass-vm                                   # boot VM (qemu)
home-manager switch --flake ~/nixglass#ihsen@nixglass          # home-only iteration
```
