source ~/.dev-machine/src/common.sh

### PUBLIC
NETWORK_DIR=~/.dev-machine/network

help() {
    _help "network"
}

forward_doc="Forwarding port from host to VM: Usage: dev-machine network forward HOST_PORT VM_PORT"
forward() {
    IP=$(cat $TMP_DIR/ip | awk '{print $1}' | head -1)
    WITH_PORT=$(printf "%s:%s\n" "$IP" "$2")
    $HOME/.dev-machine/bin/forward $1 $WITH_PORT
}

if ! [ -z $1 ]; then
    _run $1 $@
else
    help
fi
