" variables
let s:current_protocol_version  = "v1.1"
let s:hl_last_error             = "no errors"
let s:hl_supported_types        = ["cpp", "c"]
let s:prop_user_id              = 7936

" cache is a map with structure:
" {
"   buf_name: [cache_key, tokens]
" }
let s:hl_cache            = {}

let s:hl_group_to_hi_link = {
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


func hl#InitPropertieTypes()
  let l:buf       = bufname("%")
  let l:buf_type  = getbufvar(l:buf, "&filetype")

  if count(s:hl_supported_types, l:buf_type) != 0
    for l:type in keys(s:hl_group_to_hi_link)
      let l:hi = s:hl_group_to_hi_link[l:type]
      call prop_type_add(l:type, {"highlight": l:hi, "bufnr": l:buf})
    endfor
  endif
endfunc


" one connection per window
func hl#GetConnect()
  if exists("w:hl_server_channel") == 0 ||
        \ ch_status(w:hl_server_channel) != "open"
    let w:hl_server_channel = ch_open(g:hl_server_addr,
          \ {"mode": "json", "callback": "hl#MissedMsgCallback"})
  endif

  return w:hl_server_channel
endfunc


func hl#ClearTextProperties(buf)
  call prop_remove({
        \"bufnr" : a:buf,
        \"id"    : s:prop_user_id
        \})
endfunc

func hl#SetTextProperties(buf, tokens)
  for [l:hl_group, l:locations] in items(a:tokens)
    " XXX We must be confident, that we have higlight for the group
    let l:hi_link = "" " for debug you can set some value here, for example Label
    if has_key(s:hl_group_to_hi_link, l:hl_group)
      let l:hi_link = s:hl_group_to_hi_link[l:hl_group]
    endif

    if empty(l:hi_link) == 0
      for l:location in l:locations
        call prop_add(l:location[0], l:location[1],
              \{ "length"  : l:location[2],
              \"type"    : l:hl_group,
              \"bufnr"   : a:buf,
              \"id"      : s:prop_user_id
              \})
      endfor
    endif
  endfor
endfunc


" @return empty string if can not get key
func hl#CalcControlSum(buffer_content)
  let l:rows                = len(a:buffer_content)
  let l:count               = len(join(a:buffer_content, "\n"))

  return string(l:count) .. "*" .. string(l:rows)
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

  let l:buffer_content      = getbufline(l:buf_name, 1, "$")
  let l:current_control_sum = hl#CalcControlSum(l:buffer_content)

  if l:current_control_sum != l:message_control_sum
    " information already expired
    return
  endif

  call hl#ClearTextProperties(l:buf_name)
  call hl#SetTextProperties(l:buf_name, a:msg.tokens)
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
func hl#SendRequest(channel, buf_name, buffer_content, buf_type, cache_key)
  let l:compile_flags = join(hl#GetCompilationFlags(), "\n")
  let l:buf_body = join(a:buffer_content, "\n")

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
  let l:buf_name  = bufname("%")
  let l:buf_type  = getbufvar(l:buf_name, "&filetype")

  if count(s:hl_supported_types, l:buf_type) != 0
    let l:buffer_content  = getbufline(l:buf_name, 1, "$")
    let l:cache_key       = hl#CalcControlSum(l:buffer_content)
    let l:channel         = hl#GetConnect()

    " send request to hl-server
    if ch_status(l:channel) == "open"
      call hl#SendRequest(l:channel, l:buf_name, l:buffer_content, l:buf_type, l:cache_key)
    endif
  endif
endfunc

func hl#GetLastError()
  return s:hl_last_error
endfunc

" colors
hi default Member         cterm=NONE ctermfg=147
hi default Variable       cterm=NONE ctermfg=white
hi default EnumConstant   cterm=NONE ctermfg=DarkGreen
hi default Namespace      cterm=bold ctermfg=46
