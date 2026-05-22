{
  config,
  lib,
  pkgs,
  ...
}: let
  ghostty = lib.getExe config.programs.ghostty.package;

  reposDir = "$HOME/Documents/repos";

  # mango-project [<path>] — spawn a Zen + zellij(dev-layout) pair on the
  # currently-focused tag. If <path> is given, point zellij at it and load
  # URLs from <path>/.workspace.
  #
  # `+new-window` / `--new-window` are non-negotiable: mango runs with
  # focus_on_activate=1, so a bare invocation of zen/ghostty would
  # D-Bus-activate the existing instance, raise a window on another tag,
  # and snap view away from the target. The fresh-window flags force a new
  # surface that maps on the focused tag.
  #
  # Layout is whatever the focused tag is set to (dwindle by default — see
  # tagrules in mango.nix). Order matters for the dwindle split:
  # dwindle_split_ratio is the share the *existing* focused window keeps,
  # so spawning Zen first then zellij leaves Zen at ~1/3 and gives zellij
  # the remaining ~2/3. Wait between the two so Zen is fully mapped before
  # the split fires.
  mango-project = pkgs.writeShellApplication {
    name = "mango-project";
    runtimeInputs = [pkgs.mangowc config.programs.zellij.package];
    text = ''
      proj="''${1:-}"

      # Read URLs from <proj>/.workspace. Format: one `url=<URL>` per line
      # (bare URLs also work); `#` for comments, blanks ignored.
      urls=()
      if [ -n "$proj" ] && [ -f "$proj/.workspace" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
          line="''${line#"''${line%%[![:space:]]*}"}"
          line="''${line%"''${line##*[![:space:]]}"}"
          [ -z "$line" ] && continue
          case "$line" in
            \#*) continue ;;
            url=*) urls+=("''${line#url=}") ;;
            *) urls+=("$line") ;;
          esac
        done < "$proj/.workspace"
      fi

      # Zen tab orchestration. firefox-family CLI tries to be helpful and
      # routes `--new-tab` to the "most recently used window," but in
      # practice (Zen 1.20t, mango/Wayland), passing multiple URLs in one
      # invocation or chaining `--new-window URL1 --new-tab URL2 ...`
      # races: the new window isn't fully registered before the tab
      # message arrives, so tabs end up scattered across pre-existing
      # windows or new ones. Splitting into two phases — first invocation
      # creates the window, sleep gives Zen time to flip the most-recent
      # pointer, second phase fires `--new-tab` per URL — collapses them
      # into the new window.
      if [ "''${#urls[@]}" -eq 0 ]; then
        zen-twilight --new-window about:blank &
      else
        zen-twilight --new-window "''${urls[0]}" &
        if [ "''${#urls[@]}" -gt 1 ]; then
          sleep 1.5
          for u in "''${urls[@]:1}"; do
            zen-twilight --new-tab "$u"
          done
        fi
      fi

      # Let Zen finish mapping before zellij splits the pane — otherwise
      # the dwindle split can fire against the pre-existing focused window
      # (whatever was on the tag before) and Zen lands in the wrong slot.
      sleep 1.0

      if [ -n "$proj" ] && [ -d "$proj" ]; then
        cd "$proj"
        # Fresh zellij session per project. --new-session-with-layout
        # refuses to attach to an existing session, so cycle any stale
        # one first (kill detaches running clients, delete removes the
        # on-disk session dir under ~/.cache/zellij).
        session="dev-$(basename "$proj")"
        zellij kill-session "$session" 2>/dev/null || true
        zellij delete-session "$session" 2>/dev/null || true
        ${ghostty} --working-directory="$proj" +new-window \
          -e bash -lic "exec zellij -s '$session' --new-session-with-layout dev" &
      else
        ${ghostty} +new-window &
      fi
    '';
  };

  # mango-project-picker — fuzzel-driven menu of project dirs under
  # ~/Documents/repos that contain a `.workspace` marker file. Pipes the
  # selection into mango-project.
  mango-project-picker = pkgs.writeShellApplication {
    name = "mango-project-picker";
    runtimeInputs = [pkgs.fuzzel pkgs.findutils pkgs.coreutils];
    text = ''
      repos="${reposDir}"
      if [ ! -d "$repos" ]; then
        echo "no repos dir at $repos" >&2
        exit 1
      fi
      # Collect "<basename>\t<fullpath>" pairs so the menu shows clean
      # names but we can resolve back to absolute paths.
      # Walk the repo tree at any depth (a `.workspace` may live in a
      # nested project dir like `glasshome/dash`), but prune the usual
      # high-volume noise so the scan stays fast.
      mapfile -t pairs < <(
        find "$repos" \
          \( -name node_modules -o -name .git -o -name target \
             -o -name .turbo -o -name dist -o -name build \) -prune -o \
          -name .workspace -type f -printf '%h\n' \
          | sort -u | while read -r dir; do
              printf '%s\t%s\n' "$(basename "$dir")" "$dir"
            done
      )
      if [ "''${#pairs[@]}" -eq 0 ]; then
        echo "no projects with .workspace under $repos" >&2
        exit 1
      fi
      choice=$(printf '%s\n' "''${pairs[@]}" | cut -f1 | \
        fuzzel --dmenu --prompt='project: ') || exit 0
      [ -z "$choice" ] && exit 0
      path=$(printf '%s\n' "''${pairs[@]}" | awk -F'\t' -v n="$choice" \
        '$1==n {print $2; exit}')
      exec mango-project "$path"
    '';
  };
in {
  home.packages = [mango-project mango-project-picker];
}
