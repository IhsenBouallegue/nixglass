{
  config,
  inputs,
  pkgs,
  ...
}: let
  # Matte-Candy palette mapped into DMS's Material Design 3 schema. Source
  # palette lives inline in ghostty.nix / mango.nix (ported from
  # omarchy-customizer's theme/matte-candy/colors.toml); this file is the
  # DMS-shaped projection of those same hex values.
  matteCandyTheme = pkgs.writeText "matte-candy.json" (builtins.toJSON {
    dark = {
      name = "Matte-Candy";
      primary = "#e65c5c";
      primaryText = "#ffffff";
      primaryContainer = "#5a2020";
      secondary = "#cc66cc";
      surface = "#060c10";
      surfaceText = "#e6e6e6";
      surfaceVariant = "#101820";
      surfaceVariantText = "#a8a8b8";
      surfaceTint = "#e65c5c";
      background = "#060c10";
      backgroundText = "#e6e6e6";
      outline = "#404040";
      surfaceContainer = "#101820";
      surfaceContainerHigh = "#1a2530";
      surfaceContainerHighest = "#243040";
      error = "#ff6666";
      warning = "#ffcc66";
      info = "#6699ff";
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
    dgop.package = inputs.dgop.packages.${pkgs.system}.dgop;
  };

  # Custom theme JSON at a stable user-visible path. DMS's settings.json
  # is runtime-mutable (user can change themes via GUI), so we don't try to
  # set `currentThemeName`/`customThemeFile` declaratively. After rebuild,
  # activate via DMS Settings → Personalization → Custom Theme, pointed at:
  #   ~/.config/DankMaterialShell/themes/matte-candy.json
  xdg.configFile."DankMaterialShell/themes/matte-candy.json".source = matteCandyTheme;
}
