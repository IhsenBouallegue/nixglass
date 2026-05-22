# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # inputs.self.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      inputs.self.overlays.additions
      inputs.self.overlays.modifications
      inputs.self.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix = {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";
      # Dedupe identical store paths on each build — small CPU cost at build
      # time for noticeable disk savings as the store grows.
      auto-optimise-store = true;
    };
    # Opinionated: disable channels
    channel.enable = false;
  };

  # nh is the modern rebuild wrapper: parallel builds, generation diff via nvd,
  # nicer streaming output via nix-output-monitor (both pulled in below). It
  # also owns the gc story via `nh clean` — keeps the last 5 gens and prunes
  # anything older than 30 days, weekly. Run with `nh os switch` (defaults to
  # the flake at `programs.nh.flake`).
  programs.nh = {
    enable = true;
    flake = "/home/ihsen/nixglass";
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 30d --keep 5";
    };
  };

  networking.hostName = "nixglass";

  # Bootloader assumptions: hardware-configuration.nix (regenerated at install
  # time by nixos-generate-config) will declare boot.loader.* for this box —
  # typically systemd-boot on an EFI system. Nothing to set here until then.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Cap kept generations so /boot doesn't fill up over time — once it does,
  # the next switch fails partway through with a cryptic ENOSPC and you have
  # to dig out a rescue shell to clean it. 20 is plenty of rollback runway.
  boot.loader.systemd-boot.configurationLimit = 20;
  # Wipe /tmp on boot so leftover build dirs from old nix builds, dropped
  # editor swap files, etc. don't accumulate across reboots.
  boot.tmp.cleanOnBoot = true;
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  # AMD GPU stack. Harmless on the VM (virtio-vga-gl ignores it), required
  # on bare metal for Vulkan + 32-bit Steam.
  boot.initrd.kernelModules = ["amdgpu"];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [vulkan-tools libva-utils];
  };

  # Wayland glue. Portal backends for the wlroots-family compositor (mango):
  #   - gtk: file chooser, settings, app chooser (fallback for everything)
  #   - wlr: screenshot, screencast (wlroots-specific protocols)
  # The gnome backend used to be listed here (back when niri was the daily
  # driver), but with no gnome-session running, xdg-desktop-portal blocks for
  # ~50s on every GTK4 app launch trying to start its D-Bus name. That's the
  # "Ghostty takes a minute to open" symptom — see journalctl --user -u
  # xdg-desktop-portal for the "StartServiceByName ... gnome: Timeout" errors.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
    config.common = {
      default = ["gtk"];
      "org.freedesktop.impl.portal.Screenshot" = ["wlr"];
      "org.freedesktop.impl.portal.ScreenCast" = ["wlr"];
    };
  };
  security.polkit.enable = true;
  programs.dconf.enable = true;
  services.gvfs.enable = true;

  # Gaming stack (target stack in CLAUDE.md). gamemode enables CPU governor
  # tweaks for foreground games; no extra group membership needed in 1.6+.
  # gamescope is the SteamOS-style nested compositor — useful on the G9 for
  # locking a game to a target res/refresh independent of the desktop
  # (Steam launch option: `gamescope -W 5120 -H 1440 -r 240 -- %command%`).
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  # Autologin to mango via greetd. No greeter UI — initial_session fires
  # automatically. Single-user workstation by design.
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.mangowc}/bin/mango";
        user = "ihsen";
      };
    };
  };

  # Sound — pipewire is the standard pick.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Services DMS talks to for status bar widgets (network, battery,
  # power profile, bluetooth). The VM has no real hardware for most of these
  # but enabling them is harmless and matches the bare-metal target.
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # SSD weekly TRIM — keeps write performance healthy over time.
  services.fstrim.enable = true;
  # UEFI/SSD/peripheral firmware updates via `fwupdmgr refresh && fwupdmgr update`.
  services.fwupd.enable = true;

  # mDNS / Avahi so `.local` hostnames resolve through the normal libc
  # resolver path. `nssmdns4` wires `mdns_minimal` into nsswitch;
  # `openFirewall` lets UDP 5353 in for responses. We don't publish our
  # own hostname (default).
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Hard-pin the UGREEN NAS's IPv4. mDNS only returns its IPv6 (`Eveline.local`
  # advertises an AAAA but no A record), and the NFS export ACL only allows
  # 192.168.0.0/24 — so we'd be unmountable via the mDNS name. Stable IP
  # assumes a DHCP reservation on the router; bump this value (or move it to
  # a static IP on the NAS itself) if the lease ever changes.
  networking.hosts = {
    "192.168.0.86" = ["eveline"];
  };

  # UGREEN NAS data share. UGOS Pro only exposes NFSv3 (v4 mounts get
  # "No such file or directory" from the server — the pseudoroot isn't wired
  # up), so we pin nfsvers=3 explicitly. systemd-automount handles lazy
  # mount on first touch and survives the NAS being offline at boot
  # (without it, a missing NFS server drops the host into emergency mode).
  # `idle-timeout` unmounts after 10 min of inactivity; `soft` returns EIO
  # instead of hanging procs if the NAS goes away mid-session — acceptable
  # for a media/docs store, switch to `hard` if you ever rely on it for
  # write-critical data. NixOS sees `nfs` in fsType and pulls in nfs-utils
  # + rpc-statd (needed for v3 locking) automatically.
  fileSystems."/mnt/data" = {
    device = "eveline:/volume1/data";
    fsType = "nfs";
    options = [
      "nfsvers=3"
      "noatime"
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10s"
      "soft"
      "timeo=150"
      "retrans=3"
    ];
  };

  # System-wide fonts. Ghostty's font-family reads from fontconfig, which only
  # sees fonts in fonts.packages or the user's HM font scope. System-wide is
  # simplest and ensures other apps (zen, dms) see the same set.
  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.caskaydia-cove
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # Tell Electron apps (VS Code, Discord, Bitwarden, Cursor) to run on
  # Wayland natively instead of through XWayland — nixpkgs's electron
  # wrapper reads this and passes --ozone-platform=wayland +
  # --enable-features=WaylandWindowDecorations,UseOzonePlatform. Without
  # this, fonts render slightly fuzzy on wlroots compositors (XWayland
  # bitmap-scales rather than letting the toolkit do crisp HiDPI/text).
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # System-wide packages: icon theme for GTK/Qt apps, plus nh's helpers
  # (nom = streaming build output, nvd = generation diff).
  environment.systemPackages = with pkgs; [
    papirus-icon-theme
    nix-output-monitor
    nvd
    # mango (dwl-fork wlroots compositor) — the autologin session. Pulled
    # from nixpkgs-unstable via the `modifications` overlay.
    mangowc
  ];

  # Crisp font rendering on the G9 (110 DPI, RGB subpixel order). "slight"
  # hinting preserves shape without the chunky blockiness of "full"; RGB
  # subpixel + the default lcdfilter is the standard recipe for modern LCDs.
  fonts.fontconfig = {
    antialias = true;
    hinting = {
      enable = true;
      style = "slight";
      autohint = false;
    };
    subpixel = {
      rgba = "rgb";
      lcdfilter = "default";
    };
  };

  # VM-only overrides for `nixos-rebuild build-vm --flake .#nixglass`.
  # The vmVariant is automatically derived from this same host — no separate hostname.
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      diskSize = 8192;
      qemu.options = [
        # virgl 3D acceleration so mango (a wlroots compositor) actually renders.
        "-device virtio-vga-gl"
        # GTK display gives a proper window with a Machine/View menubar
        # (Machine -> Power Down, etc.) — much better UX than SDL.
        # Requires nixGL on non-NixOS hosts so qemu can resolve host EGL.
        "-display gtk,gl=on"
      ];
    };
    # Throwaway VM password — autologin via greetd means this is rarely typed,
    # but keep something predictable for sudo / tty fallback.
    # mkForce because the parent host already sets initialPassword.
    users.users.ihsen.initialPassword = lib.mkForce "vm";
    # Don't bother with SSH key-only auth inside a throwaway VM.
    services.openssh.settings.PasswordAuthentication = lib.mkForce true;
  };

  users.users = {
    ihsen = {
      # TODO: You can set an initial password for your user.
      # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      initialPassword = "correcthorsebatterystaple";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID4+qeRKKgYLGC86DwKww7i09dlqxH/elJSI+44dkz3d ihsen.bouallegue@proton.me"
      ];
      extraGroups = ["wheel" "networkmanager" "video"];
    };
  };

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    settings = {
      # Opinionated: forbid root login through SSH.
      PermitRootLogin = "no";
      # Opinionated: use keys only.
      # Remove if you want to SSH using passwords
      PasswordAuthentication = false;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
