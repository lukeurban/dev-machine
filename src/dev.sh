source $HOME/.dev-machine/src/common.sh

help() {
    _help "dev"
}

build_forward_doc="Builds console image, starts, and opens started container"
build_forward() {
    go build -o $HOME/.dev-machine/bin/forward $HOME/.dev-machine/src/forward.go
}

if ! [ -z $1 ]; then
    _run $1 $@
else
    help
fi
