{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  # Absolute store paths so niri can spawn even before any shell PATH is set up.
  ghostty = lib.getExe pkgs.ghostty;
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  brightnessctl = lib.getExe pkgs.brightnessctl;
  playerctl = lib.getExe pkgs.playerctl;
  polkitAgent = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
  # niri-flake exposes xwayland-satellite-unstable as a package output, not
  # via an overlay — reference it through the flake input directly.
  xwaylandSatellite = inputs.niri.packages.${pkgs.system}.xwayland-satellite-unstable;
in {
  programs.niri.settings = {
    input = {
      keyboard.xkb.layout = "us";
      touchpad = {
        tap = true;
        natural-scroll = true;
      };
    };

    # Xwayland for X11-only apps — required by most Steam games (the Steam
    # client itself runs native Wayland, but the games it launches usually
    # still want X11). Niri spawns xwayland-satellite on session start and
    # exposes a DISPLAY for X clients. Requires niri-unstable (already pinned
    # in nixos/configuration.nix).
    xwayland-satellite.path = lib.getExe xwaylandSatellite;

    # Force server-side decorations so windows are flush rectangles niri
    # can draw its own border + rounded clip around. Most GTK/Qt apps
    # honour this; the ones that don't will still show their own titlebar.
    prefer-no-csd = true;

    # Matte-candy window styling. niri does NOT support background blur in
    # any generally-useful form (ghostty 1.3.x doesn't implement the
    # ext-background-effect protocol it would need), so this is the "matte"
    # half of "matte glass" — rounded corners, soft drop shadow, accent-red
    # focus border, gentle gaps. App transparency (e.g. ghostty's 0.92 alpha)
    # plus the wallpaper showing through provides the glow.
    layout = {
      gaps = 10;
      border = {
        enable = true;
        width = 2;
        active.color = "#e65c5cff"; # matte-candy accent (red)
        inactive.color = "#404040ff";
      };
      focus-ring = {
        enable = true;
        width = 1;
        active.color = "#ffcc66ff"; # matte-candy cursor (yellow), tight ring inside the border
        inactive.color = "#26262600";
      };
      shadow = {
        enable = true;
        softness = 20;
        spread = 4;
        offset = {
          x = 0;
          y = 6;
        };
        color = "#00000080";
      };
    };

    # Rounded corners are applied per-window (niri's model). The wildcard
    # match catches everything; clip-to-geometry trims app content to the
    # rounded shape so the corners aren't square inside the border.
    window-rules = [
      {
        geometry-corner-radius = let
          r = 10.0;
        in {
          top-left = r;
          top-right = r;
          bottom-left = r;
          bottom-right = r;
        };
        clip-to-geometry = true;
      }
    ];

    # 49" Samsung Odyssey G9 — 5120x1440 @ 240 Hz. Niri matches outputs by
    # connector name; on this box the G9 typically shows up as DP-1 (single
    # DisplayPort cable). If `niri msg outputs` reports a different name after
    # install, rename this stanza — extras with no matching connector are
    # silently ignored, so leaving it here is safe on the VM too.
    outputs."DP-1" = {
      mode = {
        width = 5120;
        height = 1440;
        refresh = 239.761;
      };
      variable-refresh-rate = true;
      scale = 1.0;
    };

    # Something visible on boot — otherwise it's just gray + cursor.
    # noctalia-shell handles the bar, wallpaper, launcher, notifications.
    # lxqt-policykit-agent is the GUI prompt for any pkexec call.
    spawn-at-startup = [
      {command = [polkitAgent];}
      {command = ["noctalia-shell"];}
      {command = [ghostty];}
    ];

    binds = with config.lib.niri.actions; {
      "Mod+Return".action = spawn ghostty;
      "Mod+Q".action = close-window;
      "Mod+F".action = fullscreen-window;
      "Mod+Shift+E".action = quit;

      # Noctalia launcher (IPC toggle, so noctalia must already be running).
      "Mod+Space".action = spawn "noctalia-shell" "ipc" "call" "launcher" "toggle";

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

      # Screenshot — Win+Shift+S, matching the Windows shortcut. niri's
      # built-in interactive selector saves to ~/Pictures and copies to
      # the wl-clipboard. niri-flake's typed `screenshot` action requires
      # an argument we don't need to think about — calling niri's own CLI
      # is shorter and works for all three variants.
      "Mod+Shift+S".action = spawn "niri" "msg" "action" "screenshot";
      "Print".action = spawn "niri" "msg" "action" "screenshot";
      "Mod+Print".action = spawn "niri" "msg" "action" "screenshot-screen";
      "Ctrl+Print".action = spawn "niri" "msg" "action" "screenshot-window";

      # Audio (pipewire via wpctl).
      "XF86AudioRaiseVolume" = {
        action = spawn wpctl "set-volume" "-l" "1.5" "@DEFAULT_AUDIO_SINK@" "5%+";
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action = spawn wpctl "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-";
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action = spawn wpctl "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        action = spawn wpctl "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle";
        allow-when-locked = true;
      };

      # Brightness (no internal display on this box, but harmless when the
      # G9's USB-side brightness control is wired; useful if a laptop ever
      # joins this config).
      "XF86MonBrightnessUp".action = spawn brightnessctl "set" "5%+";
      "XF86MonBrightnessDown".action = spawn brightnessctl "set" "5%-";

      # Media keys (playerctl talks MPRIS to whatever is playing).
      "XF86AudioPlay".action = spawn playerctl "play-pause";
      "XF86AudioPause".action = spawn playerctl "play-pause";
      "XF86AudioNext".action = spawn playerctl "next";
      "XF86AudioPrev".action = spawn playerctl "previous";

      # Lock screen via Noctalia IPC. Mod+Shift+L is taken by move-column-right.
      "Mod+Ctrl+L".action = spawn "noctalia-shell" "ipc" "call" "lockScreen" "toggle";
    };
  };
}
