{...}: {
  programs.ghostty = {
    enable = true;
    # Non-color settings only. Colors come from Noctalia at runtime — when
    # noctalia lands it will overwrite a themed ghostty config alongside this
    # one. For now ghostty falls back to its default palette.
    settings = {
      font-family = "JetBrains Mono";
      font-size = 13;
      window-padding-x = 8;
      window-padding-y = 8;
      window-decoration = false;
      cursor-style = "block";
      shell-integration = "detect";
      confirm-close-surface = false;
    };
  };
}
