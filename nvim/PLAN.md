# Neovim rewrite plan

A from-scratch Neovim config, written by hand, to get back into Neovim after
years of VS Code and IntelliJ. At first it's mainly for C.

## The rules

- **Every line of config is typed by me.** Claude explains things, points to
  `:help` pages and reviews my diffs. It only writes config when I explicitly
  ask for something.
- **Start small and grow only when there's a reason.** If I can't say why a line
  or plugin is there, it goes.
- **Built-in first**, unless a very well-known plugin is clearly better. In that
  case, use the plugin.
- **Don't copy from the old config.** It's fine as a reference for ideas, but
  much of it uses APIs that are deprecated or gone (`vim.loop`,
  `require('lspconfig').x.setup`, nvim-cmp, the old nvim-treesitter setup).
- **It has to work on macOS too**, without much trouble.

## Decisions

These were decided before starting, with the reason for each.

**Neovim 0.12.** A fresh config should target the current release. 0.12 has its
own plugin manager, and since 0.11 most of the LSP setup is built in.

**Build next to the old config, then switch.** The new config lives in
`nvim/.config/nvim-new` and runs with `NVIM_APPNAME=nvim-new nvim`. The old
config keeps working until the new one is good enough to use every day.

**Plain symlinks instead of stow.** `ln -s ~/dotfiles/nvim/.config/nvim-new ~/.config/nvim-new`.
That's all stow would do anyway, and it works the same on macOS.

**Install tools with the system package manager** (apt on Linux, brew on macOS).
clangd, bear, ripgrep, fd and fzf are all packaged on both. Mason only becomes
worth it for a language whose server isn't packaged on both. Kotlin is the
likely case.

**Plugin manager: `vim.pack`.** It's built into Neovim, and there won't be
enough plugins to need lazy loading. Things to know about it:
- It's still marked experimental.
- Commit the lockfile (`nvim-pack-lock.json`) so another machine gets the same
  versions.
- Removing a plugin means deleting its line *and* calling `vim.pack.del()`.

**Keybindings: learn the defaults, add only a few of my own.** Leader is Space.
Never override the `gr*` LSP defaults or the hjkl motions. The keyd layout works
fine with Neovim. The only loss is `<C-a>` (increment a number), because it's
the herdr prefix.

**Plugins to start with:**
- **fzf-lua**: searching files and grepping, on `<leader>sf` and `<leader>sg`
- **blink.cmp**: completion
- **oil.nvim**: file explorer, opened with `-`
- **gitsigns**: git changes in the left margin

Do a bit of research on each one before adding it. Everything else stays built
in: the statusline, the colorscheme, LSP and diagnostics.

**C support:**
- **LSP:** a hand-written `lsp/clangd.lua`. Add nvim-lspconfig when a second
  language arrives, which makes adding Python a few minutes' work.
- **Highlighting:** Neovim's bundled C parser, started with a small autocmd. A
  parser installer can wait until a second language. The treesitter plugin world
  changed in 2026 (nvim-treesitter was archived), so look at the options again
  then.
- **Formatting:** clangd, on save. `~/.clang-format` (from the dotfiles,
  `BasedOnStyle: LLVM`, `IndentWidth: 4`) is the default style. A project's own
  `.clang-format` takes over when it has one.
- **Builds:** a hand-written Makefile. `bear -- make` produces
  `compile_commands.json`, so clangd knows the compile flags. Move to CMake when
  a project outgrows Make.
- **Debugging:** gdb through the built-in `:Termdebug`. Look at nvim-dap only if
  that stops being enough. On macOS this will need lldb instead; deal with it
  when it comes up.

**No AI in the editor.** Claude Code runs in a herdr pane. I might write my own
plugin for this later.

## Milestones

Each milestone ends with an editor I could actually use. When a milestone is
done, Claude reviews the diff and I commit it.

### 0. Setup
- [ ] Upgrade Neovim to 0.12.x and skim `:h news-0.12`
- [ ] Install clangd, bear, ripgrep, fd and fzf
- [ ] Create `nvim/.config/nvim-new/init.lua` (empty) and link it to
      `~/.config/nvim-new`
- [ ] Add `.clang-format` to the dotfiles and link it to `~/.clang-format`
- [ ] Write a hello-world C project with a Makefile to try things on

### 1. Options
- [ ] Leader key, line numbers, tabs and indentation, search behaviour, the
      persistent undo file, and how to use the system clipboard
- Read: `:h lua-guide`, `:h options`

### 2. Small extras
- [ ] Highlight text briefly after yanking
- [ ] The first few custom mappings, only ones I actually miss
- Read: `:h autocmd`, `:h vim.keymap.set()`, `:h lsp-defaults`

### 3. C intelligence, still without plugins
- [ ] `lsp/clangd.lua` and `vim.lsp.enable('clangd')`
- [ ] Show diagnostics inline. They've been hidden by default since 0.11.
- [ ] Format on save
- [ ] Treesitter highlighting for C. Check in `:h treesitter` what's built in.
- [ ] Run `bear -- make` on the hello-world project and check that clangd
      understands it
- Read: `:h lsp-quickstart`, `:h lsp-config`, `:h vim.diagnostic.config()`

### 4. Plugins
- [ ] Set up `vim.pack`
- [ ] fzf-lua, with `<leader>sf` and `<leader>sg`
- [ ] blink.cmp
- [ ] oil.nvim
- [ ] gitsigns
- Read: `:h vim.pack`

### 5. Debugging
- [ ] Debug the hello-world program with `:Termdebug`
- Read: `:h terminal-debug`

### 6. Switch over
- [ ] Make `nvim-new` the main config and delete the old one
- [ ] Write down the packages to install, with apt and brew names, for setting
      up a new machine

## Later, when it's needed
- A second language: nvim-lspconfig, a treesitter parser installer, and maybe
  mason
- Insert-mode mappings for Alt-d / Alt-f, if they ever get in the way
- which-key, mini.nvim modules, nvim-dap: only if I actually miss them
