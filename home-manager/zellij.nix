{pkgs, ...}: {
  programs.zellij = {
    enable = true;
    # zellij comes from unstable via the inherit overlay (overlays/default.nix):
    # nixpkgs-25.11's 0.44.1 needs rustc 1.92, the stable channel is on 1.91.
    # Drop the inherit when 25.11 catches up.
    package = pkgs.zellij;
    # Defer to keybind/theme defaults for now; layout/theme tweaks slot in here
    # later.
    settings = {
      default_shell = "bash";
      copy_command = "wl-copy";
      pane_frames = true;
      simplified_ui = true;
      mouse_mode = true;
      show_startup_tips = false;
      ui.pane_frames.rounded_corners = true;
    };
  };

  # `dev` layout, ported verbatim from omarchy-customizer
  # (configs/zellij/layouts/dev.kdl). Used by `mango-project` to launch a
  # project workspace: nvim on the left over a stack of three shells, with
  # two claude panes on the right. HM's programs.zellij has no typed
  # `layouts` option, so we drop the file via xdg.configFile.
  xdg.configFile."zellij/layouts/dev.kdl".text = ''
    // Dev workspace: [nvim / stacked shells] | claude-1 | claude-2
    layout {
        pane split_direction="vertical" {
            pane split_direction="horizontal" size="40%" {
                pane name="editor" size="70%" command="nvim" {
                    args "."
                }
                pane stacked=true size="30%" {
                    pane name="shell-1" expanded=true
                    pane name="shell-2"
                    pane name="shell-3"
                }
            }
            pane name="claude-1" size="30%" command="bash" {
                args "-lic" "claude --dangerously-skip-permissions"
            }
            pane name="claude-2" size="30%" command="bash" {
                args "-lic" "claude --dangerously-skip-permissions"
            }
        }
    }
  '';
}
