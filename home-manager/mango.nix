{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  # Absolute store paths so mango can spawn before any user PATH is set up.
  ghostty = lib.getExe pkgs.ghostty;
  noctaliaLauncher = "noctalia-shell ipc call launcher toggle";
in {
  imports = [inputs.mango.hmModules.mango];

  wayland.windowManager.mango = {
    enable = true;
    systemd.enable = true;

    # autostart_sh runs once at compositor start; spawn the bar + a visible
    # terminal so we don't land on a blank workspace.
    autostart_sh = ''
      noctalia-shell &
      ${ghostty} &
    '';

    settings = {
      # ── Appearance: matte-candy + glass ───────────────────────────────
      # Border + colours (0xRRGGBBAA).
      borderpx = 2;
      focuscolor = "0xe65c5cff"; # matte-candy red
      bordercolor = "0x404040ff";
      rootcolor = "0x060c10ff";

      # Gaps — small inner, none outer (like the omarchy hyprland config).
      gappih = 4;
      gappiv = 4;
      gappoh = 0;
      gappov = 0;

      # Rounded corners + per-focus opacity.
      border_radius = 10;
      focused_opacity = 0.98;
      unfocused_opacity = 0.90;

      # Blur — the whole reason we left niri. blur_optimized=1 caches the
      # wallpaper layer so it's cheap; blur_layer=1 so the noctalia bar
      # also gets blurred.
      blur = 1;
      blur_layer = 1;
      blur_optimized = 1;
      blur_params_radius = 6;
      blur_params_num_passes = 3;
      blur_params_noise = 0.07;
      blur_params_brightness = 0.9;
      blur_params_contrast = 1.2;
      blur_params_saturation = 1.2;

      # Shadows — soft, slight downward offset.
      shadows = 1;
      shadows_size = 16;
      shadows_blur = 16;
      shadows_position_x = 0;
      shadows_position_y = 4;
      shadowscolor = "0x000000aa";

      # Animations — keep them snappy.
      animations = 1;
      animation_type_open = "slide";
      animation_type_close = "slide";
      animation_duration_open = 250;
      animation_duration_close = 250;

      # ── Tags use scroller layout (niri-like horizontal scrolling) ────
      tagrule = [
        "id:1,layout_name:scroller"
        "id:2,layout_name:scroller"
        "id:3,layout_name:scroller"
        "id:4,layout_name:scroller"
        "id:5,layout_name:scroller"
        "id:6,layout_name:scroller"
        "id:7,layout_name:scroller"
        "id:8,layout_name:scroller"
        "id:9,layout_name:scroller"
      ];

      # ── Keybindings ──────────────────────────────────────────────────
      # Format: "MOD[+MOD],KEY,ACTION[,ARG]"
      bind = [
        # Spawn
        "SUPER,Return,spawn,${ghostty}"
        "SUPER,Space,spawn,${noctaliaLauncher}"

        # Window state
        "SUPER,Q,killclient"
        "SUPER,F,togglefullscreen"
        "SUPER+SHIFT,F,togglefloating"
        "SUPER+SHIFT,E,quit"
        "SUPER,R,reload_config"

        # Focus
        "SUPER,Left,focusdir,left"
        "SUPER,Right,focusdir,right"
        "SUPER,Up,focusdir,up"
        "SUPER,Down,focusdir,down"
        "SUPER,H,focusdir,left"
        "SUPER,L,focusdir,right"
        "SUPER,K,focusdir,up"
        "SUPER,J,focusdir,down"

        # Move / swap with neighbour
        "SUPER+SHIFT,H,exchange_client,left"
        "SUPER+SHIFT,L,exchange_client,right"
        "SUPER+SHIFT,K,exchange_client,up"
        "SUPER+SHIFT,J,exchange_client,down"

        # Tags (mango uses tags not workspaces; map them like workspaces)
        "SUPER,1,view,1"
        "SUPER,2,view,2"
        "SUPER,3,view,3"
        "SUPER,4,view,4"
        "SUPER,5,view,5"
        "SUPER,6,view,6"
        "SUPER,7,view,7"
        "SUPER,8,view,8"
        "SUPER,9,view,9"

        "SUPER+SHIFT,1,tag,1"
        "SUPER+SHIFT,2,tag,2"
        "SUPER+SHIFT,3,tag,3"
        "SUPER+SHIFT,4,tag,4"
        "SUPER+SHIFT,5,tag,5"
        "SUPER+SHIFT,6,tag,6"
        "SUPER+SHIFT,7,tag,7"
        "SUPER+SHIFT,8,tag,8"
        "SUPER+SHIFT,9,tag,9"
      ];
    };
  };
}
