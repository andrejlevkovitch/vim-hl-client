if has("channel") == 0
  echohl WarningMsg
  echo "vim-hl-server: has(\"channel\") == 0"
  echohl None
  finish
endif

" TODO I don't know: print this message or not? The plugin can work without
" caching, but buffer will tokenize after every switch
"call system("md5sum --version")
"if v:shell_error != 0
"  echohl WarningMsg
"  echo "vim-hl-server: required md5sum program"
"  echohl None
"endif

augroup hl_callbacks
  au BufEnter *               call hl#TryHighlightThisBuffer()

  au InsertLeave *            call hl#TryHighlightThisBuffer()
  au TextChanged *            call hl#TryHighlightThisBuffer()
augroup END

function! HLLastError()
  echo g:hl_last_error
endfunc
