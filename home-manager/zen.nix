{inputs, ...}: {
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
}
