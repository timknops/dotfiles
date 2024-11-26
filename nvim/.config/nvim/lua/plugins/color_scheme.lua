return {
  'catppuccin/nvim',
  config = function()
    require('catppuccin').setup {
      integrations = {
        cmp = true,
        fidget = true,
        gitsigns = true,
        harpoon = true,
        indent_blankline = {
          enabled = false,
          scope_color = 'sapphire',
          colored_indent_levels = false,
        },
        mason = true,
        native_lsp = { enabled = true },
        noice = true,
        notify = true,
        symbols_outline = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
      },
    }

    vim.cmd.colorscheme 'catppuccin-mocha'
  end,

  -- kanagawa
  -- 'rebelot/kanagawa.nvim',
  -- config = function()
  --   require('kanagawa').setup {
  --     compile = false, -- enable compiling the colorscheme
  --     undercurl = true, -- enable undercurls
  --     commentStyle = { italic = true },
  --     functionStyle = {},
  --     keywordStyle = { italic = true },
  --     statementStyle = { bold = true },
  --     typeStyle = {},
  --     transparent = false, -- do not set background color
  --     dimInactive = false, -- dim inactive window `:h hl-NormalNC`
  --     terminalColors = true, -- define vim.g.terminal_color_{0,17}
  --     colors = { -- add/modify theme and palette colors
  --       palette = {},
  --       theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
  --     },
  --     overrides = function(colors) -- add/modify highlights
  --       return {}
  --     end,
  --     theme = 'wave', -- Load "wave" theme when 'background' option is not set
  --     background = { -- map the value of 'background' option to a theme
  --       dark = 'wave', -- try "dragon" !
  --       light = 'lotus',
  --     },
  --   }
  --
  --   vim.cmd.colorscheme 'kanagawa'
  -- end,

  -- rose-pine
  -- 'rose-pine/neovim',
  -- config = function()
  --   require('rose-pine').setup {
  --     variant = 'auto', -- auto, main, moon, or dawn
  --     dark_variant = 'main', -- main, moon, or dawn
  --     dim_inactive_windows = false,
  --     extend_background_behind_borders = true,
  --
  --     enable = {
  --       terminal = true,
  --       legacy_highlights = true, -- Improve compatibility for previous versions of Neovim
  --       migrations = true, -- Handle deprecated options automatically
  --     },
  --
  --     styles = {
  --       bold = true,
  --       italic = true,
  --       transparency = false,
  --     },
  --
  --     groups = {
  --       border = 'muted',
  --       link = 'iris',
  --       panel = 'surface',
  --
  --       error = 'love',
  --       hint = 'iris',
  --       info = 'foam',
  --       note = 'pine',
  --       todo = 'rose',
  --       warn = 'gold',
  --
  --       git_add = 'foam',
  --       git_change = 'rose',
  --       git_delete = 'love',
  --       git_dirty = 'rose',
  --       git_ignore = 'muted',
  --       git_merge = 'iris',
  --       git_rename = 'pine',
  --       git_stage = 'iris',
  --       git_text = 'rose',
  --       git_untracked = 'subtle',
  --
  --       h1 = 'iris',
  --       h2 = 'foam',
  --       h3 = 'rose',
  --       h4 = 'gold',
  --       h5 = 'pine',
  --       h6 = 'foam',
  --     },
  --   }
  --
  --   vim.cmd.colorscheme 'rose-pine'
  -- end,
  --
  -- tokyonight
  -- 'folke/tokyonight.nvim',
  -- config = function()
  --   require('tokyonight').setup {
  --     style = 'storm', -- night, storm, day, dusk
  --     transparent = false,
  --     italic_comments = true,
  --     italic_keywords = true,
  --     italic_functions = true,
  --     italic_variables = true,
  --     contrast = true,
  --     hide_inactive_statusline = true,
  --     dark_sidebar = true,
  --     dark_float = true,
  --     sidebars = { 'qf', 'vista_kind', 'terminal', 'packer' },
  --     colors = {},
  --   }
  --
  --   vim.cmd.colorscheme 'tokyonight'
  -- end,
}
