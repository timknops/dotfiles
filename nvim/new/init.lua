vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.undofile = true

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
    pattern = "c",
    group = vim.api.nvim_create_augroup("treesitter", { clear = true }),
    callback = function()
        vim.treesitter.start()
    end,
})
