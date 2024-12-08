return {
  'sainnhe/gruvbox-material',
  config = function()
    vim.g.gruvbox_material_better_performance = true
    vim.g.gruvbox_material_background = 'hard'
    vim.g.gruvbox_material_foreground = 'mix'
    vim.g.gruvbox_material_ui_contrast = 'high'
    vim.g_gruvbox_material_enable_bold = false
    vim.g.gruvbox_material_enable_italic = false
    vim.g.gruvbox_material_diagnostic_text_highlight = true
    vim.g.gruvbox_material_float_style = 'dim'
    vim.g.gruvbox_material_statusline_style = 'mix'

    vim.cmd.colorscheme 'gruvbox-material'
  end,
}
