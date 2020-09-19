# vim-hl-client

Fast asynchronous vim client for hl-server.
Provide syntax highlighting for `c` and `cpp` (based on `clang`).
Uses [.color_coded](https://github.com/rdnetto/YCM-Generator) file for specify compile flags for analizing.
You need started [hl-server](https://github.com/andrejlevkovitch/hl-server) for using it.

__use version protocol__: v1.1


For run `hl-server` automaticly you need `vim 8` and [AsyncRun](https://github.com/skywind3000/asyncrun.vim) plugin.
After compilation `hl-server` just add to your `.vimrc` file next string:

```vim
let g:hl_server_binary  = "/path/to/hl-server/binary"
```


Also you can add next variables

```vim
" default is 'localhost:53827'
let g:hl_server_addr    = "localhost:53827"

" default is 3
let g:hl_server_threads = 3

" for debugging
let g:hl_debug_file     = "/path/to/debug/file"
```
