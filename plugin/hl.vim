" variables
let g:hl_server_addr            = get(g:, "hl_server_addr",     "localhost:53827")
let g:hl_server_threads         = get(g:, "hl_server_threads",  3)


if has("channel") == 0
  echohl WarningMsg
  echo "vim-hl-server: has(\"channel\") == 0"
  echohl None
  finish
endif

if exists("*asyncrun#run") && exists("g:hl_server_binary")
  if exists("g:hl_debug_file") == 0
    augroup hl_auto_run
      let s:hl_port = split(g:hl_server_addr, ":")[1]
      au VimEnter * call asyncrun#run("", {}, g:hl_server_binary .. " --threads=" .. g:hl_server_threads .. " --port=" .. s:hl_port)
    augroup END
  else " debug version
    augroup hl_auto_run
      let s:hl_port = split(g:hl_server_addr, ":")[1]
      au VimEnter * call asyncrun#run("", {}, g:hl_server_binary .. " --threads=" .. g:hl_server_threads .. " --port=" .. s:hl_port .. " -v &>> " .. g:hl_debug_file)
    augroup END
  endif
endif

" TODO I don't know: print this message or not? The plugin can work without
" caching, but buffer will tokenize after every switch
"call system("md5sum --version")
"if v:shell_error != 0
"  echohl WarningMsg
"  echo "vim-hl-server: required md5sum program"
"  echohl None
"endif

func hl#TryHighlightNewBuffer()
  call hl#ClearWinMatches(win_getid())
  call hl#TryHighlightThisBuffer()
endfunc

augroup hl_callbacks
  au BufEnter *               call hl#TryHighlightNewBuffer()

  au InsertLeave *            call hl#TryHighlightThisBuffer()
  au TextChanged *            call hl#TryHighlightThisBuffer()
augroup END

function! HLLastError()
  call hl#PrintLastError()
endfunc
