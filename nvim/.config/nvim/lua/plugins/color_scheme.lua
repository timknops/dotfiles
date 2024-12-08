return {
  --   'catppuccin/nvim',
  --   config = function()
  --     require('catppuccin').setup {
  --       integrations = {
  --         cmp = true,
  --         fidget = true,
  --         gitsigns = true,
  --         harpoon = true,
  --         indent_blankline = {
  --           enabled = false,
  --           scope_color = 'sapphire',
  --           colored_indent_levels = false,
  --         },
  --         mason = true,
  --         native_lsp = { enabled = true },
  --         noice = true,
  --         notify = true,
  --         symbols_outline = true,
  --         telescope = true,
  --         treesitter = true,
  --         treesitter_context = true,
  --       },
  --     }
  --
  --     vim.cmd.colorscheme 'catppuccin-mocha'
  --   end,

  'sainnhe/gruvbox-material',
  config = function()
    vim.g.gruvbox_matiral_better_performance = true
    vim.g.gruvbox_material_background = 'hard'
    vim.g.gruvbox_material_foreground = 'mix'
    vim.g.gruvbox_material_ui_contrast = 'high'
    vim.g.gruvbox_material_enable_italic = true
    vim.g.gruvbox_material_float_style = 'dim'
    vim.g.gruvbox_material_diagnostic_text_highlight = true
    vim.g.gruvbox_material_statusline_style = 'mix'

    vim.cmd.colorscheme 'gruvbox-material'
  end,
}
