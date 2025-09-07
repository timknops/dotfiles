return {
  'neovim/nvim-lspconfig',

  dependencies = {
    -- Pin mason plugins to stable versions to avoid breaking changes
    { 'williamboman/mason.nvim', version = '~1.10', config = true },
    { 'williamboman/mason-lspconfig.nvim', version = '~1.29' },
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    'nvimtools/none-ls.nvim',

    { 'j-hui/fidget.nvim', opts = {} },

    'hrsh7th/cmp-nvim-lsp',
  },

  config = function()
    local null_ls = require 'null-ls'

    -- Null-ls setup (formatters/linters)
    null_ls.setup {
      sources = {
        null_ls.builtins.formatting.black.with {
          extra_args = { '--line-length', '80' },
        },
        null_ls.builtins.formatting.isort,
        null_ls.builtins.formatting.prettierd,
      },
    }

    -- LSP keymaps
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
        map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
        map('K', vim.lsp.buf.hover, 'Hover Documentation')
        map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
        map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        local client = vim.lsp.get_client_by_id(event.data.client_id)

        -- Highlight references
        if client and client.server_capabilities.documentHighlightProvider then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })
          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        -- Inlay hints toggle (use older API for compatibility)
        if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(0, not vim.lsp.inlay_hint.is_enabled(0))
          end, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    -- LSP capabilities for cmp
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

    -- LSP servers (for Mason LSP)
    local lsp_servers = {
      html = {},
      cssls = {},
      eslint = {},
      tailwindcss = {},
      pyright = {
        settings = { python = { analysis = { autoImportCompletions = true } } },
      },
      lua_ls = {
        settings = { Lua = { completion = { callSnippet = 'Replace' } } },
      },
    }

    -- Setup Mason
    require('mason').setup()

    -- Setup Mason Tool Installer for formatters and other tools
    require('mason-tool-installer').setup {
      ensure_installed = {
        'stylua',
        'black',
        'isort',
        'prettierd',
      },
    }

    -- Setup Mason LSPConfig for LSP servers only
    require('mason-lspconfig').setup {
      ensure_installed = vim.tbl_keys(lsp_servers),
    }

    -- Setup each LSP server manually
    for name, cfg in pairs(lsp_servers) do
      cfg.capabilities = vim.tbl_deep_extend('force', {}, capabilities, cfg.capabilities or {})
      require('lspconfig')[name].setup(cfg)
    end
  end,
}
