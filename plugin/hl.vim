" variables
let g:hl_server_addr            = get(g:, "hl_server_addr",     "localhost:53827")
let g:hl_server_threads         = get(g:, "hl_server_threads",  3)


if has("textprop") == 0
  echohl ErrorMsg
  echo v:version
  echo "vim-hl-server: update vim to 8.2 or higher, or use branch win_matching"
  echohl None
  finish
endif

if has("channel") == 0
  echohl ErrorMsg
  echo "vim-hl-server: channels doesn't support"
  echohl None
  finish
endif

call system("md5sum --version")
if v:shell_error != 0
  echohl WarningMsg
  echo "vim-hl-server: recommend to install md5sum"
  echohl None
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

augroup hl_callbacks
  au BufReadPost *            call hl#InitPropertieTypes()
  au BufReadPost *            call hl#TryHighlightThisBuffer()

  au InsertLeave *            call hl#TryHighlightThisBuffer()
  au TextChanged *            call hl#TryHighlightThisBuffer()
augroup END

function! HLLastError()
  return hl#GetLastError()
endfunc
