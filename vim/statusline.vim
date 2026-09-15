" Foreglow Custom — powerline-style Vim/Neovim statusline.
" Sourced from .vimrc / init.vim; reads the active theme from g:foreglow_theme.

if !exists('g:foreglow_home')
  let g:foreglow_home = expand('<sfile>:h:h')
endif
if !exists('g:foreglow_theme')
  let g:foreglow_theme = 'foreglow'
endif

execute 'source ' . g:foreglow_home . '/themes/' . g:foreglow_theme . '.theme.vim'

set laststatus=2
set noshowmode

let s:sep = ""
let s:rsep = ""
let s:branch = ''

function! s:Hi(group, fg, bg, attr) abort
  execute 'highlight ' . a:group
        \ . ' guifg=' . a:fg . ' guibg=' . a:bg
        \ . (a:attr !=# '' ? ' gui=' . a:attr : '')
endfunction

function! s:ModeColor() abort
  let l:m = mode()
  if l:m ==# 'i'
    return g:foreglow_success
  elseif l:m ==# 'R'
    return g:foreglow_error
  elseif l:m =~# "^[vV\x16]"
    return g:foreglow_warning
  else
    return g:foreglow_keyword
  endif
endfunction

function! s:ModeLabel() abort
  let l:m = mode()
  let l:names = {'i': 'INSERT', 'R': 'REPLACE', 'v': 'VISUAL',
        \ 'V': 'V-LINE', "\x16": 'V-BLOCK', 'c': 'COMMAND'}
  return get(l:names, l:m, 'NORMAL')
endfunction

" Mode color changes on every keystroke, so this stays cheap: no subprocess.
function! FgStatuslineRefreshMode() abort
  let l:mode_bg = s:ModeColor()
  call s:Hi('FgStlA',    g:foreglow_background,     l:mode_bg,                'bold')
  call s:Hi('FgStlASep', l:mode_bg,                  g:foreglow_current_line, '')
  call s:Hi('FgStlB',    g:foreglow_foreground,      g:foreglow_current_line, '')
  call s:Hi('FgStlBSep', g:foreglow_current_line,    g:foreglow_border,       '')
  call s:Hi('FgStlC',    g:foreglow_foreground_dim,  g:foreglow_border,       '')
endfunction

" Git branch shells out, so this only runs on buffer/window changes, not on
" every cursor move or keystroke — a statusline that forks per redraw is a
" classic way to make the whole editor feel laggy.
function! FgStatuslineRefreshGit() abort
  let l:dir = expand('%:p:h')
  let s:branch = trim(system('git -C ' . shellescape(l:dir) . ' symbolic-ref --short HEAD 2>/dev/null'))
endfunction

function! FgStatuslineBuild() abort
  let l:line  = '%#FgStlA# ' . s:ModeLabel() . ' '
  let l:line .= '%#FgStlASep#' . s:sep
  let l:line .= '%#FgStlB# %f%m'
  if s:branch !=# ''
    let l:line .= '  ' . s:branch
  endif
  let l:line .= ' '
  let l:line .= '%#FgStlBSep#' . s:sep
  let l:line .= '%#FgStlC#%='
  let l:line .= '%{&filetype} '
  " Right of the flex gap, the separator faces the other way (rsep, not
  " sep) — same highlight group works unchanged since it's a mirror image.
  let l:line .= '%#FgStlBSep#' . s:rsep
  let l:line .= '%#FgStlB# %l:%c  %p%% '
  return l:line
endfunction

set statusline=%!FgStatuslineBuild()

augroup FgStatusline
  autocmd!
  autocmd InsertEnter,InsertLeave,ModeChanged * call FgStatuslineRefreshMode()
  autocmd BufEnter,WinEnter,DirChanged,FocusGained * call FgStatuslineRefreshGit() | call FgStatuslineRefreshMode()
augroup END

call FgStatuslineRefreshGit()
call FgStatuslineRefreshMode()
