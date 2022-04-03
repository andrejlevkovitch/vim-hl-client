.DEFAULT=build

cur_dir=$(shell pwd)
go:=$(shell go version 2> /dev/null)

build: submodule-update
	@mkdir -p build
ifdef go
	@cd build && cmake -DGO_TOKENIZER=ON ../third-party/hl-server
else
	@cd build && cmake ../third-party/hl-server
endif
	@cmake --build build -- -j4
	@echo ""
	@echo "Please add 'let g:hl_server_binary=\"${cur_dir}/build/bin/hl-server\"' to your .vimrc file!"

clean:
	@rm -rf build

submodule-update:
	@git submodule update --init --recursive

go-version:
ifdef go
	@echo ${go}
else
	@echo "go not found"
endif
