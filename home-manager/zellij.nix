{pkgs, ...}: {
  programs.zellij = {
    enable = true;
    # nixpkgs-25.11's zellij 0.44.1 needs rustc 1.92, but the stable channel
    # is on 1.91 — pulling from the unstable overlay sidesteps the toolchain
    # mismatch. Drop this override once 25.11 catches up.
    package = pkgs.unstablePkgs.zellij;
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
