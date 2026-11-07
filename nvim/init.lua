vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.keymap.set("n", "<leader>sf", "<cmd>FzfLua files<CR>", { desc = "Search files" })
vim.keymap.set("n", "<leader>sg", "<cmd>FzfLua live_grep<CR>", { desc = "Grep within files" })

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })

vim.keymap.set("n", "<M-h>", "<cmd>TmuxNavigateLeft<CR>", { desc = "Focus split or tmux pane left" })
vim.keymap.set("n", "<M-l>", "<cmd>TmuxNavigateRight<CR>", { desc = "Focus split or tmux pane right" })

vim.keymap.set("x", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("x", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.undofile = true

vim.opt.splitright = true

vim.opt.signcolumn = "yes"

vim.opt.scrolloff = 5

vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"

vim.schedule(function()
    vim.opt.clipboard = "unnamedplus"
end)

vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
    callback = function()
        vim.hl.on_yank()
    end,
})

vim.lsp.enable("clangd")

vim.diagnostic.config({ virtual_text = true })

local format_group = vim.api.nvim_create_augroup("lsp-format", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
    callback = function(args)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Goto definition" })

        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client or not client:supports_method("textDocument/formatting") then return end

        vim.api.nvim_clear_autocmds({ group = format_group, buffer = args.buf })
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = format_group,
            buffer = args.buf,
            callback = function()
                vim.lsp.buf.format()
            end,
        })
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("treesitter", { clear = true }),
    callback = function()
        pcall(vim.treesitter.start)
    end,
})

vim.g.tmux_navigator_no_mappings = 1

vim.pack.add({
    { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
    "https://github.com/christoomey/vim-tmux-navigator",
    "https://github.com/ibhagwan/fzf-lua",
    "https://github.com/stevearc/oil.nvim",
    "https://github.com/lewis6991/gitsigns.nvim",
    "https://github.com/rebelot/kanagawa.nvim",
    "https://github.com/nvim-mini/mini.pairs",
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/mason-org/mason.nvim",
    "https://github.com/mason-org/mason-lspconfig.nvim",
    "https://github.com/folke/lazydev.nvim"
})

vim.cmd("packadd! termdebug")

vim.cmd.colorscheme("kanagawa-wave")

require("blink.cmp").setup()
require("oil").setup({
    view_options = {
        show_hidden = true
    }
})
require("mini.pairs").setup()
require("mason").setup()
require("mason-lspconfig").setup({ ensure_installed = { "lua_ls" } })
require("lazydev").setup()
