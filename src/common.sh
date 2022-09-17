#!/bin/bash
CONFIG_FILE="$HOME/.dev-machine/config/dev-machine.config.yml"
NETWORK_DIR="$HOME/.dev-machine/network"
DISC_DIR="$HOME/.dev-machine/discs"
TMP_DIR="$HOME/.dev-machine/tmp"
HELPERS_DIR="$HOME/.dev-machine/helpers"

_print_style() {
    if [ "$2" == "info" ]; then
        COLOR="94m"
    elif [ "$2" == "success" ]; then
        COLOR="92m"
    elif [ "$2" == "warning" ]; then
        COLOR="93m"
    elif [ "$2" == "danger" ]; then
        COLOR="91m"
    else #default color
        COLOR="0m"
    fi

    STARTCOLOR="\e[$COLOR"
    ENDCOLOR="\e[0m"

    printf "$STARTCOLOR%b$ENDCOLOR" "$1"
}

_confirm() {
    ACTION="danger"
    if [ -n "$2" ]; then
        ACTION="$2"
    fi
    _print_style "${1}\n" $ACTION

    PS3="Enter a number: "

    select action in "YES" "NO"; do
        if [ $action == 'YES' ]; then
            return
        fi
        _print_style "ACTION TERMINATED\n" "danger"

        exit 1
    done
}

_load_local_env() {
    eval "$(egrep -v "^#" .env | awk 'NF' | sed -e 's/=\(.*\)/="\1/g' -e 's/$/"/g')"
}

_logo() {
    echo '                                                                                                                                   
                   _________
                  / ======= \
                 / __________\
                | ___________ |
                | | -       | |
                | |         | |
                | |_________| |________________________
                \=____________/   DEV MACHINE for mac  )
                / """"""""""" \                       /
               / ::::::::::::: \                  =D-
              (_________________)
                                                          
                                                    '
}

_header() {
    clear
    _logo
}

_get_env() {
    echo ${!1}
}

_as_admin() {
    osascript -e "do shell script \"$1\" with administrator privileges"
}

_get_config_value() {
    _get_env "GLOBAL_dev_machine_$1"
}

help_doc="Help menu"
_help() {
    _print_style "Usage:\n" "warning"
    printf "   dev-machine $1 [target]\n\n"
    _print_style "Available targets in $1:\n" "warning"
    PUBLIC_FUNCTIONS=$(declare -F | awk '{print $NF}' | egrep -v "^_")
    printf "   \033[1m%-25b %-25b \033[0m\n" "Name:" "Doc:"
    for function in $PUBLIC_FUNCTIONS; do
        function_var="${function}_doc"
        doc="${!function_var}"
        if [ -z "$doc" ]; then
            printf "   \e[92m%-25s\e[0m %-25s\n" $function "No documentation. Add ${function}_doc=\"doc\" above the ${function}() function"
        else
            printf "   \e[92m%-25s\e[0m %-25s\n" $function "$doc"
        fi
    done
}

_common_update_env() {
    KEY=$1
    VALUE=$2
    (sed '/^'$KEY'/s/=.*$/='$VALUE'/' .env) >.env2
    rm .env
    mv .env2 .env
    _load_local_env
}

# $1 = human repo name
# $2 = repo url
_check_repo() {
    origin=$(git config --get remote.origin.url)
    if [ -z $origin ]; then
        _print_style "Git not found\n" "danger"
        exit 1
    fi
    if [ $origin != $2 ]; then
        _print_style "This is not $1... Sorry.\n" "warning"
        exit 1
    fi
}

# $1 file
# $2 prefix
_parse_yaml() {
    local prefix=$2
    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @ | tr @ '\034')
    sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
        awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# $1 path one
# $2 path two
_check_path() {
    if [ $1 != $2 ]; then
        _print_style "This is not on the server... Sorry.\n" "warning"
        exit 1
    fi
}

_set_server_name() {
    servers=$(declare -p | grep '^GLOBAL_servers_')
    for server in $servers; do
        IFS='='
        read -ra server_data <<<"$server"
        server_name=${server_data[0]}
        server_ip=${server_data[1]}
        # THIS_SERVER_NAME will be global
        if [ $THIS_SERVER_IP == $server_ip ]; then
            THIS_SERVER_NAME=${server_name//"GLOBAL_servers_"/""}
        fi
    done
}

# $1 = service from .lp-tools.config.yml
# $2 method
_run() {
    shift 1
    $@
}

if [ ! -f $CONFIG_FILE ]; then
    _print_style "No config file\n" "danger"
    _confirm "Do you want to configure it now?"
    echo $(cat $HOME/.dev-machine/config/dev-machine.config.yml-template >$CONFIG_FILE)
    ~/.dev-machine/src/qemu.sh setup
    exit 1
else
    eval $(_parse_yaml $CONFIG_FILE "GLOBAL_")
fi

BUTLER_DIR=$(_get_config_value "file_butler_directory")
if [ ! -f $BUTLER_DIR ]; then
    mkdir -p $BUTLER_DIR
fi
