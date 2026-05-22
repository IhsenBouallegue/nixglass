{
  config,
  lib,
  pkgs,
  ...
}: let
  # Use the same Ghostty home-manager configures (upstream flake HEAD), not
  # nixpkgs stable. Mixing the two binaries causes a slow-start collision:
  # the HM-built one registers on D-Bus with --gtk-single-instance=true while
  # `pkgs.ghostty` (1.3.1) launches with --gtk-single-instance=false, and the
  # two app-id paths fight on every spawn.
  ghosttyPkg = config.programs.ghostty.package;
  palette = import ./themes/matte-candy.nix;
  # mango wants 0xRRGGBBaa; palette is #RRGGBB. Strip hash, append alpha.
  mangoHex = hex: alpha: "0x" + (lib.removePrefix "#" hex) + alpha;
in {
  # mango (dwl-fork wlroots compositor) — the daily-driver compositor,
  # launched by greetd autologin (see nixos/configuration.nix).
  #
  # mango is minimalist by design: no bar, no launcher, no wallpaper out of
  # the box. DankMaterialShell (DMS) provides all of that; the
  # `exec-once=dms run` line below brings it up with the session.
  #
  # mango reads ~/.config/mango/config.conf if present (fully replaces the
  # store's /etc/mango/config.conf — no merge; src/config/parse_config.h
  # in upstream confirms this), and runs `exec-once=` lines from it on
  # session start.

  # Full mango config, derived from the upstream default
  # (https://github.com/mangowm/mango/blob/main/assets/config.conf) with
  # three deltas:
  #   - `bind=Alt,Return,spawn,...` → ghostty (was foot)
  #   - `bind=Alt,space,spawn,...` → DMS spotlight IPC (was rofi)
  #   - `exec-once=dms run` so the bar/launcher/notifications start with
  #     the session.
  # Bump in lockstep when mango ships breaking config changes.
  home.file.".config/mango/config.conf".text = ''
    # More option see https://github.com/DreamMaoMao/mango/wiki/

    # Window effect — blur on both windows AND layer-shell surfaces. DMS's
    # quickshell-based bar/launcher/modals draw transparent pixels only
    # where the visible widget is (unlike Noctalia, whose bar surface
    # extended past the widget and produced a blurred strip behind it).
    # To make blur visible inside DMS surfaces, toggle Settings →
    # Personalization → Theme & Colors → Background Blur in the DMS GUI
    # and lower the widget opacity. Surgical exclusion if needed:
    #   layerrule=noblur:1,layer_name:dms:<namespace>
    # See https://mangowm.github.io/docs/visuals/effects/ and
    # https://danklinux.com/docs/dankmaterialshell/layers.
    blur=1
    blur_layer=1
    # blur_optimized=0 (was 1): scenefx's "optimized" blur path
    # pre-renders into a cached buffer (typically just the wallpaper) and
    # reuses it for every blurred surface — so notifications/popups blur
    # the wallpaper but ignore the windows underneath. Disabling forces
    # mango to compute blur from the live composited backdrop each frame,
    # which captures actual window contents. Higher GPU cost; fine on
    # this AMD stack.
    blur_optimized=0
    blur_params_num_passes = 2
    blur_params_radius = 5
    blur_params_noise = 0.02
    blur_params_brightness = 0.9
    blur_params_contrast = 0.9
    blur_params_saturation = 1.2

    shadows = 0
    layer_shadows = 0
    shadow_only_floating = 1
    shadows_size = 10
    shadows_blur = 15
    shadows_position_x = 0
    shadows_position_y = 0
    shadowscolor= 0x000000ff

    border_radius=6
    no_radius_when_single=0
    focused_opacity=1.0
    unfocused_opacity=0.85

    # Animation Configuration(support type:zoom,slide)
    animations=1
    layer_animations=1
    animation_type_open=slide
    animation_type_close=slide
    animation_fade_in=1
    animation_fade_out=1
    tag_animation_direction=1
    zoom_initial_ratio=0.4
    zoom_end_ratio=0.8
    fadein_begin_opacity=0.5
    fadeout_begin_opacity=0.8
    animation_duration_move=500
    animation_duration_open=400
    animation_duration_tag=350
    animation_duration_close=800
    animation_duration_focus=0
    animation_curve_open=0.46,1.0,0.29,1
    animation_curve_move=0.46,1.0,0.29,1
    animation_curve_tag=0.46,1.0,0.29,1
    animation_curve_close=0.08,0.92,0,1
    animation_curve_focus=0.46,1.0,0.29,1
    animation_curve_opafadeout=0.5,0.5,0.5,0.5
    animation_curve_opafadein=0.46,1.0,0.29,1

    # Scroller Layout Setting
    scroller_structs=20
    scroller_default_proportion=0.8
    scroller_focus_center=0
    scroller_prefer_center=0
    edge_scroller_pointer_focus=1
    scroller_default_proportion_single=1.0
    scroller_proportion_preset=0.5,0.8,1.0

    # Master-Stack Layout Setting
    new_is_master=1
    default_mfact=0.55
    default_nmaster=1
    smartgaps=0

    # Overview Setting
    hotarea_size=10
    enable_hotarea=1
    ov_tab_mode=0
    overviewgappi=5
    overviewgappo=30

    # Misc
    no_border_when_single=0
    axis_bind_apply_timeout=100
    focus_on_activate=1
    idleinhibit_ignore_visible=0
    sloppyfocus=1
    warpcursor=1
    focus_cross_monitor=0
    focus_cross_tag=0
    enable_floating_snap=0
    snap_distance=30
    cursor_size=24
    drag_tile_to_tile=1

    # keyboard
    repeat_rate=25
    repeat_delay=600
    numlockon=0
    xkb_rules_layout=us

    # Trackpad
    disable_trackpad=0
    tap_to_click=1
    tap_and_drag=1
    drag_lock=1
    trackpad_natural_scrolling=1
    disable_while_typing=1
    left_handed=0
    middle_button_emulation=0
    swipe_min_threshold=1

    # mouse
    mouse_natural_scrolling=0

    # Appearance. Gaps/borders/radius mirror upstream defaults; accent
    # colors are routed from themes/matte-candy.nix. The mango-only status
    # slots (urgent/scratchpad/global/overlay/maximize) are left as upstream
    # defaults since they signal distinct UI states that the 2-accent palette
    # would collapse together.
    gappih=5
    gappiv=5
    gappoh=0
    gappov=0
    scratchpad_width_ratio=0.8
    scratchpad_height_ratio=0.9
    borderpx=1
    rootcolor=${mangoHex palette.bg "ff"}
    bordercolor=${mangoHex palette.color8 "ff"}
    focuscolor=${mangoHex palette.accent "ff"}
    maximizescreencolor=0x89aa61ff
    urgentcolor=0xffcc66ff
    scratchpadcolor=0x516c93ff
    globalcolor=0xb153a7ff
    overlaycolor=0x14a57cff

    # layout — Hyprland-style binary-tree splits (dwindle).
    # New windows split the focused window; dwindle_split_ratio controls
    # how much of the parent the new pane takes. 0.33 means the second
    # window in the pair gets ~1/3 of the parent's space — which lines up
    # with "browser at 33% of screen" when ghostty is opened first and Zen
    # second (the order mango-project uses).
    tagrule=id:1,layout_name:dwindle
    tagrule=id:2,layout_name:dwindle
    tagrule=id:3,layout_name:dwindle
    tagrule=id:4,layout_name:dwindle
    tagrule=id:5,layout_name:dwindle
    tagrule=id:6,layout_name:dwindle
    tagrule=id:7,layout_name:dwindle
    tagrule=id:8,layout_name:dwindle
    tagrule=id:9,layout_name:dwindle

    dwindle_split_ratio=0.33

    # Monitor — the Samsung Odyssey G9 ultrawide. Inlined rather than
    # sourced from DMS's auto-generated ~/.config/mango/dms/outputs.conf
    # because DMS used to also overwrite border_radius/gaps/colors in
    # sibling files, silently winning over everything set here. Single
    # source of truth = this file. DMS's display panel still shows the
    # output but its changes (resolution, scale, VRR) no longer
    # propagate to mango — edit this monitorrule directly when needed.
    monitorrule=name:DP-2,width:5120,height:1440,refresh:240,x:0,y:0,scale:1.25,rr:0,vrr:0

    # Autostart — runs once via spawn_shell (sh -c) when mango starts.
    # DankMaterialShell provides bar, launcher (spotlight), control center,
    # dashboard, notifications, lock.
    exec-once=${config.programs.dank-material-shell.package}/bin/dms run

    # Polkit authentication agent — required for any GUI app that prompts
    # for elevated privileges (Bitwarden unlock, gvfs mount helpers, etc.).
    # Without this, those prompts silently fail to appear.
    exec-once=${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent

    # Key Bindings — Hyprland-style: SUPER is the only modifier.
    #   SUPER          = spawn / focus / view
    #   SUPER+SHIFT    = move / swap
    #   SUPER+CTRL     = workspace prev/next
    # Ctrl and Alt are left alone so editors and the terminal get their
    # word-jump / app shortcuts back.

    # reload
    bind=SUPER,r,reload_config

    # spawn — Ghostty (HM-configured upstream build, see comment at top of
    # file) and DMS spotlight take the terminal/launcher slots.
    bind=SUPER,Return,spawn,${lib.getExe ghosttyPkg}
    bind=SUPER,space,spawn,${config.programs.dank-material-shell.package}/bin/dms ipc call spotlight toggle
    bind=SUPER,s,spawn,${lib.getExe pkgs.nautilus}

    # screenshot — `dms screenshot` is compositor-agnostic, interactive
    # region select, saves to file + clipboard.
    bind=SUPER+SHIFT,s,spawn,${config.programs.dank-material-shell.package}/bin/dms screenshot

    # media keys — route through `dms ipc` rather than wpctl/playerctl so
    # the DMS OSD renders. The IPC handlers wrap PipeWire/MPRIS and emit
    # the visual feedback (volume bar, media popup) at the same time.
    # Using wpctl directly works but skips the OSD because DMS triggers
    # it on IPC, not on PipeWire state change.
    bind=NONE,XF86AudioRaiseVolume,spawn,${config.programs.dank-material-shell.package}/bin/dms ipc call audio increment 5
    bind=NONE,XF86AudioLowerVolume,spawn,${config.programs.dank-material-shell.package}/bin/dms ipc call audio decrement 5
    bind=NONE,XF86AudioMute,spawn,${config.programs.dank-material-shell.package}/bin/dms ipc call audio mute
    bind=NONE,XF86AudioMicMute,spawn,${config.programs.dank-material-shell.package}/bin/dms ipc call audio micmute
    bind=NONE,XF86AudioPlay,spawn,${config.programs.dank-material-shell.package}/bin/dms ipc call mpris playPause
    bind=NONE,XF86AudioNext,spawn,${config.programs.dank-material-shell.package}/bin/dms ipc call mpris next
    bind=NONE,XF86AudioPrev,spawn,${config.programs.dank-material-shell.package}/bin/dms ipc call mpris previous

    # exit
    bind=SUPER,m,quit
    bind=SUPER,q,killclient,

    # focus
    bind=SUPER,Tab,focusstack,next
    bind=SUPER,Left,focusdir,left
    bind=SUPER,Right,focusdir,right
    bind=SUPER,Up,focusdir,up
    bind=SUPER,Down,focusdir,down

    # swap window
    bind=SUPER+SHIFT,Up,exchange_client,up
    bind=SUPER+SHIFT,Down,exchange_client,down
    bind=SUPER+SHIFT,Left,exchange_client,left
    bind=SUPER+SHIFT,Right,exchange_client,right

    # window state
    bind=SUPER,g,toggleglobal,
    bind=SUPER+SHIFT,Tab,toggleoverview,
    bind=SUPER,v,togglefloating,
    bind=SUPER,a,togglemaximizescreen,
    bind=SUPER,f,togglefullscreen,
    bind=SUPER+SHIFT,f,togglefakefullscreen,
    bind=SUPER,i,minimized,
    bind=SUPER,o,toggleoverlay,
    bind=SUPER+SHIFT,I,restore_minimized
    bind=SUPER,z,toggle_scratchpad

    # scroller layout
    bind=SUPER,e,set_proportion,1.0
    bind=SUPER+SHIFT,e,switch_proportion_preset,

    # switch layout
    bind=SUPER,n,switch_layout

    # workspace switch — SUPER+N views, SUPER+SHIFT+N moves window.
    bind=SUPER,1,view,1,0
    bind=SUPER,2,view,2,0
    bind=SUPER,3,view,3,0
    bind=SUPER,4,view,4,0
    bind=SUPER,5,view,5,0
    bind=SUPER,6,view,6,0
    bind=SUPER,7,view,7,0
    bind=SUPER,8,view,8,0
    bind=SUPER,9,view,9,0

    bind=SUPER+SHIFT,1,tag,1,0
    bind=SUPER+SHIFT,2,tag,2,0
    bind=SUPER+SHIFT,3,tag,3,0
    bind=SUPER+SHIFT,4,tag,4,0
    bind=SUPER+SHIFT,5,tag,5,0
    bind=SUPER+SHIFT,6,tag,6,0
    bind=SUPER+SHIFT,7,tag,7,0
    bind=SUPER+SHIFT,8,tag,8,0
    bind=SUPER+SHIFT,9,tag,9,0

    # workspace prev/next
    bind=SUPER+CTRL,Left,viewtoleft,0
    bind=SUPER+CTRL,Right,viewtoright,0

    # project workspace — fuzzel picker over ~/Documents/repos/*/.workspace
    # markers; selecting one spawns Zen + ghostty/zellij on the current
    # tag with the project as working dir. See home-manager/workspaces.nix.
    bind=SUPER+SHIFT,p,spawn,mango-project-picker

    # browser — Zen Twilight in a fresh window (--new-window avoids
    # focus_on_activate=1 raising an existing window on another tag).
    # mango parses spawn args space-separated after the third comma; an
    # extra comma would land --new-window as a separate dispatch arg.
    bind=SUPER,b,spawn,zen-twilight --new-window

    # gaps
    bind=SUPER+SHIFT,X,incgaps,1
    bind=SUPER+SHIFT,Z,incgaps,-1
    bind=SUPER+SHIFT,R,togglegaps

    # Mouse Button Bindings — SUPER+drag handles move/resize, replacing the
    # old keyboard-driven CTRL+SHIFT/CTRL+ALT arrow movewin/resizewin binds.
    mousebind=SUPER,btn_left,moveresize,curmove
    mousebind=NONE,btn_middle,togglemaximizescreen,0
    mousebind=SUPER,btn_right,moveresize,curresize

    # Axis Bindings — SUPER+scroll walks workspaces (skipping empty ones).
    axisbind=SUPER,UP,viewtoleft_have_client
    axisbind=SUPER,DOWN,viewtoright_have_client
  '';
}
