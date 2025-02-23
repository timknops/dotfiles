-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
-- vim.keymap.set('n', 'q', '<Nop>', { desc = 'Disable q' })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>l', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Keybinds for split navigation
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Keybinds for visul mode
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move the selected lines down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move the selected lines up' })

-- Keeping cursor in the middle
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down and keep cursor in the middle' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up and keep cursor in the middle' })
vim.keymap.set('n', 'n', 'nzz', { desc = 'Move to next search result and keep cursor in the middle' })
vim.keymap.set('n', 'N', 'Nzz', { desc = 'Move to previous search result and keep cursor in the middle' })

vim.keymap.set('i', '<C-c>', '<nop>')

-- Paste without yanking
vim.keymap.set('x', 'p', '"_dP', { desc = 'Paste without yanking' })

-- Keybinds for buffer navigation
vim.keymap.set('n', '<C-p>', '<Cmd>BufferPrevious<CR>', { desc = 'Go to previous buffer' })
vim.keymap.set('n', '<C-n>', '<Cmd>BufferNext<CR>', { desc = 'Go to next buffer' })
vim.keymap.set('n', '<C-q>', '<Cmd>BufferClose<CR>', { desc = 'Close buffer' })
vim.keymap.set('n', '<C-h>', '<Cmd>BufferMovePrevious<CR>', { desc = 'Move current buffer a position back' })
vim.keymap.set('n', '<C-l>', '<Cmd>BufferMoveNext<CR>', { desc = 'Move current buffer to next position' })
