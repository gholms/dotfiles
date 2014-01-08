call pathogen#infect()

syntax on
filetype plugin on " load file type plugins
set encoding=utf-8

set noerrorbells " Don't make noise
set novisualbell " Don't flash either
set ruler        " Statusbar line numbers
set showcmd      " Show (partial) command in status line
set showmatch    " Show matching braces

set ignorecase   " Searches are case-insensitive...
set smartcase    " ...unless they contain at least one capital letter
set noincsearch  " No incremental searching
set hlsearch     " Highlight matches

set scrolloff=2  " Keep some lines at top/bottom for scope

set backspace=indent,eol,start " Make backspace more useful in insert mode
set shiftwidth=4  " Auto-indent width when using cindent, >>, <<, etc.
set softtabstop=4 " Number of spaces to add/remove with tab/backspace
set tabstop=8     " Hard tab width
set expandtab     " Spaces, not tabs
set shiftround    " When at a weird indent, reindent to the correct place
set smarttab      " Tab/backspace add/remove full tab widths

set invlist                  " Show invisible chars (useful for finding tabs)
set listchars=tab:>-,trail:- " Show tabs and trailing space

" Keep swap files in one of these.  Double slash at the end apparently
" prevents collisions for files named the same thing.
set directory=~/.vim/backup//,.
set backupdir=~/.vim/backup//,.
if version >= 703
    set undofile " Also keep persistent undo when closing and reopening files
    set undodir=~/.vim/undo//,.
endif

""set t_Co=256
""let g:solarized_termtrans=1
""let g:solarized_termcolors=256
""colorscheme solarized

colorscheme peachpuff

" Highlight VCS conflict markers
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

" Search for selected text, forwards or backwards
vnoremap <silent> * :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy/<C-R><C-R>=substitute(
  \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gV:call setreg('"', old_reg, old_regtype)<CR>
vnoremap <silent> # :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy?<C-R><C-R>=substitute(
  \escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gV:call setreg('"', old_reg, old_regtype)<CR>

" Jump to the last position when reopening a file
if has("autocmd")
    au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif
