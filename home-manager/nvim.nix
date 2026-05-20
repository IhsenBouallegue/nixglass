{pkgs, ...}: {
  # Starter declarative neovim. CLAUDE.md targets "full config declarative" —
  # this is the baseline; LSPs / DAP / per-language tweaks get layered on as
  # they come up. Colorscheme is catppuccin-mocha.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs.vimPlugins; [
      catppuccin-nvim
      plenary-nvim
      telescope-nvim
      nvim-treesitter.withAllGrammars
      nvim-lspconfig
      gitsigns-nvim
      comment-nvim
      nvim-web-devicons
      lualine-nvim
      which-key-nvim
    ];

    extraLuaConfig = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      local o = vim.opt
      o.number = true
      o.relativenumber = true
      o.expandtab = true
      o.shiftwidth = 2
      o.tabstop = 2
      o.smartindent = true
      o.termguicolors = true
      o.signcolumn = "yes"
      o.undofile = true
      o.ignorecase = true
      o.smartcase = true
      o.scrolloff = 8
      o.updatetime = 250
      o.clipboard = "unnamedplus"

      require("catppuccin").setup({ flavour = "mocha" })
      vim.cmd.colorscheme("catppuccin")

      require("gitsigns").setup()
      require("Comment").setup()
      require("lualine").setup({ options = { theme = "catppuccin" } })
      require("which-key").setup()

      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
        indent = { enable = true },
      })

      local tb = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", tb.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", tb.live_grep,  { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", tb.buffers,    { desc = "Buffers" })
      vim.keymap.set("n", "<leader>fh", tb.help_tags,  { desc = "Help" })
    '';
  };
}
