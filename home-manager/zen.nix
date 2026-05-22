{
  config,
  inputs,
  pkgs,
  ...
}: let
  # Zen-Nebula — glassmorphism theme by JustAdumbPrsn. Pinned to a known
  # commit so the chrome doesn't shift under us when upstream lands a
  # breaking refactor; bump the rev (and the hash; build will tell you the
  # new one if the rev moves) when you want updates. The repo's
  # "official" install path is Sine (a Zen mod manager), but the
  # userChrome.css / userContent.css / nebula/ layout is a normal
  # Firefox-style chrome bundle so we drop the files in directly. The
  # Sine UI in `preferences.json` is just a settings panel for tweaking
  # CSS vars — without it we get Nebula's defaults, which is the
  # showroom look.
  nebula = pkgs.fetchFromGitHub {
    owner = "JustAdumbPrsn";
    repo = "Zen-Nebula";
    rev = "31ba4a3bde77391e173a6a3460d9fb0ab9bca8a0";
    hash = "sha256-1jZ+7ndp31qTGreStonmSz97zulA48fTR+0g/Zqw0UI=";
  };
in {
  imports = [inputs.zen-browser.homeModules.twilight];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;

    profiles.default = {
      settings = {
        # Allow custom userChrome.css / userContent.css to take effect.
        # Without this flag Zen ignores user stylesheets.
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Force dark mode end-to-end: dark chrome (toolbar + content area)
        # and tell sites we prefer dark via prefers-color-scheme.
        "ui.systemUsesDarkTheme" = 1;
        "browser.theme.content-theme" = 0;
        "browser.theme.toolbar-theme" = 0;
        "layout.css.prefers-color-scheme.content-override" = 0;

        # Compact mode — auto-hide the vertical-tab sidebar, keep the top
        # URL/toolbar always visible. `use-single-toolbar` must be off so
        # the URL bar lives at the top instead of inside the sidebar.
        # `enable-at-startup` forces compact mode on every launch; without
        # it `zen.view.compact` is just the current runtime state and gets
        # overwritten by session restore.
        "zen.view.compact" = true;
        "zen.view.compact.enable-at-startup" = true;
        "zen.view.compact.hide-tabbar" = true;
        "zen.view.compact.hide-toolbar" = false;
        "zen.view.use-single-toolbar" = false;

        # Disable Zen's cross-window tab sync. Default-on since v1.18b,
        # it copies tabs (including new tabs and essentials/pins) between
        # any open Zen windows in the same workspace — bad for the
        # mango-project picker, which wants each project window to stay
        # an isolated set of tabs. Knob is coarse: turning it off also
        # disables Zen Workspaces and Essential/Pinned tab sharing.
        # See https://github.com/zen-browser/desktop/discussions/12025.
        "zen.window-sync.enabled" = false;

        # Nebula transparency prerequisites (per the Nebula README).
        # Without these, the glass/blur surfaces fall back to opaque
        # backgrounds and the theme looks flat.
        "browser.tabs.allow_transparent_browser" = true;
        "zen.widget.linux.transparency" = true;

        # Browser Toolbox (Ctrl+Shift+Alt+I) is gated behind these
        # two prefs in firefox-family — Zen inherits the gate. Needed
        # to inspect chrome elements (e.g. when figuring out which
        # selector paints the dark sidebar).
        "devtools.chrome.enabled" = true;
        "devtools.debugger.remote-enabled" = true;
      };
    };
  };

  # Drop the Nebula bundle into Zen's chrome dir. The DMS matugen sync
  # (which used to put DankMaterialShell/zen.css at userChrome.css) is
  # gone — Nebula owns the chrome now and its dark glassmorphism doesn't
  # benefit from being recolored to the DMS palette. The nebula/ subdir
  # is a store symlink; userChrome.css and userContent.css are inlined
  # text files so we can append local overrides after Nebula's @import
  # without diverging from upstream when its rev bumps.
  home.file.".config/zen/default/chrome/nebula".source = "${nebula}/nebula";

  # Ghostty-style dark overlay. Nebula's web background goes through
  # `browser[transparent="true"] { background: var(--nebula-website-tint) }`
  # (nebula/modules/general-ui.css) where `--nebula-website-tint` is
  # `light-dark(<light>, <dark>)`. In Zen's chrome scope `color-scheme`
  # isn't dependably set to dark even with the dark-theme prefs, so
  # `light-dark(...)` falls back to the light branch (0% alpha) and
  # the wallpaper bleeds through.
  #
  # Override the *resolved* variable instead of the `--var-*` input
  # half. Static rgb values, !important, declared after the @import so
  # we win the cascade tie against Nebula's own `:root { ... !important }`
  # block. Note alpha doesn't translate 1:1 from ghostty — Zen tints a
  # plain dark layer with no compositor blur behind it, so anything
  # above ~75% reads as opaque. Chrome and content kept at the same
  # alpha so the toolbar→page transition is visually continuous.
  # Bump up or down by ±10 to taste.
  home.file.".config/zen/default/chrome/userChrome.css".text = ''
    @import url("nebula/chrome.css");

    :root {
      --nebula-ui-tint: rgb(0 0 0 / 40%) !important;
      --nebula-website-tint: rgb(0 0 0 / 40%) !important;
    }

    .titlebar-close { display: none !important; }
  '';
  home.file.".config/zen/default/chrome/userContent.css".text = ''
    @import url("nebula/content.css");

    :root {
      --nebula-website-tint: rgb(0 0 0 / 40%) !important;
    }
  '';
}
