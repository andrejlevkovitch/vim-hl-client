" variables
let s:current_protocol_version  = "v1.1"
let s:hl_last_error             = ""
let s:hl_supported_types        = ["cpp", "c"]

" cache is a map with structure:
" {
"   buf_name: [cache_key, tokens]
" }
let s:hl_cache            = {}

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


" one connection per window
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

func hl#SetWinMatches(win_id, tokens)
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


" return empty string if can not get key
func hl#GetCacheKey(buffer)
  " we use md5 of buffer as cache keys
  let l:md5sum  = system("md5sum", a:buffer)
  if v:shell_error != 0 " error
    return ""
  endif

  return l:md5sum
endfunc

func hl#GetFromCache(buf_name, cache_key)
  if has_key(s:hl_cache, a:buf_name)
    if a:cache_key == s:hl_cache[a:buf_name][0]
      return s:hl_cache[a:buf_name][1]
    else
      unlet s:hl_cache[a:buf_name] " invalidate cache
    endif
  endif

  return {}
endfunc

func hl#PutInCache(buf_name, cache_key, tokens)
  if strlen(a:cache_key) != 0
    let s:hl_cache[a:buf_name] = [a:cache_key, a:tokens]
  endif
endfunc


func hl#MissedMsgCallback(channel, msg)
  let s:hl_last_error = "missed message"
endfunc

func hl#HighlightCallback(channel, msg)
  " check that request was processed properly
  if a:msg.version != s:current_protocol_version
    let s:hl_last_error = "invalid version of response"
  endif

  if a:msg.return_code != 0
    let s:hl_last_error = a:msg.error_message

    if empty(a:msg.tokens) == 1
      return
    end " otherwise try add highlight
  endif

  let l:buf_name            = a:msg.buf_name
  let l:message_control_sum = a:msg.id

  let l:buffer              = getbufline(l:buf_name, 1, "$")
  let l:current_control_sum = hl#GetCacheKey(l:buffer)

  if l:current_control_sum == l:message_control_sum
    call hl#PutInCache(l:buf_name, l:message_control_sum, a:msg.tokens)
  else
    " information already expired
    return
  endif

  if bufname("%") != l:buf_name
    " at this time we use another buffer
    return
  endif

  " before set new highlight we need remove previous
  let l:win_id = win_getid()
  call hl#ClearWinMatches(l:win_id)

  call hl#SetWinMatches(l:win_id, a:msg.tokens)
endfunc

" @return list of flags for current buffer
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

" @param buffer list of buffer strings
func hl#SendRequest(channel, buf_name, buffer, buf_type, cache_key)
  let l:compile_flags = join(hl#GetCompilationFlags(), "\n")
  let l:buf_body = join(a:buffer, "\n")

  let l:request = {} 
  let l:request["version"]         =  s:current_protocol_version
  let l:request["id"]              =  a:cache_key " use as control field
  let l:request["buf_type"]        =  a:buf_type
  let l:request["buf_name"]        =  a:buf_name
  let l:request["buf_body"]        =  l:buf_body
  let l:request["additional_info"] =  l:compile_flags

  call ch_sendexpr(a:channel, l:request, {"callback": "hl#HighlightCallback"})
endfunc


func hl#TryHighlightThisBuffer()
  let l:win_id    = win_getid()
  let l:buf_type  = &filetype
  let l:buf_name  = bufname("%")

  if count(s:hl_supported_types, l:buf_type) != 0
    let l:buffer    = getbufline(l:buf_name, 1, "$")
    let l:cache_key = hl#GetCacheKey(l:buffer)

    " try get values from cache
    let l:tokens    = hl#GetFromCache(l:buf_name, l:cache_key)
    if empty(l:tokens) == 0
      call hl#ClearWinMatches(l:win_id)
      call hl#SetWinMatches(l:win_id, l:tokens)
      return
    endif

    " send request to hl-server
    let l:channel = hl#GetConnect()
    if ch_status(l:channel) == "open"
      call hl#SendRequest(l:channel, l:buf_name, l:buffer, l:buf_type, l:cache_key)
    endif
  else
    " otherwise we need clear mathces from previous buffer (if they exists)
    call hl#ClearWinMatches(l:win_id)
  endif
endfunc

func hl#PrintLastError()
  echo s:hl_last_error
endfunc

" colors
hi default Member         cterm=NONE ctermfg=147
hi default Variable       cterm=NONE ctermfg=white
hi default EnumConstant   cterm=NONE ctermfg=DarkGreen
hi default Namespace      cterm=bold ctermfg=46
