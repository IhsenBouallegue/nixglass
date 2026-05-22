{
  lib,
  pkgs,
  ...
}: {
  # Neovim binary + the runtime tools LazyVim's defaults expect on PATH.
  # Plugin management is delegated to lazy.nvim (cloned with the starter
  # in the activation script below) — *do not* add `programs.neovim.plugins`
  # here, it'll fight LazyVim for runtimepath ownership.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraPackages = with pkgs; [
      tree-sitter # nvim-treesitter grammar builds
      lazygit # LazyVim's :LazyGit / Snacks lazygit integration
      nodejs # required by a handful of LSPs / Mason-installed tools
    ];
  };

  # LazyVim plugin spec layered on top of the starter. Files under
  # ~/.config/nvim/lua/plugins/ are auto-discovered by lazy.nvim, so this
  # symlinked spec is loaded alongside the starter's `example.lua`. We add
  # AvengeMedia/base46 (the colorscheme loader DMS's matugen pipeline
  # generates against), pin LazyVim's colorscheme to "dms", and set
  # globals for rounded float borders + translucent floats (which pick
  # up ghostty's transparency + mango's compositor-side blur).
  xdg.configFile."nvim/lua/plugins/dms.lua".text = ''
    -- Managed declaratively by home-manager/nvim.nix. To customise nvim
    -- beyond this, edit any other file under ~/.config/nvim/lua/plugins/
    -- (those are owned by LazyVim and writable).
    return {
      { "AvengeMedia/base46" },
      {
        "LazyVim/LazyVim",
        opts = { colorscheme = "dms" },
        init = function()
          -- nvim 0.11+ global float border (replaces having to set
          -- `border = "rounded"` on every plugin's setup table).
          vim.o.winborder = "rounded"
          -- Let the terminal background (ghostty 0.92 opacity + mango
          -- blur) show through floats and the completion popup.
          vim.o.winblend = 10
          vim.o.pumblend = 10
        end,
      },
      -- DMS also writes ~/.config/nvim/lua/lualine/themes/dms.lua via
      -- matugen; point lualine at it so the statusline tracks the palette.
      {
        "nvim-lualine/lualine.nvim",
        opts = {options = {theme = "dms"};},
      },
    }
  '';

  # First-run bootstrap: clone the LazyVim starter into ~/.config/nvim if
  # it isn't there yet. cp -rn (no-clobber) preserves the HM-managed
  # dms.lua above and DMS's matugen-written ~/.config/nvim/colors/dms.lua
  # + ~/.config/nvim/lua/lualine/themes/dms.lua. lazy.nvim then takes over
  # at first nvim launch and installs the rest of the plugins to
  # ~/.local/share/nvim/lazy/.
  home.activation.bootstrapLazyVim = lib.hm.dag.entryAfter ["writeBoundary"] ''
    nvimdir="$HOME/.config/nvim"
    marker="$nvimdir/lua/config/lazy.lua"
    if [ ! -f "$marker" ]; then
      tmpdir=$(mktemp -d)
      run ${pkgs.git}/bin/git clone --depth=1 https://github.com/LazyVim/starter "$tmpdir/starter"
      run rm -rf "$tmpdir/starter/.git"
      run mkdir -p "$nvimdir"
      run cp -rn "$tmpdir/starter/." "$nvimdir/"
      run rm -rf "$tmpdir"
    fi
  '';
}
