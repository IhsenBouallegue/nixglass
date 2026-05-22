{
  config,
  lib,
  pkgs,
  ...
}: {
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
      # Tracks the DMS palette. The theme file `~/.config/zellij/themes/dms.kdl`
      # is regenerated on every matugen run from the template registered in
      # `~/.config/matugen/config.toml` below.
      theme = "dms";
    };
  };

  # DMS doesn't ship a zellij matugen template (see its
  # share/quickshell/dms/matugen/configs/ — alacritty/ghostty/kitty/foot/
  # wezterm yes, zellij no). Register a user template via matugen's user
  # config so the DMS matugen pipeline picks it up alongside the bundled
  # ones. Output lands at ~/.config/zellij/themes/dms.kdl, referenced by
  # `theme = "dms"` above. DMS's Common/Theme.qml passes
  # --run-user-templates=true by default (the SettingsData toggle in the
  # DMS GUI controls it), so this just works.
  xdg.configFile."matugen/templates/zellij.kdl".text = ''
    themes {
        dms {
            fg "{{colors.on_surface.default.hex}}"
            bg "{{colors.background.default.hex}}"
            black "{{dank16.color0.default.hex}}"
            red "{{dank16.color1.default.hex}}"
            green "{{dank16.color2.default.hex}}"
            yellow "{{dank16.color3.default.hex}}"
            blue "{{dank16.color4.default.hex}}"
            magenta "{{dank16.color5.default.hex}}"
            cyan "{{dank16.color6.default.hex}}"
            white "{{dank16.color7.default.hex}}"
            orange "{{dank16.color11.default.hex}}"
        }
    }
  '';

  # DMS's matugen runner reads ~/.config/matugen/config.toml, extracts the
  # `[config]` and `[templates]` sections (via strings.Index on the literal
  # markers — so the bare `[templates]` line below is required even though
  # it's an empty table), and merges them into the temp config it feeds
  # matugen. matugen 3 accepts the top-level `[templates.X]` schema even
  # though it predates v4 — the DMS bundled configs all use that form.
  xdg.configFile."matugen/config.toml".text = ''
    [config]

    [templates]

    [templates.zellij]
    input_path = "${config.xdg.configHome}/matugen/templates/zellij.kdl"
    output_path = "${config.xdg.configHome}/zellij/themes/dms.kdl"
  '';

  # Best-effort initial population: invoke `dms matugen queue` with the
  # state/shell/config dirs and the current wallpaper from session.json.
  # When DMS is running, queue goes through its socket; otherwise the
  # subcommand runs matugen directly. Skips silently if session.json is
  # missing (first boot) — the theme file will then appear on the next
  # DMS-triggered run (wallpaper or theme change).
  home.activation.zellijThemeBootstrap = lib.hm.dag.entryAfter ["writeBoundary"] ''
    sessionFile="$HOME/.local/state/DankMaterialShell/session.json"
    if [ -f "$sessionFile" ]; then
      wallpaper=$(${pkgs.jq}/bin/jq -r '.wallpaperPath // empty' "$sessionFile")
      if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
        run ${config.programs.dank-material-shell.package}/bin/dms matugen queue \
          --state-dir "$HOME/.local/state/DankMaterialShell" \
          --shell-dir ${config.programs.dank-material-shell.package}/share/quickshell/dms \
          --config-dir "$HOME/.config" \
          --value "$wallpaper" \
          --skip-templates "" \
          2>/dev/null || true
      fi
    fi
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
