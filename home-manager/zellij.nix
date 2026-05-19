{pkgs, ...}: {
  programs.zellij = {
    enable = true;
    # zellij comes from unstable via the inherit overlay (overlays/default.nix):
    # nixpkgs-25.11's 0.44.1 needs rustc 1.92, the stable channel is on 1.91.
    # Drop the inherit when 25.11 catches up.
    package = pkgs.zellij;
    # Defer to keybind/theme defaults for now; layout/theme tweaks slot in here
    # later. Themes match Noctalia's preset via a user-template (TODO).
    settings = {
      default_shell = "bash";
      copy_command = "wl-copy";
      pane_frames = false;
      simplified_ui = true;
      mouse_mode = true;
    };
  };
}
