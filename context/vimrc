" File: .vimrc
"
" Description: Vim editor configuration.
"
"   IMPORTANT: the mere existence of this file stops Vim from loading
"   $VIMRUNTIME/defaults.vim, which is what normally turns on syntax
"   highlighting and filetype support. Neither is re-enabled below,
"   so as written this configuration runs with:
"
"     syntax highlighting  OFF
"     filetype detection   OFF
"     filetype plugins     OFF
"     filetype indent      OFF
"
"   Adding `syntax on` and `filetype plugin indent on` would restore
"   them; see the formatoptions note below for the one interaction to
"   watch out for if you do.
"
" See also: .bashrc, .inputrc
"
" Author: Rubens Gomes
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" display line number
set number

" use 80 column wide files
" textwidth=80 hard-wraps: Vim inserts a real newline in the buffer
" once a line passes 80 columns. This is a permanent edit to the
" file, not a display effect.
set textwidth=80
" wrapmargin is an older alternative that measures from the right
" edge of the window instead of from column 1. It is ignored entirely
" whenever textwidth is non-zero, so this line is inert and serves
" only to document that textwidth is the one in charge.
set wrapmargin=0
" 't' makes the hard wrap above apply while typing, in every buffer --
" prose and source code alike. Because filetype plugins are off (see
" header), nothing later overrides it and the effective value is 'vt'.
" Note this base is the Vi-compatible default, so it lacks 'c'
" (continue comment leaders when wrapping) and 'q' (let gq reformat
" comments) that a defaults.vim setup would give as 'tcq'.
" If filetype plugins are ever enabled, ftplugins reset formatoptions
" per language and this flag will be lost; the usual remedy is an
" autocmd FileType * setlocal formatoptions+=t
set formatoptions+=t

" breaks by word rather than character
" Display-only, and unrelated to the hard wrapping above: it controls
" where Vim visually folds a line too long for the window, when 'wrap'
" is on. Has no effect while 'list' is on.
set linebreak

" Disable all bell sounds
" The first two cover the error bell and the screen-flash bell.
set noerrorbells
set novisualbell
" belloff=all (Vim 8.0+) is the comprehensive switch and makes the two
" settings above redundant; they are kept for older Vim builds.
set belloff=all
" Empty the terminal's visual-bell string as a final backstop. Must
" have no trailing whitespace -- any spaces after '=' become part of
" the value and the bell comes back.
set t_vb=

" Use spaces instead of tabs
" tabstop    - width a literal tab character is displayed as
" shiftwidth - width of one level of >> / << and autoindent
" expandtab  - insert spaces when Tab is pressed
" softtabstop is left at 0, so Backspace over an indent removes a
" single space rather than a full 2-column level; set it to 2 to make
" Tab and Backspace symmetric.
set tabstop=2
set shiftwidth=2
set expandtab
" display current editor cursor line and column number
set ruler
