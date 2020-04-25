augroup hl_callbacks
  au BufEnter *               call hl#TryHighlightThisBuffer()

  au InsertLeave *            call hl#TryHighlightThisBuffer()
  au TextChanged *            call hl#TryHighlightThisBuffer()
augroup END

function! HLLastError()
  echo g:hl_last_error
endfunc
