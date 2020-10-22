" variables
let g:hl_server_addr            = get(g:, "hl_server_addr",     "localhost:53827")
let g:hl_server_threads         = get(g:, "hl_server_threads",  3)
let g:hl_debug_file             = get(g:, "hl_debug_file",      "/dev/null")


if has("textprop") == 0
  echohl ErrorMsg
  echo v:version
  echo "vim-hl-server: current version of vim doesn't support textproperties"
  echo "vim-hl-server: update vim to version 8.2 or higher, or use branch win_matching"
  echohl None
  finish
endif

if has("channel") == 0
  echohl ErrorMsg
  echo "vim-hl-server: current version of vim doesn't support channels"
  echo "vim-hl-server: update vim to version 8 or higher"
  echohl None
  finish
endif


if has("job") && exists("g:hl_server_binary")
  let s:hl_port = split(g:hl_server_addr, ":")[1]
  let s:command = [
        \ "bash", "-c",
        \ g:hl_server_binary, "-v",
        \ "--threads=" .. g:hl_server_threads,
        \ "--port=" .. s:hl_port,
        \ "&>>" .. g:hl_debug_file, "</dev/null"
        \ ]

  let s:hl_job = job_start(s:command)


  function! HLServerStart()
    if job_status(s:hl_job) == "run"
      echohl WarningMsg
      echo "hl-server already runing"
      echohl None
      return
    endif

    let s:hl_job = job_start(s:command)
  endfunc

  function! HLServerStop()
    if job_status(s:hl_job) != "run"
      echohl WarningMsg
      echo "hl-server doesn't runing"
      echohl None
      return
    endif

    call job_stop(s:hl_job)
  endfunc

  function! HLServerStatus()
    echo "hl-server " .. job_status(s:hl_job)
  endfunc
else
  echohl WarningMsg
  echo "vim-hl-server: hl-server can't be run automaticly"
  echo "vim-hl-server: update vim to version 8 or higher, or start the server manually"
  echohl None
  finish
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
