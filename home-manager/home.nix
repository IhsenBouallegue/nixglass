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
    ./mango.nix
    ./ghostty.nix
    ./dms.nix
    ./zen.nix
    ./vscode.nix
    ./nvim.nix
    ./zellij.nix
    ./workspaces.nix
    ./fuzzel.nix
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

    gcc
    gnumake

    # Wayland helpers used by mango keybinds and DMS (screenshot, audio,
    # brightness, media keys, clipboard).
    grim
    slurp
    swappy # screenshot annotation editor (also dms's default editor)
    wl-clipboard
    brightnessctl
    playerctl
    wireplumber # provides wpctl for volume

    # Polkit agent — mango spawns this at startup so GUI sudo prompts work.
    lxqt.lxqt-policykit

    # Terminals
    foot # trial alongside ghostty — minimalist Wayland-native terminal

    # Apps
    bitwarden-desktop
    anki
    discord
    code-cursor
    bambu-studio
    spotify
    chromium

    # Gaming user-side. Steam itself is enabled at the system level.
    # lutris/zellij come from unstable via the inherit overlay in
    # overlays/default.nix — nixpkgs-25.11 lags upstream. Drop the inherits
    # when stable catches up.
    lutris
    winetricks
    mangohud
    protonup-qt # GUI to install/manage GE-Proton, UMU-Proton, Luxtorpeda
  ];

  # Sudo askpass — lets graphical programs (like Claude Code) prompt for password.
  # BROWSER is set automatically by the zen-browser module's setAsDefaultBrowser.
  home.sessionVariables.SUDO_ASKPASS = pkgs.writeShellScript "askpass" ''
    ${pkgs.zenity}/bin/zenity --password --title "sudo password"
  '';

  # Cursor theme — sets XCURSOR_THEME/SIZE for Wayland (mango reads these on
  # session start), the GTK cursor-theme-name, and the Qt cursor. DMS's
  # cursorSettings.theme = "System Default" follows XCURSOR_THEME. Size kept
  # in lockstep with mango's `cursor_size=24` in home-manager/mango.nix.
  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Icon theme — Adwaita (the freedesktop default) is missing entries for
  # Zen, Foot, Bitwarden, Neovim, NixOS-Manual, etc., so DMS's spotlight
  # falls back to colored letter badges. Papirus-Dark covers the long
  # tail. `gtk.iconTheme` writes gsettings + gtk-3.0/settings.ini for GTK
  # apps; the GTK_ICON_THEME / QT_ICON_THEME env vars cover Qt apps
  # (including DMS's quickshell-based spotlight).
  # GTK theme. adw-gtk3 ports libadwaita's look back to GTK3 so zenity,
  # nautilus, file-pickers etc. match the dark surface. Accent overrides
  # below recolour focus rings / buttons / progress bars to the matte-candy
  # coral so the askpass dialog and any GTK file pickers brand consistently
  # with mango/ghostty/DMS.
  gtk = let
    p = import ./themes/matte-candy.nix;
    # GTK3 (zenity, gtk3 file pickers) reads @theme_selected_bg_color /
    # @theme_selected_fg_color for selection + focus rings. GTK4 /
    # libadwaita reads @accent_bg_color / @accent_color. Override both
    # so the accent lands consistently regardless of toolkit version.
    accentCss = ''
      @define-color accent_bg_color ${p.accent};
      @define-color accent_color ${p.accent};
      @define-color accent_fg_color #ffffff;
      @define-color theme_selected_bg_color ${p.accent};
      @define-color theme_selected_fg_color #ffffff;
      @define-color theme_unfocused_selected_bg_color ${p.accent};
      @define-color theme_unfocused_selected_fg_color #ffffff;
      @define-color focus_border_color ${p.accent};
      @define-color borders ${p.color8};
      @define-color unfocused_borders ${p.color8};
      entry:focus:focus, entry:focus-within:focus-within {
        border-color: ${p.accent};
        box-shadow: inset 0 0 0 2px ${p.accent};
        outline-color: ${p.accent};
      }
      button:focus:focus, button:focus-visible:focus-visible {
        outline-color: ${p.accent};
        border-color: ${p.accent};
      }
    '';
  in {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraCss = accentCss;
    gtk4.extraCss = accentCss;
  };

  home.sessionVariables = {
    GTK_ICON_THEME = "Papirus-Dark";
    QT_ICON_THEME = "Papirus-Dark";
  };

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
  # New files dropped into dotfiles/wallpapers/ flow through on the next
  # rebuild.
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

  # Bash is HM-managed so the integration hooks below (direnv, zoxide, fzf,
  # eza aliases) attach themselves to ~/.bashrc. We had no prior bashrc, so
  # there's nothing to preserve — start from HM defaults.
  programs.bash = {
    enable = true;
    shellAliases = {
      cx = "claude --dangerously-skip-permissions";
    };
    initExtra = ''
      eval "$(${pkgs.mise}/bin/mise activate bash)"
    '';
  };

  # Minimal one-line prompt: directory + git branch/status + arrow.
  # Bash integration auto-attaches via HM (sources init at end of ~/.bashrc).
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$character";
      # Coral on success and error — both pop with the primary accent.
      # Directory uses cosmic blue (secondary). Branch/status are gray
      # so the prompt resolves to "two colours + neutral text".
      character = {
        success_symbol = "[❯](bold red)";
        error_symbol = "[❯](bold red)";
      };
      directory = {
        style = "bold blue";
        truncation_length = 3;
        truncate_to_repo = false;
      };
      git_branch = {
        symbol = " ";
        style = "bold white";
        format = "[$symbol$branch]($style) ";
      };
      git_status = {
        style = "bold white";
      };
    };
  };

  # Per-project nix shells: drop an `.envrc` with `use flake` and the shell
  # is loaded automatically when you `cd` in. nix-direnv adds caching so the
  # eval isn't re-run on every cd.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Modern CLI replacements. All wire into bash via their HM modules (no
  # manual aliasing needed): `z <dir>` for zoxide, `Ctrl-R` for fzf history,
  # `cat`-as-bat with syntax highlighting, `eza` (with --git aliases).
  programs.zoxide.enable = true;
  programs.fzf.enable = true;
  programs.bat.enable = true;
  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.11";
}
