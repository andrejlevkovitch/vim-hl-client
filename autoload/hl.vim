let g:hl_server_addr      = "localhost:9173"
let g:hl_supported_types  = ["cpp", "c"]
let g:hl_last_error       = ""

" cache is a map with structure:
" {
"   buf_name: [cache_key, tokens]
" }
let g:hl_cache            = {}

let g:hl_group_to_hi_link = {
      \ "Namespace"                           : "Namespace",
      \ "NamespaceAlias"                      : "Namespace",
      \ "NamespaceRef"                        : "Namespace",
      \ 
      \ "StructDecl"                          : "Type",
      \ "UnionDecl"                           : "Type",
      \ "ClassDecl"                           : "Type",
      \ "EnumDecl"                            : "Type",
      \ "TypedefDecl"                         : "Type",
      \ "TemplateTypeParameter"               : "Type",
      \ "ClassTemplate"                       : "Type",
      \ "ClassTemplatePartialSpecialization"  : "Type",
      \ "TemplateTemplateParameter"           : "Type",
      \ "UsingDirective"                      : "Type",
      \ "UsingDeclaration"                    : "Type",
      \ "TypeAliasDecl"                       : "Type",
      \ "CXXBaseSpecifier"                    : "Type",
      \ "TemplateRef"                         : "Type",
      \ "TypeRef"                             : "Type",
      \ 
      \ "CXXConstructor"                      : "Function",
      \ "CXXDestructor"                       : "Function",
      \ "Function"                            : "Function",
      \ "FunctionDecl"                        : "Function",
      \ "FunctionTemplate"                    : "Function",
      \ "OverloadedDeclRef"                   : "Function",
      \ "ConversionFunction"                  : "Function",
      \ "CallExpr"                            : "Function",
      \ 
      \ "Member"                              : "Member",
      \ "MemberRef"                           : "Member",
      \ "MemberRefExpr"                       : "Member",
      \ "CXXMethod"                           : "Member",
      \ "FieldDecl"                           : "Member",
      \ 
      \ "EnumConstant"                        : "EnumConstant",
      \ "EnumConstantDecl"                    : "EnumConstant",
      \ 
      \ "MacroDefinition"                     : "Macro",
      \ "MacroInstantiation"                  : "Macro",
      \ "macro expansion"                     : "Macro",
      \ 
      \ "InvalidFile"                         : "Error",
      \ "NoDeclFound"                         : "Error",
      \ "InvalidCode"                         : "Error",
      \ 
      \ "CXXAccessSpecifier"                  : "Label",
      \ "LabelRef"                            : "Label",
      \ 
      \ "LinkageSpec"                         : "Normal",
      \ "FirstInvalid"                        : "Normal",
      \ "NotImplemented"                      : "Normal",
      \ "FirstExpr"                           : "Normal",
      \ "BlockExpr"                           : "Normal",
      \ 
      \ "ObjCMessageExpr"                     : "Normal",
      \ "ObjCSuperClassRef"                   : "Normal",
      \ "ObjCProtocolRef"                     : "Normal",
      \ "ObjCClassRef"                        : "Normal",
      \ "ObjCDynamicDecl"                     : "Normal",
      \ "ObjCSynthesizeDecl"                  : "Normal",
      \ "ObjCInterfaceDecl"                   : "Normal",
      \ "ObjCCategoryDecl"                    : "Normal",
      \ "ObjCProtocolDecl"                    : "Normal",
      \ "ObjCPropertyDecl"                    : "Normal",
      \ "ObjCIvarDecl"                        : "Normal",
      \ "ObjCInstanceMethodDecl"              : "Member",
      \ "ObjCClassMethodDecl"                 : "Member",
      \ "ObjCImplementationDecl"              : "Normal",
      \ "ObjCCategoryImplDecl"                : "Normal",
      \}
        
" XXX default highlighting for Varables are simple white color, so I don't see
" reason for set this highlight by plugin. But if you need another highlighting
" - just uncomment it and set what you want
"     \ "Variable"                            : "Variable",
"     \ "ParmDecl"                            : "Variable",
"     \ "VariableRef"                         : "Variable",
"     \ "NonTypeTemplateParameter"            : "Variable",


func hl#GetConnect()
  if exists("w:hl_server_channel") == 0 ||
        \ ch_status(w:hl_server_channel) != "open"
    let w:hl_server_channel = ch_open(g:hl_server_addr,
          \ {"mode": "json", "callback": "hl#MissedMsgCallback"})
  endif

  return w:hl_server_channel
endfunc


func hl#ClearWinMatches(win_id)
  if exists("w:matches")
    for l:match in w:matches
      call matchdelete(l:match, a:win_id)
    endfor
  endif

  let w:matches = []
endfunc


" return empty string if can not get key
func hl#GetCacheKey(buf_name)
  " we use md5 of buffers as cache keys
  let input   = getbufline(a:buf_name, 1, "$")
  let md5sum  = system("md5sum", input)
  if v:shell_error != 0 " error
    return ""
  endif

  return md5sum
endfunc

func hl#CheckInCache(buf_name)
  if has_key(g:hl_cache, a:buf_name)
    if hl#GetCacheKey(a:buf_name) == g:hl_cache[a:buf_name][0]
      return g:hl_cache[a:buf_name][1]
    else
      unlet g:hl_cache[a:buf_name] " invalidate cache
    endif
  endif

  return {}
endfunc

func hl#PutInCache(buf_name, tokens)
  " FIXME here is a problem with asynchronous callbacks, because md5 (which we
  " use as cache key) can change at the time when the tokens will be get
  let l:cache_key = hl#GetCacheKey(a:buf_name)
  if strlen(l:cache_key) != 0
    let g:hl_cache[a:buf_name] = [l:cache_key, a:tokens]
  endif
endfunc


func hl#MissedMsgCallback(channel, msg)
  let g:hl_last_error = "missed message"
endfunc

func hl#SetHighlight(win_id, tokens)
  " and add new heighligth
  for [l:hl_group, l:locations] in items(a:tokens)
    " XXX We must be confident, that we have higlight for the group

    let l:hi_link = "" " for debug you can set some value here, for example Label
    if has_key(g:hl_group_to_hi_link, l:hl_group)
      let l:hi_link = g:hl_group_to_hi_link[l:hl_group]
    endif

    if empty(l:hi_link) == 0
      for l:location in l:locations
        let l:match = matchaddpos(l:hi_link, [l:location], 0, -1,
              \ {"window": a:win_id})
        if l:match != -1 " otherwise invalid match
          call add(w:matches, l:match)
        endif
      endfor
    endif
  endfor
endfunc

func hl#HighlightCallback(channel, msg)
  " check that request was processed properly
  if a:msg.version != "v1"
    let g:hl_last_error = "invalid version of response"
  endif

  if a:msg.return_code != 0
    let g:hl_last_error = a:msg.error_message

    if empty(a:msg.tokens) == 1
      return
    end " otherwise try add highlight
  endif

  let l:win_id = a:msg.id
  let l:buf_name = a:msg.buf_name
  call hl#PutInCache(l:buf_name, a:msg.tokens)
  if win_getid() != l:win_id || bufname("%") != l:buf_name
    return
  endif

  " before set new highlight we need remove previous
  call hl#ClearWinMatches(l:win_id)

  call hl#SetHighlight(l:win_id, a:msg.tokens)
endfunc

" return flags for current buffer as list
func hl#GetCompilationFlags()
  let l:flags = []
  let l:config_file = findfile(".color_coded", ".;")
  if empty(l:config_file) == 0
    let l:tmp_flags = readfile(l:config_file)

    " some of -I flags can be relative, so we should set it as absolute
    let l:config_path = fnamemodify(l:config_file, ":p:h")
    for l:tmp_flag in l:tmp_flags
      if match(l:tmp_flag, "^-I\\w") != -1 || match(l:tmp_flag, "^-I\./") != -1
        let l:flag = substitute(l:tmp_flag, "^-I", "-I" .. l:config_path .. "/", "")
        call add(l:flags, l:flag)
      else
        call add(l:flags, l:tmp_flag)
      endif
    endfor
  end

  " also add current dir as include path
  call add(l:flags, "-I" .. expand("%:p:h"))

  return l:flags
endfunc

func hl#SendRequest(win_id, buf_type, channel)
  let l:buf_body = join(getline(1, "$"), "\n")

  let l:compile_flags = hl#GetCompilationFlags()

  let l:request = {} 
  let l:request["version"]         =  "v1"
  let l:request["id"]              =  a:win_id
  let l:request["buf_type"]        =  a:buf_type
  let l:request["buf_name"]        =  bufname("%")
  let l:request["buf_body"]        =  l:buf_body
  let l:request["additional_info"] =  join(l:compile_flags, "\n")

  call ch_sendexpr(a:channel, l:request, {"callback": "hl#HighlightCallback"})
endfunc


func hl#TryHighlightThisBuffer()
  let l:win_id    = win_getid()
  let l:buf_type  = &filetype
  let l:buf_name  = bufname("%")

  if count(g:hl_supported_types, l:buf_type) != 0
    " try get values from cache
    let l:tokens = hl#CheckInCache(l:buf_name)
    if empty(l:tokens) == 0
      call hl#ClearWinMatches(l:win_id)
      call hl#SetHighlight(l:win_id, l:tokens)
      return
    endif

    " send request to hl-server
    let l:channel = hl#GetConnect()
    if ch_status(l:channel) == "open"
      call hl#SendRequest(l:win_id, l:buf_type, l:channel)
    endif
  else
    " otherwise we need clear mathces from previous buffer (if they exists)
    call hl#ClearWinMatches(l:win_id)
  endif
endfunc


" colors
hi default Member         cterm=NONE ctermfg=147
hi default Variable       cterm=NONE ctermfg=white
hi default EnumConstant   cterm=NONE ctermfg=DarkGreen
hi default Namespace      cterm=bold ctermfg=46
