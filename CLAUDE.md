# nixglass

NixOS + flakes + Home Manager config. Migration target from Omarchy (Arch + Hyprland). Single-user developer workstation, 49" ultrawide (Samsung Odyssey G9, 5120x1440@240), AMD GPU.

## Status

Scaffolded from `Misterio77/nix-starter-configs#standard` (NixOS 25.11). Hostname `nixglass`, user `ihsen`. `flake check` passes. VM boots to mango (scroller layout, blur, matte-candy borders) with a Ghostty terminal and a Noctalia top bar (matte-candy palette). No zen / nvim modules yet.

**Compositor change:** initially picked niri for its scrollable tiling, but niri 26.04's blur is gated behind the new `ext-background-effect` protocol and most apps haven't opted in yet (ghostty 1.3.1 doesn't). Switched to **mango** (dwl-derived) which has built-in blur/shadows/animations and a `scroller` tag layout — same scrolling UX, simpler config (`blur = 1` and it works). Git history under the niri commits if we ever want to revisit.

`nixos/hardware-configuration.nix` is a placeholder. Regenerate at install time via `nixos-generate-config --root /mnt`.

## Topology — ONE host, not two

There is **one** `nixosSystem` named `nixglass`. The VM is **not** a separate host — it's the `.vmVariant` automatically derived from the same config.

```
# Build + run VM (throwaway test rig)
# On NixOS hosts:
nixos-rebuild build-vm --flake .#nixglass && ./result/bin/run-nixglass-vm

# On the current Arch host (no nixos-rebuild available):
nix build .#nixosConfigurations.nixglass.config.system.build.vm
nix run --impure github:nix-community/nixGL -- ./result/bin/run-nixglass-vm
# Don't delete nixglass.qcow2 between launches — see iteration workflow below.

# Bare-metal install (eventual)
# From NixOS installer ISO:
nixos-generate-config --root /mnt
# copy resulting hardware-configuration.nix into nixos/, commit
nixos-install --flake /mnt/etc/nixos#nixglass
```

### Iteration workflow (edit-on-host, rebuild-and-reboot VM)

The 9p share of this repo into the VM is **for browsing/inspection only** — do not run `nixos-rebuild` inside the VM against the shared path. Reason: the 9p mount unit (`home-ihsen-Documents-repos-nixglass.mount`) is part of `vmVariant`, not the base config. When `nixos-rebuild` inside the VM activates the base config, systemd unmounts the 9p share mid-activation, the path disappears, and subsequent rebuilds fail with "could not find a flake.nix". The activation also bails with exit 4 partway through. **Don't do it.**

The reliable workflow:

1. Edit any `.nix` file on the **host**.
2. On the **host**: `nix build .#nixosConfigurations.nixglass.config.system.build.vm` — typically seconds once the closure is cached.
3. Power-down the running VM (qemu **Machine → Power Down**) and re-launch with `nix run --impure github:nix-community/nixGL -- ./result/bin/run-nixglass-vm`.
4. The persistent qcow2 keeps user state across reboots, so noctalia config / shell history etc. survive.

For tiny CSS-only tweaks (noctalia colourscheme via its in-app GUI, or ghostty colours typed in a config file inside the VM), edit inside the VM, restart the app — no host rebuild needed. But for any change tracked by the flake, host-rebuild + VM reboot is the path.

Only delete `nixglass.qcow2` when you genuinely want a fresh install.

VM-specific overrides (qemu mem/disk, virgl `-device virtio-vga-gl`, SDL+GL display, autologin, throwaway password) go in a `virtualisation.vmVariant = { ... }` block inside `nixos/configuration.nix`. **Do not split into two hosts** — they would drift.

### Why `nix run nixGL` on the Arch host

Nix-built qemu has its own RPATH baked in and can't see Arch's `/usr/lib/libEGL.so.1`. Running it directly aborts in `epoxy_get_proc_address: Couldn't find current GLX or EGL context`. nixGL wraps the call and injects host GL drivers — required for any GL-using Nix binary on a non-NixOS host. Not needed once we boot into actual NixOS.

### qemu SDL controls (no menubar like GTK)

- **Ctrl+Alt+G** — release captured keyboard/mouse
- Close the SDL window or `pkill qemu-system-x86_64` to quit
- The display is SDL not GTK because qemu's GtkGLArea path fails on this Wayland host. SDL+GL works under nixGL.

## Target stack

| Layer | Tool | Notes |
|---|---|---|
| Compositor | **Mango** | dwl-fork with `scroller` tag layout (gives niri-like horizontal scrolling on the ultrawide), plus native blur, shadows, animations. Via `github:mangowm/mango`. Config in `~/.config/mango/config.conf`. Tags 1–9 instead of workspaces. |
| Bar + theming engine | **Noctalia** | Replaces waybar. Flake input `github:noctalia-dev/noctalia-shell`; not in nixpkgs. Add via `inputs.noctalia.homeModules.default`. PAM entry for lock screen is NOT auto-configured — add manually. |
| Terminal | Ghostty | Non-color config declarative; colors come from Noctalia. |
| Browser | Zen | Theming needs `toolkit.legacyUserProfileCustomizations.stylesheets = true` in about:config. |
| Editor | Neovim | Full config declarative. |
| Gaming | Steam + Lutris (Proton) | `programs.steam.enable = true`; `allowUnfree = true`. AMD is plug-and-play. |

## The Nix-vs-Noctalia ownership boundary (critical)

Two layers, do not mix:

- **Nix manages:** software install, all non-color config (keybinds, plugins, fonts, packages, niri config, nvim config).
- **Noctalia manages at runtime:** all color theming. Its Python template processor reads `~/.config/noctalia/colors.json` and writes themed config files for:
  - Ghostty, Zen (userChrome.css + userContent.css), GTK3/4, Qt → auto-themed (native templates). Mango colours are driven via our typed nix config (not noctalia templates).
  - **Neovim is NOT in the native list.** Use a colorscheme plugin (tokyonight/catppuccin) matched to the Noctalia preset, or write a user template in `~/.config/noctalia/user-templates.toml`.

### Current VM state (compromise during step 4)

We're temporarily declaring `programs.noctalia-shell.settings` via the home module, which means home-manager writes `~/.config/noctalia/settings.json` as a `/nix/store` symlink. Noctalia's runtime edits to settings.json are silently dropped (the file is read-only).

This is the **opposite** of the ownership boundary CLAUDE.md prescribes, but it's necessary because:

- Noctalia with empty settings registers no bar widgets and creates no layer-shell surface (`niri msg layers` returns empty).
- `mkOutOfStoreSymlink` to `${repo}/dotfiles/noctalia/` only resolves on the bare-metal host — the VM has no such path.

For now: iterate bar/widget changes by editing `home-manager/noctalia.nix` and rebuilding. The in-app settings GUI will appear to work but its writes vanish on next HM activation. **Revisit when moving to bare-metal** — at that point switch to mkOutOfStoreSymlink and seed `dotfiles/noctalia/settings.json` from the current declarative version as a starting point.

### The mkOutOfStoreSymlink rule

Noctalia writes back to its own config dir at runtime (`settings.json`, generated theme files). If Home Manager places those from `/nix/store` they are read-only and Noctalia silently fails to edit them.

**Fix:** mount `~/.config/noctalia` as a writable symlink into this repo, not a store path:

```nix
home.file.".config/noctalia".source =
  config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/Documents/repos/nixglass/dotfiles/noctalia";
```

The directory `dotfiles/noctalia/` is git-tracked (your custom `colorschemes/matte-candy.json` lives there), but Noctalia is free to edit `settings.json` and the generated files inside it. Declarative + GUI-editable.

Reference: https://github.com/noctalia-dev/noctalia-shell/issues/2214

### Things to NOT manage declaratively

- `~/.config/noctalia/settings.json` (Noctalia rewrites it — though we currently break this rule, see "Current VM state" above)
- Themed ghostty config, `gtk.css`, Qt color files, Zen `userChrome.css`/`userContent.css` — all auto-generated by Noctalia.

### Things to manage declaratively

- Mango config (via `wayland.windowManager.mango.settings` — flattened key/value pairs)
- ghostty config (including matte-candy palette — we don't go through Noctalia's template)
- nvim full config
- Custom Noctalia colorscheme JSON in `dotfiles/noctalia/colorschemes/` (static, read-only from Noctalia's POV)
- All packages, system services, fonts

## Reference: source config to port from

`~/Documents/repos/omarchy-customizer/` — the user's current Arch dotfile repo. Modular `install.sh` that symlinks configs into `~/.config/`. Port over:

- `configs/hypr/` → niri equivalent (different config language entirely — don't transliterate, translate)
- `configs/waybar/` → noctalia bar layout config
- `configs/ghostty/config` → non-color bits as nix module; colors come from Noctalia
- `configs/zellij/` → declarative via home-manager
- `configs/mako/` → noctalia notification handler
- `theme/matte-candy/colors.toml` → `dotfiles/noctalia/colorschemes/matte-candy.json`
- `packages.txt` → system packages list

The bambustudio/cursor/discord packages are unfree — `allowUnfree = true` is already set.

## Migration plan

1. ✅ Install Nix (Determinate official upstream installer) on the Arch host.
2. ✅ Scaffold flake from Misterio77 standard. Rename, fill FIXMEs.
3. ✅ Add niri-flake input + greetd autologin + vmVariant overrides. VM boots to empty niri session.
4. ⏳ Add noctalia input, plus home modules for ghostty, neovim, and niri keybinds/spawn-at-startup. Iterate via VM build until niri+noctalia+zen+ghostty+nvim all work.
5. ⏳ Boot NixOS installer ISO on this box, generate hardware-config, `nixos-install`.
6. ⏳ Iterate post-install for 1–2 weeks.

## Commands

```
nix flake check                                        # validate flake (skip --no-build for full check)
nix flake update                                       # bump all inputs
nix fmt                                                # alejandra formatter
nixos-rebuild build-vm --flake .#nixglass              # build VM
./result/bin/run-nixglass-vm                           # boot it (qemu)
home-manager switch --flake .#ihsen@nixglass           # standalone home-manager (for testing on Arch)
```
