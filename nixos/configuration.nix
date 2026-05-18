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
    };
    # Opinionated: disable channels
    channel.enable = false;
  };

  networking.hostName = "nixglass";

  # Bootloader assumptions: hardware-configuration.nix (regenerated at install
  # time by nixos-generate-config) will declare boot.loader.* for this box —
  # typically systemd-boot on an EFI system. Nothing to set here until then.

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  # Niri scrolling tiling compositor (the niri-flake nixosModule is wired in flake.nix).
  # Pin to niri-unstable so we get ext-background-effect support (blur via
  # the Wayland staging protocol). niri-stable v25.08 predates that.
  programs.niri.enable = true;
  programs.niri.package = inputs.niri.packages.${pkgs.system}.niri-unstable;

  # AMD GPU stack. Harmless on the VM (virtio-vga-gl ignores it), required
  # on bare metal for Vulkan + 32-bit Steam.
  boot.initrd.kernelModules = ["amdgpu"];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [vulkan-tools libva-utils];
  };

  # Wayland glue.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config.niri.default = ["gnome" "gtk"];
  };
  security.polkit.enable = true;
  programs.dconf.enable = true;
  services.gvfs.enable = true;

  # PAM entry for Noctalia's lock screen — without this, the lock UI can't
  # authenticate and you get stuck on it. See CLAUDE.md.
  security.pam.services.noctalia-lock = {};

  # Gaming stack (target stack in CLAUDE.md). gamemode enables CPU governor
  # tweaks for foreground games; no extra group membership needed in 1.6+.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  programs.gamemode.enable = true;

  # Autologin to niri via greetd. No greeter UI — initial_session fires automatically.
  # Bare metal and VM both autologin; throwaway by design for a single-user workstation.
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "ihsen";
      };
    };
  };

  # Sound — niri itself doesn't pull this in. Pipewire is the standard pick.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Services Noctalia talks to for status bar widgets (network, battery,
  # power profile, bluetooth). The VM has no real hardware for most of these
  # but enabling them is harmless and matches the bare-metal target.
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # System-wide fonts. Ghostty's font-family reads from fontconfig, which only
  # sees fonts in fonts.packages or the user's HM font scope. System-wide is
  # simplest and ensures other apps (zen, noctalia later) see the same set.
  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.caskaydia-cove
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # Icon theme available to GTK/Qt apps system-wide.
  environment.systemPackages = with pkgs; [papirus-icon-theme];

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
        # virgl 3D acceleration so niri (a wayland compositor) actually renders.
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
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
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
