" vim: filetype=vim foldmethod=marker foldmarker=#region,#endregion :

set runtimepath+=~/.vim  " for windows
if filereadable( expand('~/.vim/autoload/plug.vim') )
    call plug#begin('~/.vim/plugged')

    Plug 'felipesousa/rupza', { 'do': 'cp colors/* ~/.vim/colors/' }
    Plug 'sheerun/vim-polyglot'
    Plug 'jremmen/vim-ripgrep'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-repeat'
    Plug 'tpope/vim-commentary'

    Plug 'thinca/vim-visualstar'
    Plug 'tpope/vim-endwise'
    Plug 'tpope/vim-rsi'

    Plug 'jiangmiao/auto-pairs'
    let g:AutoPairs = {'(':')', '[':']', '{':'}','"':'"'}

    Plug 'thinca/vim-quickrun'
    let g:quickrun_config = { '*': { 'split': '10' } }

    Plug 'dhruvasagar/vim-table-mode'
    let g:table_mode_motion_up_map    = '<C-k>'
    let g:table_mode_motion_down_map  = '<C-j>'
    let g:table_mode_motion_left_map  = '<C-h>'
    let g:table_mode_motion_right_map = '<C-l>'

    Plug 'luochen1990/rainbow'
    let g:rainbow_active = 1

    Plug 'junegunn/fzf' | Plug 'junegunn/fzf.vim'
    " Plug 'yuki-ycino/fzf-preview.vim'
    let g:fzf_command_prefix = 'Fzf'

    Plug 'easymotion/vim-easymotion'
    let g:EasyMotion_do_mapping = 0
    let g:EasyMotion_smartcase = 1

    Plug 'mg979/vim-visual-multi'
    let g:VM_theme = 'iceblue'
    let g:VM_maps = {}
    let g:VM_maps["Undo"] = 'u'
    let g:VM_maps["Redo"] = '<C-r>'
    let g:VM_maps["Exit"] = '<C-c>'
    let g:VM_maps["Visual Cursors"] = 'n'

    Plug 'dense-analysis/ale'
    let g:ale_sign_column_always = 1
    let g:ale_prolog_swipl_load = 'asserta(use_module(_)), current_prolog_flag(argv, [File]), load_files(File, [sandboxed(true)]), halt.'

    if executable('node')
        Plug 'neoclide/coc.nvim', { 'branch': 'release' }
        let g:coc_disable_startup_warning = 1
        inoremap <silent><expr> <TAB>
                    \ pumvisible() ? "\<C-n>" :
                    \ <SID>check_back_space() ? "\<TAB>" :
                    \ coc#refresh()
        inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

        function! s:check_back_space() abort
            let col = col('.') - 1
            return !col || getline('.')[col - 1]  =~# '\s'
        endfunction
    endif

    " Lisp
    Plug 'guns/vim-sexp'
    let g:sexp_filetypes = ''  " disable all key mappings

    Plug 'kovisoft/slimv'
    let g:slimv_repl_split = 2 " below
    let g:slimv_repl_split_size = 8
    " let g:paraedit_disable_clojure = 1
    let g:paraedit_smartjump = 1
    let g:paredit_electric_return = 0

    Plug 'liquidz/vim-iced', { 'for': 'clojure' }
    Plug 'liquidz/vim-iced-coc-source', { 'for': 'clojure' }
    let g:iced_enable_default_key_mappings = v:true
    let g:iced#buffer#stdout#mods = 'vertical rightbelow'
    " autocmd BufWinEnter *.clj  :IcedConnect
    " autocmd BufWinEnter *.cljc :IcedConnect

    " Golang
    " Plug 'josa42/coc-go', { 'do': 'yarn install --frozen-lockfile' }  " gopls
    Plug 'mattn/vim-goimports', { 'for': 'go' }  " gofmt, goimports

    call plug#end()

    if filereadable(expand('~/.vim/colors/rupza.vim'))
        colorscheme rupza  " should be placed between plug#end() and other highlight commands.
    endif

    highlight ALEWarning ctermbg=Brown
    highlight ALEError   ctermbg=DarkRed
endif

command PlugSetup :call PlugSetup()
function! PlugSetup()
    let plug_path = $HOME . '/.vim/autoload/plug.vim'
    if !filereadable(plug_path)
        execute '!curl --create-dirs -sfLo ' . plug_path . ' https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
        call mkdir(expand("~/.vim/colors"), "p")
    endif
endfunction

language C
set number
set nowrap
set hlsearch
set incsearch
set ignorecase | set smartcase
set directory=$HOME/.vim  " swapfile
set nobackup
set noundofile
set viminfo=
set modeline
set backspace=2
set scrolloff=4
set splitbelow
set laststatus=0
set cmdheight=1 " gui
set rulerformat=%40(%=%t%m%r%h%w\ \|\ %{&fileencoding}\ %{&fileformat}\ \|\ %P%)
set list | set listchars=tab:\|\ ,extends:»,precedes:«,nbsp:%
set expandtab
set shiftwidth=4   " tab width at bol.
set tabstop=4      " tab width other than bol.
set encoding=utf-8
set fileencodings=utf-8,cp932,euc-jp
set fileformats=unix,dos
set mouse=a
set clipboard& | set clipboard^=unnamedplus
let mapleader = ','
let maplocalleader = '\'

"let &t_EI .= '\ePtmux;\e[<0t\e\\'
"set ttimeoutlen=100

" remove trailing whitespace
autocmd BufWritePre * :%s/\s\+$//ge

" discreet showmatch paren
hi MatchParen cterm=NONE ctermbg=DarkGray ctermfg=NONE

" discreet special chars
" eol, extends, precedes
hi NonText    ctermbg=NONE ctermfg=59 guibg=NONE guifg=NONE
" nbsp, tab, trail
hi SpecialKey ctermbg=NONE ctermfg=59 guibg=NONE guifg=NONE

" highlight current line when insert mode
autocmd InsertEnter,InsertLeave * set cursorline!
highlight CursorLine cterm=NONE ctermbg=Black

" black hole
noremap  c  "_c
noremap  C  "_C
noremap  x  "_x
vnoremap p  "_dP

" disable inc/dec
map <C-a> <Nop>
map <C-x> <Nop>

" map
noremap  H      ^
noremap  L      $
noremap  <C-l>  zz
inoremap <C-l>  <C-o>zz
inoremap <C-c>  <Esc>
nnoremap t      zA
nnoremap T      zM
nnoremap <C-t>  zR
nnoremap J      zj
nnoremap K      zk
nnoremap >      >>
nnoremap <      <<
vnoremap >      >gv
vnoremap <      <gv
map      s      <Plug>(easymotion-s2)
nmap     <C-_>  <Plug>CommentaryLine " C-/ only works on tmux.
vmap     <C-_>  <Plug>Commentary
imap     <C-_>  <C-o><Plug>CommentaryLine

" Lisp
nmap <C-j>  <Plug>(sexp_swap_element_forward)
nmap <C-k>  <Plug>(sexp_swap_element_backward)
nmap <C-h>  <Plug>(sexp_flow_to_prev_open)<Plug>(sexp_indent_top)
nmap <C-l>  <Plug>(sexp_flow_to_next_open)<Plug>(sexp_indent_top)
nmap md  d%
nmap m"  <Leader>w"
nmap m(  <Leader>w)
nmap m[  <Leader>w]
nmap m{  <Leader>w}
nmap m.  <Leader>>
nmap m,  <Leader><
nmap m@  <Leader>S
nmap mr  <Leader>I

nnoremap mso :IcedStdoutBufferOpen<CR>
nnoremap msc :IcedStdoutBufferClose<CR>
nnoremap msr :IcedStdoutBufferClear<CR>
nnoremap mc  :IcedConnect<CR>

autocmd BufNewFile,BufRead *.lisp  nmap mc <Leader>c
autocmd BufNewFile,BufRead *.clj   nnoremap mc :IcedConnect<CR>
autocmd BufNewFile,BufRead *.cljs  nnoremap mc :IcedConnect<CR>
autocmd BufNewFile,BufRead *.cljc  nnoremap mc :IcedConnect<CR>


" space
nnoremap <Space>@  gg=G<C-o><C-o>
nnoremap <Space>0  :noh<CR>
nnoremap <Space>1  :only<CR>
nnoremap <Space>-  :split<CR>
nnoremap <Space>^  :vsplit<CR>
nnoremap <Space>:  :FzfCommands<CR>
nnoremap <Space>;  :FzfBuffers<CR>
nnoremap <Space>f  :FzfFiles<CR>
nnoremap <Space>s  :FzfBLines<CR>
nnoremap <Space>S  :FzfLines<CR>
nnoremap <Space>t  :FzfFiletypes<CR>
nnoremap <Space>g  :Rg<Space>
nnoremap <Space>r  :QuickRun<Space>

" command
command ReopenWithCp932 :e ++enc=cp932
command SaveWithCp932   :set fenc=cp932<CR>:w<CR>
command SaveWithUtf8    :set fenc=utf-8<CR>:w<CR>

" autocmd
autocmd BufNewFile,BufRead *.bb  setl filetype=clojure
autocmd BufNewFile,BufRead *.cmd setl filetype=ps1 fileencodings=cp932

autocmd FileType scheme vnoremap <Leader>e :!gosh_send %V

" function! CursorChar()
"   return getline('.')[col('.')-1]
" endfunction

" function! RemovePaired()
"   if CursorChar() = '('
" endfunction
