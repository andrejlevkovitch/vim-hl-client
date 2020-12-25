" variables
let g:hl_server_port            = get(g:, "hl_server_port",     53827)
let g:hl_server_threads         = get(g:, "hl_server_threads",  3)
let g:hl_debug_file             = get(g:, "hl_debug_file",      "/dev/null")

let g:hl_server_addr = "localhost:" . g:hl_server_port


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


let s:command = [
      \ "sh", "-c",
      \ g:hl_server_binary  . 
      \ " --verbose"
      \ ]

let s:hl_job = job_start(s:command, {
      \ "in_io": "pipe",
      \ "out_io": "pipe",
      \ "err_io": "file",
      \ "err_name": g:hl_debug_file,
      \})


" getting channel to the job
let s:hl_server_channel = job_getchannel(s:hl_job)
call ch_setoptions(s:hl_server_channel, {"mode": "json", "callback": "hl#MissedMsgCallback"})

func hl#GetConnect()
  return s:hl_server_channel
endfunc


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
  echo "hl-server " . job_status(s:hl_job)
endfunc

augroup hl_callbacks
  au BufReadPost *            call hl#InitPropertieTypes()
  au BufReadPost *            call hl#TryHighlightThisBuffer()

  au InsertLeave *            call hl#TryHighlightThisBuffer()
  au TextChanged *            call hl#TryHighlightThisBuffer()
augroup END

function! HLServerLastError()
  return hl#GetLastError()
endfunc
