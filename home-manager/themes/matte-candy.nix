# Cosmic Coral Candy — single source of truth for the terminal/editor palette.
#
# Two saturated accents, everything else neutral. Coral red (#e65c5c)
# is the primary (matches mango focuscolor); cosmic blue (#6699ff) is
# the secondary. All other ANSI slots are blue/warm-tinted grays —
# enough hue for subtle differentiation, neutral enough that only the
# two accents draw the eye.
#
# Imported by ghostty.nix, zellij.nix, nvim.nix, mango.nix, and dms.nix;
# rebuild after editing any hex value here and every consumer updates
# atomically.
#
# Note: zellij.nix and nvim.nix don't blindly map palette slot N to
# the ANSI Nth-named colour. zellij's "green" slot (the focused-pane
# border) is wired to palette.color1 (coral) on purpose; nvim's
# semantic groups route Statement/Conditional/exceptions to coral and
# Function/Keyword to blue. Edit those files to reroute, not this one.
#
# DMS also gets a matte-candy theme JSON projected from these values
# (see dms.nix), but it ships alongside DMS's own matugen-driven themes;
# user picks via DMS GUI which one is active.
{
  # Surface
  bg = "#060c10"; # cosmic blue-black (ghostty bg)
  fg = "#e6e6e6";
  accent = "#e65c5c"; # coral red — primary accent (mango focuscolor)
  cursor = "#e65c5c";
  selectionFg = "#ffffff";
  selectionBg = "#404040"; # mango bordercolor

  # 16-colour ANSI palette. Only slots 1/4/9/12 carry the accents at
  # full saturation; everything else is a neutral gray.
  color0 = "#101820"; # slightly lifted bg
  color1 = "#e65c5c"; # CORAL (primary, candy-saturated)
  color2 = "#5e7080"; # cool gray (was green)
  color3 = "#7a8590"; # mid blue-gray (was yellow)
  color4 = "#6699ff"; # COSMIC BLUE (secondary, candy-saturated)
  color5 = "#7a7a85"; # neutral gray (was magenta)
  color6 = "#8090a0"; # cool gray (was cyan)
  color7 = "#e6e6e6";
  color8 = "#404040"; # mango bordercolor
  color9 = "#ff7878"; # bright coral
  color10 = "#7a8a95";
  color11 = "#9aa0aa";
  color12 = "#8ab3ff"; # bright cosmic blue
  color13 = "#9a9aa5";
  color14 = "#a0b0c0";
  color15 = "#f5f5f5";

  # Derived greys for the neovim colourscheme.
  muted = "#606060";
  dark = "#101820";
}
