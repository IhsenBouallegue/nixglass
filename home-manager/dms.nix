{
  config,
  inputs,
  pkgs,
  ...
}: let
  # Matte-Candy palette mapped into DMS's Material Design 3 schema. Source
  # palette is themes/matte-candy.nix (also imported by ghostty/zellij/nvim/
  # mango); this file is the DMS-shaped projection.
  p = import ./themes/matte-candy.nix;
  matteCandyTheme = pkgs.writeText "matte-candy.json" (builtins.toJSON {
    dark = {
      name = "Matte-Candy";
      primary = p.accent;
      primaryText = "#ffffff";
      primaryContainer = "#5a2020";
      secondary = p.color4;
      surface = p.bg;
      surfaceText = p.fg;
      surfaceVariant = p.color0;
      surfaceVariantText = "#a8a8b8";
      surfaceTint = p.accent;
      background = p.bg;
      backgroundText = p.fg;
      outline = p.color8;
      surfaceContainer = p.color0;
      surfaceContainerHigh = "#1a2530";
      surfaceContainerHighest = "#243040";
      error = p.color9;
      warning = "#ffcc66";
      info = p.color4;
      matugen_type = "scheme-content";
    };
    light = {
      name = "Matte-Candy";
      primary = "#cc3333";
      primaryText = "#ffffff";
      primaryContainer = "#f5d0d0";
      secondary = "#a64ca6";
      surface = "#f5f0eb";
      surfaceText = "#2a2a2a";
      surfaceVariant = "#ebe5dd";
      surfaceVariantText = "#5a5a5a";
      surfaceTint = "#cc3333";
      background = "#f5f0eb";
      backgroundText = "#2a2a2a";
      outline = "#c0bab2";
      surfaceContainer = "#ebe5dd";
      surfaceContainerHigh = "#e0d8ce";
      surfaceContainerHighest = "#d5ccc0";
      error = "#cc3333";
      warning = "#cc8800";
      info = "#3366cc";
      matugen_type = "scheme-content";
    };
  });
in {
  # DankMaterialShell — bar, launcher (spotlight), control center, dashboard,
  # notifications, lock. quickshell + QML based.
  #
  # Used by mango via `exec-once=dms run` and `dms ipc call spotlight toggle`
  # bindings (see home-manager/mango.nix).
  #
  # systemd.enable left at its default (false): we spawn DMS via mango's
  # exec-once so the lifecycle is compositor-scoped rather than tied to
  # graphical-session.target.
  imports = [inputs.dms.homeModules.dank-material-shell];

  programs.dank-material-shell = {
    enable = true;
    # dgop is the system-resources CLI dms calls for its CPU/RAM/etc.
    # widgets. The module defaults to `pkgs.dgop`, but dgop isn't in
    # nixpkgs — wire it explicitly from its own flake so we don't have
    # to maintain an overlay.
    dgop.package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.dgop;

    # Narrow centered bar: experimented with patching DankBarWindow.qml
    # (anchors.left/right -> false, implicitWidth = screen.width * 0.33).
    # Visually the bar centered correctly but popups went sideways:
    # getBarBounds() in Common/SettingsData.qml returns x=0, width=screenWidth
    # and every popup position is built on that. Patching the fan-out is
    # broader than the bar window itself. Upstream tracking issue for the
    # proper feature is: https://github.com/AvengeMedia/DankMaterialShell/issues/1679
  };

  # Custom theme JSON at a stable user-visible path. DMS's settings.json
  # is runtime-mutable (user can change themes via GUI), so we don't try to
  # set `currentThemeName`/`customThemeFile` declaratively. After rebuild,
  # activate via DMS Settings → Personalization → Custom Theme, pointed at:
  #   ~/.config/DankMaterialShell/themes/matte-candy.json
  xdg.configFile."DankMaterialShell/themes/matte-candy.json".source = matteCandyTheme;

  # NOTE on user matugen templates (~/.config/matugen/config.toml):
  # The DMS docs at danklinux.com claim user templates run alongside DMS's
  # built-ins. They do not. The dms-go wrapper invokes matugen with `-c
  # /tmp/matugen-config-<rand>.toml` containing only its bundled templates;
  # the user's ~/.config/matugen/config.toml is ignored entirely. Confirmed
  # by intercepting the matugen invocation.
  #
  # The good news: DMS's bundled set is broader than the docs admit. It
  # already includes ghostty (-> ~/.config/ghostty/themes/dankcolors), foot,
  # nvim, gtk3/4, mango colors, vesktop, dgop, and kcolorscheme variants.
  # See home-manager/ghostty.nix for how the ghostty side picks it up.

  # settings.json is intentionally NOT managed declaratively. Three paths
  # were considered:
  #   1. Upstream `programs.dank-material-shell.settings = { ... }` — writes
  #      the whole file as a /nix/store symlink, read-only. DMS GUI edits
  #      silently vanish (the Noctalia trap).
  #   2. Activation script that jq-merges a subset of keys — works, but
  #      GUI edits to managed keys snap back on every rebuild.
  #   3. mkOutOfStoreSymlink at the file level — fails because Quickshell's
  #      FileView writes settings with `atomicWrites: true` (write tmp +
  #      rename), which replaces the symlink with a regular file on the
  #      first GUI change. Dir-level symlink works but conflicts with
  #      xdg.configFile for the matte-candy theme inside the same dir.
  # Net: settings.json is pure runtime state. Tune via the DMS GUI.
}
