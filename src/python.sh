source ~/.dev-machine/scripts/common.sh

#### PRIVATE
PYTHON_SERVICE='python'
COMPOSE_FILE='docker-compose.yml'
GATEWAY_MIDDLEWARE_SERVICE='gateway'
CONFIG_SETTING="ltc_engine"

_is_container_ready() {
    container_id=$1
    retry_limit=5
    gateway_id=$(docker-compose -f $COMPOSE_FILE ps -q $GATEWAY_MIDDLEWARE_SERVICE | tail -n1)
    new_container_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_id)
    DATA=$(docker exec $gateway_id curl --silent --include --retry-connrefused --retry $retry_limit --retry-delay 1 --fail http://$new_container_ip:80/api/ping || exit 1)
}

_reload_api_gateway() {
    gateway_id=$(docker-compose -f $COMPOSE_FILE ps -q $GATEWAY_MIDDLEWARE_SERVICE | tail -n1)
    docker exec -it $gateway_id nginx -s reload
}

_change_version() {
    if [ $PYTHON_VERSION == $1 ]; then
        echo Versions are the same $PYTHON_VERSION " == " $1
        exit 0
    fi
    _common_update_env 'PYTHON_VERSION' $1

    old_container_id=$(docker-compose -f $COMPOSE_FILE ps -q $PYTHON_SERVICE | head -n1)
    docker-compose -f $COMPOSE_FILE up -d --no-deps --scale $PYTHON_SERVICE\=2 --no-recreate $PYTHON_SERVICE
    new_container_id=$(docker-compose -f $COMPOSE_FILE ps -q $PYTHON_SERVICE | egrep -v "$old_container_id" | head -n1)

    echo $new_container_id
    echo $old_container_id
    (
        _is_container_ready $new_container_id
        _reload_api_gateway
        echo "Stopping old container"
        docker stop $old_container_id
        docker rm $old_container_id
        docker-compose -f $COMPOSE_FILE up -d --no-deps --scale $service_name\=1 --no-recreate $service_name
        _reload_api_gateway
    ) || (
        echo "Something failed, you need to manually chenge the version"
        echo "Stopping new failed container"
        docker stop $new_container_id
        docker rm $new_container_id
        docker-compose -f $COMPOSE_FILE up -d --no-deps --scale $service_name\=1 --no-recreate $service_name
    )
}

### PUBLIC

help() {
    _help "engine"
}

build_console_env=$LOCAL_METHOD
build_console_doc="Building local development console image"
build_console() {
    _print_style "Building engine console...\n" "info"
    docker build -t ladis-python-console:latest -f ./docker/console/Dockerfile .
}

start_env=$LOCAL_METHOD
start_doc="Starting dev environment"
start() {
    _print_style "Strarting engine...\n" "info"
    docker-compose -f docker-compose.console.yml up -d
}

stop_env=$LOCAL_METHOD
stop_doc="Stopping dev environment"
stop() {
    _print_style "Stopping engine...\n" "info"
    docker-compose -f docker-compose.console.yml down
}

console_env=$LOCAL_METHOD
console_doc="Builds console image, starts, and opens started container"
console() {
    build_console
    start
    _print_style "Launching console...\n" "info"
    docker exec -it ladis_python_console zsh
}

change_version_env=$SERVER_METHOD
change_version_doc="Changing version for python service. Usage: 'lp-tools adapter change_version X.Y.Z-BUILD_NO'"
change_version() {
    _docker_stop_when_container_not_running 'python'
    _print_style "Updating console $THIS_SERVER_NAME...\n" "info"

    if [ -z $1 ]; then
        _print_style "You are missing version X.Y.Z-BUILD_NO\n" "danger"
        exit 1
    fi
    _load_local_env
    _change_version ${1}
}

if ! [ -z $1 ]; then
    _run $CONFIG_SETTING $1 $@
else
    help
fi
