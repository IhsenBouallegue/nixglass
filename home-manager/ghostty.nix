{
  inputs,
  pkgs,
  ...
}: {
  programs.ghostty = {
    enable = true;
    # Upstream ghostty flake — needed for ext-background-effect-v1 (the
    # protocol nixpkgs v1.3.1 doesn't have; landed 4d after that tag).
    package = inputs.ghostty.packages.${pkgs.system}.default;
    # Matte-candy palette inlined. We don't route through Noctalia's template
    # processor: home-manager owns ~/.config/ghostty/* as /nix/store symlinks,
    # so any file Noctalia tries to write there is silently dropped (the
    # ownership-boundary problem CLAUDE.md flags). Keeping colours here is
    # the pragmatic fix until we move noctalia out of /nix/store via
    # mkOutOfStoreSymlink.
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
      window-padding-x = 14;
      window-padding-y = 14;
      window-padding-balance = true;
      window-decoration = false;
      confirm-close-surface = false;
      resize-overlay = "never";

      # Transparency + real blur via ext-background-effect-v1. niri-unstable
      # implements the compositor side; ghostty's GTK build announces the
      # blur intent for its surface, niri composites the gaussian blur
      # behind it. 20 is the ghostty default "looks good" intensity.
      background-opacity = 0.92;
      unfocused-split-opacity = 0.85;
      background-blur = 20;

      # Cursor
      cursor-style = "block";
      cursor-style-blink = false;

      # Behaviour
      copy-on-select = "clipboard";
      mouse-scroll-multiplier = 0.95;
      shell-integration = "detect";
      shell-integration-features = "no-cursor,ssh-env";

      # Matte-candy (Ayaka) palette — matches dotfiles/noctalia/colorschemes/Matte-Candy.
      background = "060c10";
      foreground = "e6e6e6";
      cursor-color = "ffcc66";
      selection-foreground = "ffffff";
      selection-background = "404040";
      palette = [
        "0=#262626"
        "1=#e65c5c"
        "2=#66cc66"
        "3=#ffcc66"
        "4=#6699ff"
        "5=#cc66cc"
        "6=#66cccc"
        "7=#f2f2f2"
        "8=#404040"
        "9=#ff6666"
        "10=#80e680"
        "11=#ffdd80"
        "12=#80b3ff"
        "13=#e680e6"
        "14=#80e6e6"
        "15=#ffffff"
      ];

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
}
