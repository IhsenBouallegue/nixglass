{
  config,
  lib,
  pkgs,
  ...
}: let
  # Absolute store path so niri can spawn even before any shell PATH is set up.
  ghostty = lib.getExe pkgs.ghostty;
in {
  programs.niri.settings = {
    input = {
      keyboard.xkb.layout = "us";
      touchpad = {
        tap = true;
        natural-scroll = true;
      };
    };

    # Something visible on boot — otherwise it's just gray + cursor.
    spawn-at-startup = [
      {command = [ghostty];}
    ];

    binds = with config.lib.niri.actions; {
      "Mod+Return".action = spawn ghostty;
      "Mod+Q".action = close-window;
      "Mod+F".action = fullscreen-window;
      "Mod+Shift+E".action = quit;

      # Focus — arrows and vim keys.
      "Mod+Left".action = focus-column-left;
      "Mod+Right".action = focus-column-right;
      "Mod+Up".action = focus-window-up;
      "Mod+Down".action = focus-window-down;
      "Mod+H".action = focus-column-left;
      "Mod+L".action = focus-column-right;
      "Mod+K".action = focus-window-up;
      "Mod+J".action = focus-window-down;

      # Move.
      "Mod+Shift+Left".action = move-column-left;
      "Mod+Shift+Right".action = move-column-right;
      "Mod+Shift+Up".action = move-window-up;
      "Mod+Shift+Down".action = move-window-down;
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+L".action = move-column-right;
      "Mod+Shift+K".action = move-window-up;
      "Mod+Shift+J".action = move-window-down;

      # Workspaces.
      "Mod+1".action = focus-workspace 1;
      "Mod+2".action = focus-workspace 2;
      "Mod+3".action = focus-workspace 3;
      "Mod+4".action = focus-workspace 4;
      "Mod+5".action = focus-workspace 5;
      "Mod+6".action = focus-workspace 6;
      "Mod+7".action = focus-workspace 7;
      "Mod+8".action = focus-workspace 8;
      "Mod+9".action = focus-workspace 9;

      # move-column-to-workspace by index isn't exposed in niri-flake's typed
      # actions yet (only -down/-up). Use Mod+Shift+J/K to move between
      # workspaces, or revisit when noctalia is in.
    };
  };
}
