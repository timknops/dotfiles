" Enable IdeaVim plugins
Plug 'machakann/vim-highlightedyank'
Plug 'tpope/vim-commentary'
Plug 'preservim/nerdtree'

let mapleader = ' '

" Settings.
set number relativenumber
set scrolloff=10
set mouse=a
set noshowmode
set clipboard=unnamedplus
set breakindent
set undofile
set ignorecase
set smartcase
set signcolumn=yes
set updatetime=250
set notimeout
set splitright
set splitbelow
set list
set listchars=tab:» ,trail:·,nbsp:␣
set inccommand=split
set cursorline
set hlsearch
set commentary
set incsearch
set hig
set NERDTree
set ideajoin
set which-key
set ideastatusicon=gray
set idearefactormode=keep

" NERDTree
let g:NERDTreeWinSize = 30
nmap m :NERDTreeToggle<CR>

" For switching between tabs/panes
nnoremap <C-n> :tabnext<CR>
nnoremap <C-p> :tabprevious<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k

" For splitting and unsplitting
map <leader>v <Action>(SplitVertically)
map <leader>u <Action>(Unsplit)

" Comment lines
vmap gc <Action>(CommentByLineComment)<Esc>

" Clears any search highlights
nnoremap <Esc> :nohlsearch<CR>

" Disables the q and C-c keys
nnoremap q <Nop>
inoremap <C-c> <Nop>

" For moving highlighted text up and down
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Goto's
nmap gi <Action>(FindUsages)
nmap [d <Action>(GotoPreviousError)
nmap ]d <Action>(GotoNextError)

" For error navigation
nmap <S-k> <Action>(ShowErrorDescription)
nmap <S-j> <Action>(QuickJavaDoc)

"For centering the screen after moving up and down
nnoremap <Esc><Esc> <C-\><C-n>
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap n nzz
nnoremap N Nzz

" For some reason, only the up arrow key needs to be remapped
imap <C-k> <C-p>

" For searching everywhere
nmap <leader>se <Action>(SearchEverywhere)
nmap <leader>sf <Action>(com.mituuz.fuzzier.Fuzzier)

" For accepting lookup and copilot
imap <C-l> <Action>(EditorChooseLookupItem)<Action>(copilot.applyInlays)
