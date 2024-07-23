require 'user.remaps'
require 'user.options'
require 'user.lazy_init'

local autocmd = vim.api.nvim_create_autocmd
local general = vim.api.nvim_create_augroup('General', { clear = true })

-- Shows highlighting on yanking
autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = general,
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost' }, {
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand '%' ~= '' and vim.bo.buftype == '' then
      vim.api.nvim_command 'update'
    end
  end,
})
