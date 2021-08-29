" variables
let g:hl_server_port            = get(g:, "hl_server_port",     53827)
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

if has("job") == 0
  echohl WarningMsg
  echo "vim-hl-server: hl-server can't be run automaticly"
  echo "vim-hl-server: update vim to version 8 or higher, or start the server manually"
  echohl None
  finish
endif

if exists("g:hl_server_binary") == 0
  echohl WarningMsg
  echo "vim-hl-server: hl_server_binary doesn't set"
  echo "vim-hl-server: can't run hl-sever"
  echohl None
  finish
endif


" check version of hl-server
let s:file_script_dir = expand("<sfile>:p:h")

let s:hl_server_binary_verson = system(g:hl_server_binary . " --version")
let s:hl_server_repo_version  = system('git --git-dir=' . s:file_script_dir . "/../third-party/hl-server/.git describe --tags")

if s:hl_server_binary_verson != s:hl_server_repo_version
  echohl WarningMsg
  echo "vim-hl-server: hl-server updated to " . s:hl_server_repo_version
  echo "vim-hl-server: you should recompile hl-server"
  echohl None
endif


let s:hl_server_start_command = [
      \ "sh", "-c",
      \ g:hl_server_binary  . 
      \ " --verbose"        .
      \ " --port="          . g:hl_server_port
      \ ]

" XXX in case of usage *_io as file option, then every job start truncate
" log file. See E920
let s:hl_server_job_options = {
      \ "in_io"   : "null",
      \ "out_io"  : "file",
      \ "err_io"  : "file",
      \ "out_name": g:hl_debug_file,
      \ "err_name": g:hl_debug_file,
      \}

let s:hl_job = job_start(s:hl_server_start_command, s:hl_server_job_options)


" one connection per window
func hl#GetConnect()
  if exists("w:hl_server_channel") == 0 ||
        \ ch_status(w:hl_server_channel) != "open"
    let w:hl_server_channel = ch_open(
          \"localhost:" . g:hl_server_port,
          \ {"mode": "json", "callback": "hl#MissedMsgCallback"})
  endif

  return w:hl_server_channel
endfunc


function! HLServerStart()
  if job_status(s:hl_job) == "run"
    echohl WarningMsg
    echo "hl-server already runing"
    echohl None
    return
  endif

  let s:hl_job = job_start(s:hl_server_start_command, s:hl_server_job_options)
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
  echo "hl-server " . job_status(s:hl_job)
endfunc

augroup hl_callbacks
  au BufNewFile  *            call hl#InitPropertieTypes()

  au BufReadPost *            call hl#InitPropertieTypes()
  au BufReadPost *            call hl#TryHighlightThisBuffer()

  au InsertLeave *            call hl#TryHighlightThisBuffer()
  au TextChanged *            call hl#TryHighlightThisBuffer()
augroup END

function! HLServerLastError()
  return hl#GetLastError()
endfunc
