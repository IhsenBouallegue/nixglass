# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./niri.nix
    ./ghostty.nix
    ./noctalia.nix
    ./zen.nix
    ./nvim.nix
    ./zellij.nix
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

  home = {
    username = "ihsen";
    homeDirectory = "/home/ihsen";
  };

  home.packages = with pkgs; [
    # Dev tooling / CLI
    claude-code
    jq
    yq
    sqlite
    ncdu
    ripgrep
    fd
    zenity
    gh

    # Wayland / niri helpers (referenced by niri keybinds: screenshot, audio,
    # brightness, media keys, clipboard).
    grim
    slurp
    wl-clipboard
    brightnessctl
    playerctl
    wireplumber # provides wpctl for volume

    # Polkit agent — niri spawns this at startup so GUI sudo prompts work.
    lxqt.lxqt-policykit

    # Apps
    bitwarden-desktop
    anki
    discord
    code-cursor
    bambu-studio
    spotify

    # Gaming user-side. Steam itself is enabled at the system level.
    # Pull lutris from unstable — nixpkgs-25.11 is stuck on 0.5.19 while
    # upstream is on 0.5.22 (Feb 2026). Drop the override when 25.11 catches up.
    unstablePkgs.lutris
    winetricks
    mangohud
  ];

  # Sudo askpass — lets graphical programs (like Claude Code) prompt for password.
  # BROWSER is set automatically by the zen-browser module's setAsDefaultBrowser.
  home.sessionVariables.SUDO_ASKPASS = pkgs.writeShellScript "askpass" ''
    ${pkgs.zenity}/bin/zenity --password --title "sudo password"
  '';

  # Declarative URL/mime defaults — Zen's setAsDefaultBrowser sets these at
  # runtime, but pinning them here means a fresh machine has them on first boot
  # too. The desktop file name follows the zen-browser-flake variant (twilight).
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Web browser handlers
      "text/html" = "zen-twilight.desktop";
      "application/xhtml+xml" = "zen-twilight.desktop";
      "application/x-extension-htm" = "zen-twilight.desktop";
      "application/x-extension-html" = "zen-twilight.desktop";
      "application/x-extension-shtml" = "zen-twilight.desktop";
      "application/x-extension-xhtml" = "zen-twilight.desktop";
      "application/x-extension-xht" = "zen-twilight.desktop";
      "x-scheme-handler/http" = "zen-twilight.desktop";
      "x-scheme-handler/https" = "zen-twilight.desktop";
      "x-scheme-handler/about" = "zen-twilight.desktop";
      "x-scheme-handler/unknown" = "zen-twilight.desktop";
      "x-scheme-handler/chrome" = "zen-twilight.desktop";

      # Claude Code deep-link handler (claude-cli:// URLs from shared conversations)
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
  };

  # Wallpapers — ported from omarchy-customizer's matte-candy/backgrounds.
  # Noctalia's WallpaperService defaults to ~/Pictures/Wallpapers, so dropping
  # them there is enough to make them show up; the noctalia module also pins
  # `wallpaper.directory` explicitly so a different HOME wouldn't break things.
  # Whole-directory mount means new files added to dotfiles/wallpapers/ flow
  # through on the next rebuild.
  home.file."Pictures/Wallpapers".source = ../dotfiles/wallpapers;

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    settings.user = {
      name = "Ihsen Bouallegue";
      email = "ihsen.bouallegue@proton.me";
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.11";
}
