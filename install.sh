#!/bin/bash

moveDir() {
    DIR=$(pwd)
    mkdir -p ~/.dev-machine
    cd ..
    mv $DIR/{,.}* ~/.dev-machine
}

copyExecutable() {
    if [ "$(uname)" == "Darwin" ]; then
        sudo ln -s ~/.dev-machine/dev-machine /usr/local/bin/dev-machine
    else
        sudo ln -s ~/.dev-machine/dev-machine /usr/bin/dev-machine
    fi
}

copyExecutable
