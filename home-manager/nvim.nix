{
  lib,
  pkgs,
  ...
}: let
  palette = import ./themes/matte-candy.nix;
in {
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
  # symlinked spec is loaded alongside the starter's `example.lua`.
  #
  # Colourscheme is defined inline as a function rather than a separate
  # colors/*.lua file: LazyVim accepts a function for opts.colorscheme,
  # the omarchy port ships it that way, and it keeps the palette as the
  # single source of truth (interpolated from themes/matte-candy.nix).
  xdg.configFile."nvim/lua/plugins/matte-candy.lua".text = ''
    -- Managed declaratively by home-manager/nvim.nix. Edit the palette
    -- in home-manager/themes/matte-candy.nix and rebuild — every consumer
    -- (ghostty, zellij, this colourscheme, lualine) updates atomically.
    return {
      {
        "LazyVim/LazyVim",
        opts = {
          colorscheme = function()
            vim.cmd("set termguicolors")
            -- Two-accent routing: coral hits Statement/Conditional/
            -- exceptions/numbers (semantic names purple/danger/accent),
            -- cosmic blue hits Function/Keyword/links (primary/success),
            -- everything else (strings, types, operators, comments) is
            -- a neutral palette gray. Edit which semantic name maps to
            -- which palette slot here, not in the highlight definitions
            -- below.
            local colors = {
              bg        = "${palette.color0}",
              fg        = "${palette.fg}",
              purple    = "${palette.color1}",  -- coral (Statement/Conditional/@constructor)
              primary   = "${palette.color4}",  -- cosmic blue (Function/Keyword)
              secondary = "${palette.color2}",  -- neutral gray (String/Character)
              success   = "${palette.color4}",  -- cosmic blue (links, MoreMsg)
              danger    = "${palette.color1}",  -- coral (Exception/errors)
              warning   = "${palette.color3}",  -- gray (Type/Macro)
              info      = "${palette.color6}",  -- gray (Operator/Tag)
              muted     = "${palette.muted}",
              dark      = "${palette.dark}",
              accent    = "${palette.color1}",  -- coral (Number/Float/MatchParen)
              subtle    = "${palette.color8}",
              border    = "${palette.color8}",
              selection = "${palette.color8}",
            }
            vim.cmd("highlight clear")
            local function set_hl(group, opts)
              vim.api.nvim_set_hl(0, group, opts)
            end
            -- Normal has no bg: ghostty (0.92 opacity + mango blur)
            -- shows through. Every Normal-family group below also gets
            -- bg=none for full transparency.
            set_hl("Normal", { fg = colors.fg })
            set_hl("Comment", { fg = colors.muted, italic = true })
            set_hl("Constant", { fg = colors.purple })
            set_hl("String", { fg = colors.secondary })
            set_hl("Character", { fg = colors.secondary })
            set_hl("Number", { fg = colors.accent })
            set_hl("Boolean", { fg = colors.primary, bold = true })
            set_hl("Float", { fg = colors.accent })
            set_hl("Identifier", { fg = colors.fg })
            set_hl("Function", { fg = colors.primary, bold = true })
            set_hl("Statement", { fg = colors.purple, bold = true })
            set_hl("Conditional", { fg = colors.purple })
            set_hl("Repeat", { fg = colors.purple })
            set_hl("Label", { fg = colors.secondary })
            set_hl("Operator", { fg = colors.info })
            set_hl("Keyword", { fg = colors.primary, bold = true })
            set_hl("Exception", { fg = colors.danger })
            set_hl("PreProc", { fg = colors.secondary })
            set_hl("Include", { fg = colors.primary })
            set_hl("Define", { fg = colors.primary })
            set_hl("Macro", { fg = colors.warning })
            set_hl("PreCondit", { fg = colors.secondary })
            set_hl("Type", { fg = colors.warning, italic = true })
            set_hl("StorageClass", { fg = colors.danger })
            set_hl("Structure", { fg = colors.secondary })
            set_hl("Typedef", { fg = colors.secondary })
            set_hl("Special", { fg = colors.accent })
            set_hl("SpecialChar", { fg = colors.accent })
            set_hl("Tag", { fg = colors.info })
            set_hl("Delimiter", { fg = colors.fg })
            set_hl("SpecialComment", { fg = colors.muted })
            set_hl("Debug", { fg = colors.danger })
            set_hl("Title", { fg = colors.primary, bold = true })
            set_hl("Directory", { fg = colors.info })
            set_hl("MatchParen", { fg = colors.accent, bg = colors.subtle, bold = true })
            set_hl("Conceal", { fg = colors.muted })
            set_hl("NonText", { fg = colors.muted })
            set_hl("SpecialKey", { fg = colors.muted })
            set_hl("Whitespace", { fg = colors.muted })
            set_hl("CursorLine", { bg = colors.dark })
            set_hl("CursorColumn", { bg = colors.dark })
            set_hl("CursorLineNr", { fg = colors.primary, bold = true })
            set_hl("LineNr", { fg = colors.muted })
            set_hl("SignColumn", { fg = colors.muted, bg = colors.bg })
            set_hl("Visual", { bg = colors.selection })
            set_hl("VisualNOS", { bg = colors.subtle })
            set_hl("Search", { fg = colors.bg, bg = colors.primary })
            set_hl("IncSearch", { fg = colors.bg, bg = colors.accent })
            set_hl("Substitute", { fg = colors.bg, bg = colors.warning })
            set_hl("Pmenu", { fg = colors.fg, bg = colors.dark })
            set_hl("PmenuSel", { fg = colors.dark, bg = colors.primary })
            set_hl("PmenuSbar", { bg = colors.subtle })
            set_hl("PmenuThumb", { bg = colors.secondary })
            set_hl("StatusLine", { fg = colors.fg, bg = colors.dark })
            set_hl("StatusLineNC", { fg = colors.muted, bg = colors.dark })
            set_hl("WinSeparator", { fg = colors.border })
            set_hl("VertSplit", { fg = colors.border })
            set_hl("Folded", { fg = colors.muted, bg = colors.subtle, italic = true })
            set_hl("FoldColumn", { fg = colors.muted, bg = colors.bg })
            set_hl("TabLine", { fg = colors.muted, bg = colors.dark })
            set_hl("TabLineFill", { bg = colors.dark })
            set_hl("TabLineSel", { fg = colors.primary, bg = colors.bg, bold = true })
            set_hl("ErrorMsg", { fg = colors.bg, bg = colors.danger, bold = true })
            set_hl("WarningMsg", { fg = colors.bg, bg = colors.warning })
            set_hl("MoreMsg", { fg = colors.success })
            set_hl("ModeMsg", { fg = colors.primary, bold = true })
            set_hl("Question", { fg = colors.info })
            set_hl("DiffAdd", { bg = "#223e36" })
            set_hl("DiffChange", { bg = "#3c2f47" })
            set_hl("DiffDelete", { bg = "#472f36" })
            set_hl("DiffText", { bg = "#47442f", bold = true })
            set_hl("SpellBad", { undercurl = true, sp = colors.danger })
            set_hl("SpellCap", { undercurl = true, sp = colors.warning })
            set_hl("SpellLocal", { undercurl = true, sp = colors.info })
            set_hl("SpellRare", { undercurl = true, sp = colors.accent })
            set_hl("DiagnosticError", { fg = colors.danger })
            set_hl("DiagnosticWarn", { fg = colors.warning })
            set_hl("DiagnosticInfo", { fg = colors.info })
            set_hl("DiagnosticHint", { fg = colors.muted })
            set_hl("DiagnosticUnderlineError", { undercurl = true, sp = colors.danger })
            set_hl("DiagnosticUnderlineWarn", { undercurl = true, sp = colors.warning })
            set_hl("DiagnosticUnderlineInfo", { undercurl = true, sp = colors.info })
            set_hl("DiagnosticUnderlineHint", { undercurl = true, sp = colors.muted })
            set_hl("@text", { link = "Normal" })
            set_hl("@comment", { link = "Comment" })
            set_hl("@constant", { link = "Constant" })
            set_hl("@constant.builtin", { fg = colors.danger, bold = true })
            set_hl("@string", { link = "String" })
            set_hl("@character", { link = "Character" })
            set_hl("@number", { link = "Number" })
            set_hl("@boolean", { link = "Boolean" })
            set_hl("@float", { link = "Float" })
            set_hl("@function", { link = "Function" })
            set_hl("@function.builtin", { fg = colors.accent, bold = true })
            set_hl("@method", { link = "Function" })
            set_hl("@keyword", { link = "Keyword" })
            set_hl("@keyword.function", { link = "Keyword" })
            set_hl("@keyword.operator", { link = "Operator" })
            set_hl("@preproc", { link = "PreProc" })
            set_hl("@type", { link = "Type" })
            set_hl("@type.builtin", { fg = colors.warning, bold = true })
            set_hl("@storageclass", { link = "StorageClass" })
            set_hl("@variable", { fg = colors.fg })
            set_hl("@variable.builtin", { fg = colors.danger, bold = true, italic = true })
            set_hl("@property", { fg = colors.info })
            set_hl("@field", { fg = colors.info })
            set_hl("@parameter", { fg = colors.warning, italic = true })
            set_hl("@punctuation.bracket", { link = "Delimiter" })
            set_hl("@punctuation.delimiter", { link = "Delimiter" })
            set_hl("@tag", { link = "Tag" })
            set_hl("@tag.attribute", { fg = colors.secondary })
            set_hl("@tag.delimiter", { fg = colors.muted })
            set_hl("@constructor", { fg = colors.purple })
            set_hl("@namespace", { fg = colors.info })
            set_hl("@include", { link = "Include" })
            set_hl("@conditional", { link = "Conditional" })
            set_hl("@repeat", { link = "Repeat" })
            set_hl("@label", { link = "Label" })
            set_hl("@exception", { link = "Exception" })
            set_hl("@text.title", { link = "Title" })
            set_hl("@text.literal", { link = "String" })
            set_hl("@text.uri", { fg = colors.success, underline = true })
            set_hl("@text.emphasis", { italic = true })
            set_hl("@text.strong", { bold = true })
            set_hl("@text.todo", { fg = colors.bg, bg = colors.warning, bold = true })
            set_hl("@lsp.type.variable", {})
            set_hl("@lsp.type.property", { link = "@property" })
            set_hl("@lsp.type.function", { link = "@function" })
            set_hl("@lsp.type.method", { link = "@method" })
            set_hl("@lsp.type.keyword", { link = "@keyword" })
            set_hl("@lsp.type.namespace", { link = "@namespace" })
            set_hl("@lsp.type.parameter", { link = "@parameter" })
            set_hl("@lsp.type.type", { link = "Type" })
            set_hl("@lsp.type.class", { link = "Type" })
            set_hl("@lsp.type.struct", { link = "Type" })
            set_hl("@lsp.type.enum", { link = "Type" })
            -- Full transparency: every Normal-family group has bg=none
            -- so ghostty's background (0.92 opacity + mango blur) and
            -- the wallpaper underneath show through.
            for _, group in ipairs({
              "NormalNC", "NormalFloat", "FloatBorder",
              "SignColumn", "EndOfBuffer", "MsgArea", "VertSplit",
              "WinSeparator", "StatusLine", "StatusLineNC",
              "TabLine", "TabLineFill",
              "SnacksDashboardNormal", "SnacksDashboardDesc",
              "SnacksDashboardFooter", "SnacksDashboardHeader",
              "SnacksDashboardIcon", "SnacksDashboardTitle", "SnacksDashboardFile",
            }) do
              vim.api.nvim_set_hl(0, group, { bg = "none" })
            end
            -- Snacks dashboard keymap hints (the "f", "n", "p" letters on
            -- the right). Default link is Number which is the warm-amber
            -- accent; override to coral so they fire the primary accent.
            set_hl("SnacksDashboardKey", { fg = colors.danger, bold = true, bg = "none" })
            vim.g.colors_name = "matte-candy"
          end,
        },
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
      -- Inline lualine theme keyed off the same palette. Mode colours
      -- mirror the two-tone aesthetic: cosmic blue for normal (default
      -- state), coral for insert (active editing — fires the primary
      -- accent), bright coral for replace, mauve for visual, warm gray
      -- for command.
      {
        "nvim-lualine/lualine.nvim",
        opts = {
          options = {
            theme = {
              normal = {
                a = { fg = "${palette.bg}", bg = "${palette.color4}", gui = "bold" },
                b = { fg = "${palette.fg}", bg = "${palette.dark}" },
                c = { fg = "${palette.fg}", bg = "${palette.bg}" },
              },
              insert  = { a = { fg = "${palette.bg}", bg = "${palette.color1}", gui = "bold" } },
              visual  = { a = { fg = "${palette.bg}", bg = "${palette.color5}", gui = "bold" } },
              replace = { a = { fg = "${palette.bg}", bg = "${palette.color9}", gui = "bold" } },
              command = { a = { fg = "${palette.bg}", bg = "${palette.color3}", gui = "bold" } },
              inactive = {
                a = { fg = "${palette.muted}", bg = "${palette.dark}" },
                b = { fg = "${palette.muted}", bg = "${palette.dark}" },
                c = { fg = "${palette.muted}", bg = "${palette.bg}" },
              },
            },
          },
        },
      },
    }
  '';

  # First-run bootstrap: clone the LazyVim starter into ~/.config/nvim if
  # it isn't there yet. cp -rn (no-clobber) preserves the HM-managed
  # matte-candy.lua above; any leftover dms.lua / colors/dms.lua from the
  # previous matugen pipeline is harmless (nothing references them).
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
