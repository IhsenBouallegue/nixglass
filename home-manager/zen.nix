{
  config,
  inputs,
  ...
}: {
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
      };
    };
  };

  # Symlink Zen's userChrome.css to DMS's matugen-generated zen.css so the
  # browser chrome tracks the active DMS theme. mkOutOfStoreSymlink keeps
  # the link target stable as ~/.config/DankMaterialShell/zen.css (a plain
  # file DMS rewrites in place on theme/wallpaper changes); Zen reads
  # userChrome.css on launch, so new Zen windows pick up the new palette.
  # Restart Zen after a DMS theme switch.
  home.file.".config/zen/default/chrome/userChrome.css".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/DankMaterialShell/zen.css";
}
