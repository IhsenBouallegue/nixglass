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

      colorSchemes.predefinedScheme = "Catppuccin-Lavender";
    };
  };
}
