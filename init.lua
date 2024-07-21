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

autocmd({ 'InsertLeave', 'TextChanged' }, {
  nested = true, -- for format on save
  callback = function()
    if vim.bo.filetype ~= '' and vim.bo.buftype == '' then
      vim.cmd 'w'
    end
  end,
  group = general,
  desc = 'Auto Save',
})

-- -- Update file when there are changes
-- autocmd('FocusGained', {
--   callback = function()
--     vim.cmd 'checktime'
--   end,
--   group = general,
--   desc = 'Update file when there are changes',
-- })
