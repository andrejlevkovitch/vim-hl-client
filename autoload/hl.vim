let g:hl_server_addr = "localhost:9173"
let g:hl_supported_types = ["cpp", "c"]
let g:hl_last_error = ""

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
      \ "Variable"                            : "Variable",
      \ "VarDecl"                             : "Variable",
      \ "ParmDecl"                            : "Variable",
      \ "VariableRef"                         : "Variable",
      \ "NonTypeTemplateParameter"            : "Variable",
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


" Connect to hl_server
let g:hl_server_channel = ch_open(g:hl_server_addr, {"mode": "json", "callback": "hl#MissedMsgCallback"})

func hl#TryConnect()
  if ch_status(g:hl_server_channel) != "open"
    let g:hl_server_channel = ch_open(g:hl_server_addr, {"mode": "json", "callback": "hl#MissedMsgCallback"})
  endif
endfunc


func hl#ClearWinMatches(win_id)
  if exists("w:matches")
    for l:match in w:matches
      call matchdelete(l:match, a:win_id)
    endfor
  endif

  let w:matches = []
endfunc


func hl#MissedMsgCallback(channel, msg)
  let g:hl_last_error = "missed message"
endfunc

func hl#HighlightCallback(channel, msg)
  " check that request was processed properly
  if a:msg.return_code != 0
    let g:hl_last_error = a:msg.error_message

    if empty(a:msg.tokens) == 1
      return
    end " otherwise try add highlight
  endif

  let l:win_id = a:msg.id
  if win_getid() != l:win_id
    return
  endif

  " at first clear all matches
  call hl#ClearWinMatches(l:win_id)

  " and add new heighligth
  for [l:hl_group, l:locations] in items(a:msg.tokens)
    " XXX We must be confident, that we have higlight for the group

    let l:hi_link = "" " for debug you can set some value here, for example Label
    if has_key(g:hl_group_to_hi_link, l:hl_group)
      let l:hi_link = g:hl_group_to_hi_link[l:hl_group]
    endif

    if empty(l:hi_link) == 0
      for l:location in l:locations
        let l:match = matchaddpos(l:hi_link, [l:location], 0, -1, {"window": l:win_id})
        if l:match != -1 " otherwise invalid match
          call add(w:matches, l:match)
        endif
      endfor
    endif
  endfor
endfunc

" return flags for current buffer as list
func hl#GetCompilationFlags()
  let l:config_file = findfile(".color_coded", ".;")
  if empty(l:config_file) == 0
    let l:flags = readfile(l:config_file)
    call add(l:flags, "-I" . expand("%:p:h")) " also add current dir as include path

    return l:flags
  end

  return []
endfunc

func hl#SendRequest(win_id, buf_type)
  let l:buf_body = join(getline(1, "$"), "\n")

  let l:compile_flags = hl#GetCompilationFlags()

  let l:request = {} 
  let l:request["id"] =         a:win_id
  let l:request["buf_type"] =   a:buf_type
  let l:request["buf_name"] =   buffer_name("%")
  let l:request["buf_body"] =   l:buf_body
  let l:request["additional_info"] = join(l:compile_flags, "\n")

  call ch_sendexpr(g:hl_server_channel, l:request, {"callback": "hl#HighlightCallback"})
endfunc

func hl#TrySendRequestForThisBuffer()
  let l:win_id = win_getid()
  let l:buf_type = &filetype

  call hl#TryConnect()
  if count(g:hl_supported_types, l:buf_type) != 0 && ch_status(g:hl_server_channel) == "open"
    call hl#SendRequest(l:win_id, l:buf_type)
  else
    call hl#ClearWinMatches(l:win_id)
  endif
endfunc


" colors
hi default Member         cterm=NONE ctermfg=147
hi default Variable       cterm=NONE ctermfg=white
hi default EnumConstant   cterm=NONE ctermfg=DarkGreen
hi default Namespace      cterm=bold ctermfg=46
