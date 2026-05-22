{
  inputs,
  pkgs,
  ...
}: let
  palette = import ./themes/matte-candy.nix;
in {
  programs.ghostty = {
    enable = true;
    # Upstream ghostty flake — newer than the nixpkgs-25.11 1.3.1 pin. Drop
    # the override (use `pkgs.ghostty`) once nixpkgs catches up.
    package = inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
    settings = {
      # Font
      font-family = "JetBrainsMono Nerd Font";
      font-size = 11;
      font-feature = ["calt" "liga"];
      adjust-cell-height = 2;
      # Slight thickening — matches the matte/dark aesthetic so glyphs don't
      # disappear into the bg, and pairs well with fontconfig's "slight"
      # hinting set at the system level.
      font-thicken = true;
      font-thicken-strength = 50;

      # Window
      window-padding-x = 6;
      window-padding-y = 6;
      window-padding-balance = true;
      window-decoration = false;
      confirm-close-surface = false;
      resize-overlay = "never";

      # Transparency. background-blur would require the compositor to
      # implement ext-background-effect-v1 (niri-unstable did, mango does
      # not), so we rely on mango's compositor-side blur from mango.nix
      # for the blurred-behind effect instead.
      background-opacity = 0.92;
      unfocused-split-opacity = 0.85;

      # Cursor
      cursor-style = "block";
      cursor-style-blink = false;

      # Behaviour
      copy-on-select = "clipboard";
      mouse-scroll-multiplier = 0.95;
      shell-integration = "detect";
      shell-integration-features = "no-cursor,ssh-env";

      # Canonical Matte Candy palette, written declaratively from
      # ./themes/matte-candy.nix via xdg.configFile below. DMS's matugen
      # pipeline still regenerates ~/.config/ghostty/themes/dankcolors on
      # wallpaper change — we just don't reference it. To re-couple to
      # DMS, switch this back to "dankcolors".
      theme = "matte-candy";

      # Splits + tabs + clipboard, ported from the omarchy ghostty config.
      keybind = [
        "shift+insert=paste_from_clipboard"
        "control+insert=copy_to_clipboard"

        "ctrl+shift+enter=new_split:right"
        "ctrl+shift+backslash=new_split:down"
        "ctrl+shift+w=close_surface"

        "ctrl+shift+h=goto_split:left"
        "ctrl+shift+j=goto_split:bottom"
        "ctrl+shift+k=goto_split:top"
        "ctrl+shift+l=goto_split:right"

        "ctrl+shift+equal=equalize_splits"
        "ctrl+shift+t=new_tab"
        "ctrl+shift+page_up=previous_tab"
        "ctrl+shift+page_down=next_tab"

        "ctrl+plus=increase_font_size:1"
        "ctrl+minus=decrease_font_size:1"
        "ctrl+zero=reset_font_size"
      ];
    };
  };

  # Ghostty theme file format: one `key = value` per line, plus
  # `palette = N=#hex` entries for the 16 ANSI slots.
  xdg.configFile."ghostty/themes/matte-candy".text = ''
    background = ${palette.bg}
    foreground = ${palette.fg}
    cursor-color = ${palette.cursor}
    selection-background = ${palette.selectionBg}
    selection-foreground = ${palette.selectionFg}

    palette = 0=${palette.color0}
    palette = 1=${palette.color1}
    palette = 2=${palette.color2}
    palette = 3=${palette.color3}
    palette = 4=${palette.color4}
    palette = 5=${palette.color5}
    palette = 6=${palette.color6}
    palette = 7=${palette.color7}
    palette = 8=${palette.color8}
    palette = 9=${palette.color9}
    palette = 10=${palette.color10}
    palette = 11=${palette.color11}
    palette = 12=${palette.color12}
    palette = 13=${palette.color13}
    palette = 14=${palette.color14}
    palette = 15=${palette.color15}
  '';
}
