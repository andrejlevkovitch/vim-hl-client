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
  let s:hl_port = split(g:hl_server_addr, ":")[1]

  function! HLStartServer()
    if exists("g:hl_debug_file") == 0
      call asyncrun#run("", {}, g:hl_server_binary .. " --threads=" .. g:hl_server_threads .. " --port=" .. s:hl_port)
    else
      call asyncrun#run("", {}, g:hl_server_binary .. " --threads=" .. g:hl_server_threads .. " --port=" .. s:hl_port .. " -v &>> " .. g:hl_debug_file)
    endif
  endfunc

  function! HLStopServer()
    call asyncrun#stop("")
  endfunc

  augroup hl_auto_run
    au VimEnter * call HLStartServer()
  augroup END
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
  return hl#GetLastError()
endfunc
