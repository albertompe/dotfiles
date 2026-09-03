let mapleader=" "

" Set encoding to UTF-8
set encoding=utf-8

" Filetype, plugin and indentation detection
filetype on
filetype plugin on
filetype indent on

" Enable syntax hightlighting
syntax on

" Mouse enabled
set mouse=a

" Set tabbing and indentatingand indentating behaviour
set tabstop=4
set softtabstop=0
set expandtab
set shiftwidth=4
set smarttab
set autoindent
set smartindent

" Show line numbers / relative numbers
set number
set relativenumber

" Show cursor line
set cursorline

" Highlight search terms and incremental search
set hlsearch
set incsearch

" Ignore case on searchs unless you specify an upper case character
set ignorecase
set smartcase

set splitbelow
set splitright

" White space chacters
set nolist
set listchars=eol:$,tab:.\ ,trail:.,extends:>,precedes:<,nbsp:_
highlight SpecialKey term=standout ctermfg=darkgray guifg=darkgray

" Display white space characters with F3 key
nnoremap <F3> :set list!<CR>

"inoremap <C-i> <Esc>

" Open a file throw the explorer
nnoremap <silent> <leader>o :Explore<CR>
" Save changes
nnoremap <silent> <C-s> :w<CR>
" Save file as
nnoremap <silent> <C-s>a :w<Space>
" Quit
nnoremap <silent> <C-q> :q<CR>
" Force quit
nnoremap <silent> <C-q>f :q!<CR>

" -------------------------------------
" - Toggle configurations
" ------------------------------------
" Toggle line numbers
nnoremap <silent> <leader>nn :set number! number?<CR>
" Toggle line relative numbers
nnoremap <silent> <leader>rr :set relativenumber! relativenumber?<CR>
" Toggle long lines wrapping
nnoremap <silent> <leader>ww :set wrap! wrap?<CR>

" -------------------------------------
" - Windows navigation
" -------------------------------------
" Move to the left window
nnoremap <silent> <leader>h <C-w><Left>
" Move to the right window
nnoremap <silent> <leader>l <C-w><Right>
" Move to the window above
nnoremap <silent> <leader>k <C-w><Up>
" Move to the window below
nnoremap <silent> <leader>j <C-w><Down>

" -------------------------------------
" - Windows management
" -------------------------------------
" Close window
nnoremap <silent> <leader>wc :close<CR>
" Split window horizontally
nnoremap <silent> <leader>wh :split<CR>
" Split window vertically
nnoremap <silent> <leader>wv :vsplit<CR>

" -------------------------------------
" - Buffers key mapping
" -------------------------------------
" Create new buffer in actual window
nnoremap <silent> <leader>bn :ene<CR>
" Edit file in new buffer
nnoremap <silent> <leader>bo :e<Space>
" Horizontal split with new buffer
nnoremap <silent> <leader>bh :new<CR>
" Vertical split with new buffer
nnoremap <silent> <leader>bv :vnew<CR>
" List buffers
nnoremap <silent> <leader>bl :ls<CR>
" List buffers and select one
nnoremap <silent> <leader>bc :ls<CR>:buffer<Space>
" Switch between current and last buffer
nnoremap <silent> <leader>bb <C-^>
" Go to next buffer
nnoremap <TAB> :bnext<CR>
" Go to previous buffer
nnoremap <S-TAB> :bprevious<CR>
" Close actual buffer
nnoremap <silent> <leader>bd :bd<CR>
" Kill actual buffer
nnoremap <silent> <leader>bk :bd!<CR>

" -------------------------------------
" - Tabs key mapping
" -------------------------------------
" Create a new tab
nnoremap <silent> <leader>tn :tabnew<CR>
" Go to next tab
nnoremap <silent> <leader>tl :tabnext<CR>
" Go to previous tab
nnoremap <silent> <leader>th :tabprevious<CR>
" Go to first tab
nnoremap <silent> <leader>ta :tabfirst<CR>
" Go to last tab
nnoremap <silent> <leader>tz :tablast<CR>
" Close the current tab
nnoremap <silent> <leader>td :tabclose<CR>
" Close all other tabs
nnoremap <silent> <leader>tD :tabonly<CR>
" Move current tab to left
nnoremap <silent> <leader>tmh :tabm -1<CR>
" Move current tab to right
nnoremap <silent> <leader>tml :tabm +1<CR>

" -------------------------------------
" - Plugins
" -------------------------------------
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  echo '==> Installing vim-plug...'
  let plug_url = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  if has('nvim')
    let plugdir = stdpath('data') . '/site/autoload'
  else
    let plugdir = expand('~/.vim/autoload')
  endif
  call system('mkdir -p ' . shellescape(plugdir))
  if executable('curl')
    call system('curl -fsSL -o ' . shellescape(plugdir . '/plug.vim') . ' ' . shellescape(plug_url))
    if v:shell_error != 0
      echohl ErrorMsg | echo '==> Failed to download vim-plug with curl.' | echohl None
    endif
  elseif executable('wget')
    call system('wget -q -O ' . shellescape(plugdir . '/plug.vim') . ' ' . shellescape(plug_url))
    if v:shell_error != 0
      echohl ErrorMsg | echo '==> Failed to download vim-plug with wget.' | echohl None
    endif
  else
    echohl ErrorMsg | echo '==> No curl or wget available to install vim-plug.' | echohl None
  endif
endif

" Source vim-plug directly by path so it is available in the same session even
" it was just downloaded (nvim does not re-index autoload plugins mid-startup).
let plugged = has('nvim') ? stdpath('data') . '/site/autoload/plug.vim' : expand('~/.vim/autoload/plug.vim')
if filereadable(plugged)
  execute 'source ' . fnameescape(plugged)
endif

call plug#begin('~/.vim/plugged')
" Airline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" NERDTree
Plug 'https://github.com/preservim/nerdtree'
" Tagbar
Plug 'https://github.com/preservim/tagbar'
" Surround
"Plug 'tpope/vim-surround'
" Insert cursor
"Plug 'wincent/terminus'
" fzf

" Autocomplete
"Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()

" -------------------------------------
" - Plugins config: airline
" -------------------------------------
" enable tabline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ''
let g:airline#extensions#tabline#left_alt_sep = ''
let g:airline#extensions#tabline#right_sep = ''
let g:airline#extensions#tabline#right_alt_sep = ''

" enable powerline fonts
"let g:airline_powerline_fonts = 1
"let g:airline_left_sep = ''
"let g:airline_right_sep = ''

" Switch to your current theme
let g:airline_theme = 'onedark'

" Always show tabs
set showtabline=2

" -------------------------------------
" - Plugins key mappings: NERDTree
" -------------------------------------
" NERDTree focus
nnoremap <silent> <leader>f :NERDTreeFocus<CR>
nnoremap <C-f> :NERDTreeFocus<CR>
" NERDTree launch
nnoremap <silent> <leader>n :NERDTree<CR>
nnoremap <C-n> :NERDTree<CR>
" NERDTree focus
nnoremap <silent> <leader>t :NERDTreeToggle<CR>
nnoremap <C-t> :NERDTreeToggle<CR>

" -------------------------------------
"  - Plugins key mappings: Tagbar
" -------------------------------------
" Tagbar toggle
nnoremap <silent> <leader>tb :TagbarToggle<CR>
