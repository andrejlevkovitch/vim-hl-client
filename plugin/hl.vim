augroup hl_callbacks
  au BufEnter *               call hl#TrySendRequestForThisBuffer()

  au InsertLeave *            call hl#TrySendRequestForThisBuffer()
  au TextChanged *            call hl#TrySendRequestForThisBuffer()
augroup END
