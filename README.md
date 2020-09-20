# vim-hl-client: semantic highlighting for c/c++ in vim

Fast asynchronous vim client for hl-server.
Provide semantic highlighting for `c` and `cpp` (based on `clang`).
Uses [.color_coded](https://github.com/rdnetto/YCM-Generator) file for specify compile flags for analizing.

__use version protocol__: v1.1


## Requirements

- `vim 8` (not tested with less versions, but, I think, can works with `7.4` version)

- [hl-server](https://github.com/andrejlevkovitch/hl-server)

- [AsyncRun](https://github.com/skywind3000/asyncrun.vim) (not required, need for automatical start of `hl-server`)


## Installation

1. Use [vundle](https://github.com/VundleVim/Vundle.vim) for install this plagin and [hl-server](https://github.com/andrejlevkovitch/hl-server)

2. Compile `hl-server` by `cmake`. Just call:

```sh
mkdir build
cd build
cmake ..
cmake --build .
```

__NOTE__ that you need installed `boost`

3. Install [AsyncRun](https://github.com/skywind3000/asyncrun.vim) plugin. It is needed for
asynchronous start of `hl-server`

4. Add to your `.vimrc` file next line:

```vim
let g:hl_server_binary  = "/path/to/hl-server/binary"
```

This command starts your `hl-server` automaticly after starting `vim`


## Additional settings

- set address for server manually
```vim
let g:hl_server_addr    = "localhost:53827"
```

- set capacity of threads for `hl-server`
```vim
let g:hl_server_threads = 3
```

- debug mode for `hl-server`. All logs will write in debug file.
```vim
let g:hl_debug_file     = "/path/to/debug/file"
```


- for check some errors you can call:
```vim
echo HLLastError()
```

- for restarting (only if you has `AsuncRun` plugin) `hl-server` you can run command:
```vim
call HLStopServer()
call HLRestartServer()
```


## Why should not use color-coded

[color-coded](https://github.com/jeaye/color_coded) is similar plugin for semantic highlighting for `c/c++`.
I used it previously, but it has several serious problems, like:

- need `vim`, compiled with `lua` support

- impassible to integrate the plugin with other editors

- hard for debug

- low stability - `color-coded` crashes sometimes and crashes `vim` also!

- speed and memory - `color-coded` can use above 2Gb of memory and can work very slowly with big files


## Why vim-hl-client is better then color-coded

- this plugin has client-server architecture: [vim-hl-client](https://github.com/andrejlevkovitch/vim-hl-client)
as client and [hl-server](https://github.com/andrejlevkovitch/hl-server) as server. So vim don't need some extra
features like `be compiled with lua support`. It needes only `channels` support (`AsyncRun` isn't required, but it
is needed for automaticly start `hl-server`)

- absolutly asynchronous. `vim-hl-client` uses standard `vim` asynchronous features like `channels` and `callbacks` for
calling requests. All tasks handles on server side.

- simple to debug. Server is a separate program, you can start it by `gdb`, or just see logs

- high stability. Even if `hl-server` will crash, `vim` will work as expected, but without highlighting.

- `hl-server` absolutly independent from `vim`, so you can integrate it with other editors - just create you own
`*-hl-client`
