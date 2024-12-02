return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  opts = {
    ensure_installed = {
      'python',
      'bash',
      'c',
      'diff',
      'html',
      'lua',
      'luadoc',
      'markdown',
      'vim',
      'vimdoc',
      'css',
      'go',
      'java',
      'svelte',
      'typescript',
      'json',
      'php',
    },

    auto_install = true,
    highlight = {
      enable = true,
    },

    indent = { enable = true },
  },
}
