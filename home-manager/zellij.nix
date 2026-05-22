{
  config,
  lib,
  pkgs,
  ...
}: let
  palette = import ./themes/matte-candy.nix;
in {
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
      # Ghostty answers zellij's CSI-u/OSC startup queries with sequences
      # zellij 0.44 can't parse, hits the 1000-unknown-message cutoff, and
      # logs the client out (window closes immediately when launched via
      # `exec zellij` from ghostty). Disabling kitty-keyboard support stops
      # zellij from soliciting those responses.
      support_kitty_keyboard_protocol = false;
      # Canonical Matte Candy palette, written declaratively from
      # ./themes/matte-candy.nix via xdg.configFile below. To re-couple
      # to DMS's matugen pipeline (which still regenerates dms.kdl on
      # wallpaper change), switch this back to "dms".
      theme = "matte-candy";
    };
  };

  # Zellij theme KDL. Slot names here are zellij's labels for UI roles,
  # not strict ANSI mappings — zellij's "green" drives the focused-pane
  # frame and tab badges, so we wire it to coral (palette.color1) so
  # those fire the primary accent. "blue" stays cosmic blue for any
  # secondary-accent UI. Everything else is a neutral palette gray.
  # "orange" is a misc UI slot; we send it to bright coral too.
  xdg.configFile."zellij/themes/matte-candy.kdl".text = ''
    themes {
        matte-candy {
            fg "${palette.fg}"
            bg "${palette.bg}"
            black "${palette.color0}"
            red "${palette.color1}"
            green "${palette.color1}"
            yellow "${palette.color3}"
            blue "${palette.color4}"
            magenta "${palette.color1}"
            cyan "${palette.color6}"
            white "${palette.color7}"
            orange "${palette.color9}"
        }
    }
  '';

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
