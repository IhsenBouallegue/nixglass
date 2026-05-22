{
  lib,
  pkgs,
  ...
}: let
  p = import ./themes/matte-candy.nix;
  # fuzzel wants rrggbbaa (no leading #); strip and append alpha.
  c = hex: alpha: (lib.removePrefix "#" hex) + alpha;
in {
  # fuzzel only ships with default light theme; mango-project-picker (and
  # any future dmenu callers) get the matte-candy palette here. Source of
  # truth is themes/matte-candy.nix.
  programs.fuzzel = {
    enable = true;
    package = pkgs.fuzzel;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=12";
        dpi-aware = "yes";
        prompt = "'> '";
        layer = "overlay";
        width = 45;
        lines = 12;
        horizontal-pad = 16;
        vertical-pad = 12;
        inner-pad = 8;
        line-height = 22;
      };
      colors = {
        background = c p.bg "ee";
        text = c p.fg "ff";
        match = c p.accent "ff";
        selection = c p.color0 "ff";
        selection-text = c p.fg "ff";
        selection-match = c p.accent "ff";
        border = c p.accent "ff";
        prompt = c p.color4 "ff";
        input = c p.fg "ff";
        placeholder = c p.muted "ff";
        counter = c p.muted "ff";
      };
      border = {
        radius = 8;
        width = 1;
      };
      dmenu = {
        exit-immediately-if-empty = "yes";
      };
    };
  };
}
