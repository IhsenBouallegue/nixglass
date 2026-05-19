{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.noctalia.homeModules.default];

  # Custom colorscheme ported from omarchy-customizer's theme/matte-candy.
  # Noctalia's ColorSchemeService scans
  # ~/.config/noctalia/colorschemes/<Name>/<Name>.json (subdir layout, not
  # flat) — see Services/Theming/ColorSchemeService.qml in the noctalia
  # source. The `predefinedScheme` setting below is the basename, "Matte-Candy".
  xdg.configFile."noctalia/colorschemes/Matte-Candy/Matte-Candy.json".source =
    ../dotfiles/noctalia/colorschemes/Matte-Candy/Matte-Candy.json;

  programs.noctalia-shell = {
    enable = true;
    # Noctalia's default settings have no widgets configured, so no bar
    # surface is created and `niri msg layers` returns empty. The bar only
    # appears once you declare what goes on it.
    #
    # Note: home-manager writes this file into /nix/store, which means
    # noctalia cannot edit it back at runtime (CLAUDE.md's "ownership
    # boundary" problem). For now we accept that trade-off — iterate via
    # nix-rebuild instead of the in-app settings GUI. Revisit when we
    # move to bare-metal and can use mkOutOfStoreSymlink properly.
    settings = {
      # Pin to the current schema so noctalia skips its startup migrations.
      # Without this, the HM-managed settings.json (which has no version
      # field) is treated as v0 and 25+ migrations run on every start,
      # several of which silently overwrite fields — Migration45 in
      # particular clobbers `barType` back to "simple" because the legacy
      # `bar.floating` field isn't present. Bump when noctalia ships a new
      # Migration<N>.qml past 59; check Commons/Settings.qml in the
      # noctalia-shell store output. Long-term fix: mkOutOfStoreSymlink
      # (see CLAUDE.md "Outstanding").
      settingsVersion = 59;

      bar = {
        density = "compact";
        position = "top";
        barType = "simple";
        showCapsule = true;
        widgets = {
          left = [
            {id = "Launcher";}
            {
              id = "Clock";
              formatHorizontal = "HH:mm ddd, MMM dd";
              useMonospacedFont = true;
            }
            {id = "SystemMonitor";}
            {id = "ActiveWindow";}
            {id = "MediaMini";}
          ];
          center = [
            {
              id = "Workspace";
              hideUnoccupied = false;
              labelMode = "index";
            }
          ];
          right = [
            {id = "Tray";}
            {id = "NotificationHistory";}
            {id = "Volume";}
            {
              id = "ControlCenter";
              useDistroLogo = false;
              icon = "noctalia";
            }
          ];
        };
      };

      colorSchemes = {
        predefinedScheme = "Matte-Candy";
        # Don't auto-derive colors from the wallpaper — that overrides our
        # custom scheme on every wallpaper change.
        useWallpaperColors = false;
        darkMode = true;
      };

      # Wallpapers live in ~/Pictures/Wallpapers (mounted from
      # dotfiles/wallpapers via home.file in home.nix). `automationEnabled`
      # + alphabetical mode rotates through them every 10 minutes for a
      # screensaver vibe; flip to "single" if you settle on one.
      wallpaper = {
        enabled = true;
        directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
        setWallpaperOnAllMonitors = true;
        fillMode = "crop";
        automationEnabled = true;
        wallpaperChangeMode = "alphabetical";
        randomIntervalSec = 600;
        transitionDuration = 1500;
      };
    };
  };
}
