{
  config,
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.noctalia.homeModules.default];

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
      bar = {
        density = "default";
        position = "top";
        barType = "floating";
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

      # Use a custom colorscheme instead of any predefined one.
      colorSchemes = {
        darkMode = true;
        useWallpaperColors = false;
      };
    };

    # Matte-candy palette mapped onto noctalia's Material-You-ish color
    # roles. Same hex values as the Ayaka palette in
    # ~/Documents/repos/omarchy-customizer/theme/matte-candy/colors.toml,
    # mapped: primary=blue, secondary=purple, tertiary=cyan, error=red(accent).
    colors = {
      mPrimary = "#6699ff";
      mOnPrimary = "#060c10";
      mSecondary = "#cc66cc";
      mOnSecondary = "#060c10";
      mTertiary = "#66cccc";
      mOnTertiary = "#060c10";
      mError = "#e65c5c";
      mOnError = "#060c10";
      mSurface = "#060c10";
      mOnSurface = "#e6e6e6";
      mSurfaceVariant = "#262626";
      mOnSurfaceVariant = "#b3b3b3";
      mOutline = "#404040";
      mShadow = "#000000";
      mHover = "#ffcc66";
      mOnHover = "#060c10";
    };
  };
}
