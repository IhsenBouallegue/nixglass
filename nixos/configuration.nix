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

  # Niri scrolling tiling compositor (the niri-flake nixosModule is wired in flake.nix).
  programs.niri.enable = true;

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

  # System-wide fonts. Ghostty's font-family reads from fontconfig, which only
  # sees fonts in fonts.packages or the user's HM font scope. System-wide is
  # simplest and ensures other apps (zen, noctalia later) see the same set.
  fonts.packages = with pkgs; [
    jetbrains-mono
  ];

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
      # TODO: Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
      extraGroups = ["wheel"];
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
