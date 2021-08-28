# vim-hl-client: semantic highlighting for c/c++ in vim

Fast asynchronous vim client for hl-server.
Provide semantic highlighting for `c` and `cpp` (based on `clang`).
Uses [.color_coded](https://github.com/rdnetto/YCM-Generator) file for specify
compile flags for analizing.

__use version protocol__: v1.1


## Requirements

- `vim 8.2` (can be used `vim 8` with branch `win-matching`)

- [hl-server](https://github.com/andrejlevkovitch/hl-server)


## Installation

1. Use [vundle](https://github.com/VundleVim/Vundle.vim) for install this plagin

```vim
Plugin 'andrejlevkovitch/vim-hl-client'
```

2. Compile [hl-server](third-party/hl-server) by `cmake`. Just call:

```sh
mkdir build
cd build
cmake ../third-party/hl-server
cmake --build .
```

__NOTE__ that you need installed `boost`

3. Add to your `.vimrc` file next line:

```vim
let g:hl_server_binary  = "/path/to/hl-server/binary"
```

This command starts your `hl-server` automaticly after starting `vim`


## Additional settings

- set port for server manually
```vim
let g:hl_server_port    = 53827
```

- debug mode for `hl-server`. All logs will write in debug file.
```vim
let g:hl_debug_file     = "/path/to/debug/file"
```


- for check some errors you can call:
```vim
echo HLServerLastError()
```

- for restarting `hl-server` you can run command:
```vim
call HLServerStop()
call HLServerStart()
```

- for check status of `hl-server` you can call

```vim
call HLServerStatus()
```

__NOTE__ that `hl-server` can be started only ones (with same port), so if you
run other instance of vim this command return that `hl-server` is _dead_


## Why should not use color-coded

[color-coded](https://github.com/jeaye/color_coded) is similar plugin for
semantic highlighting for `c/c++`.  I used it previously, but it has several
serious problems, like:

- need `vim`, compiled with `lua` support

- impassible to integrate the plugin with other editors

- hard for debug

- low stability - `color-coded` crashes sometimes and crashes `vim` also!

- speed and memory - `color-coded` can use above 2Gb of memory and can work very
slowly with big files


## Why vim-hl-client is better then color-coded

- this plugin has client-server architecture: [vim-hl-client](https://github.com/andrejlevkovitch/vim-hl-client)
as client and [hl-server](https://github.com/andrejlevkovitch/hl-server) as
server. So vim don't need some extra features like `be compiled with lua support`.
It works with standard features __only__ (jobs, channels, textproperties).

- absolutly asynchronous. `vim-hl-client` uses standard `vim` asynchronous
features like `channels` and `callbacks` for calling requests. All tasks handles
on server side.

- simple to debug. Server is a separate program, you can start it by `gdb`, or
just see logs

- high stability. Even if `hl-server` will crash, `vim` will work as expected,
but without highlighting.

- `hl-server` absolutly independent from `vim`, so you can integrate it with
other editors - just create you own `*-hl-client`


## Bugs

After updating plugin you can get notice that you should recompile [hl-server](http://github.com/andrejlevkovitch/hl-server).
Highly recomended remove previous cmake configs and generate new.

```bash
cd build
rm * -r
cmake ..
cmake --build . -- -j4
```


Also note, that debug file truncate every time when new instance of vim raised.
So, if you set `g:hl_debug_file` like a static file, then you may have a problem
with save it, or even reading (you can't open it by new instance of vim, because
it will be trancated before opening). So highly recomended set debug file as:

```vim
let g:hl_debug_file = "/path/to/file" . localtime()
```

In this case every instance of vim will has your own debug file
