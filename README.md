# vim-hl-client

Fast asynchronous vim client for hl-server.
Provide syntax highlighting for `c` and `cpp` (based on `clang`).
Uses [.color_coded](https://github.com/rdnetto/YCM-Generator) file for specify compile flags for analizing.
You need started [hl-server](https://github.com/andrejlevkovitch/hl-server) for using it.

__use version protocol__: v1.1


For run `hl-server` automaticly you need `vim 8` and [AsyncRun](https://github.com/skywind3000/asyncrun.vim) plugin.
After compilation `hl-server` just add to your `.vimrc` file next string:

```vim
au VimEnter * AsyncRun /path/to/hl-server/binary --threads=2
```
