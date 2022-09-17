source ~/.dev-machine/src/common.sh

### PUBLIC

help() {
    _help "vm"
}

setup() {
    if [ -z "$EDITOR" ]; then
        echo "Your \$EDITOR is not set"
        printf "Add 'export EDITOR=xxx' to your .bashrc file"
        exit
    fi

    if [ ! -f $CONFIG_FILE ]; then
        cp ~/dev-machine/config/.dev-machine.config.yml-template $CONFIG_FILE
    fi

    $EDITOR $CONFIG_FILE
}

start() {
    mkdir -p $TMP_DIR
    if [ -f "$TMP_DIR/pidfile.txt" ]; then
        PROCESS=$(cat $TMP_DIR/pidfile.txt)
        proc=$(ps aux | grep -v grep | grep "\" $PROCESS \"")
        if [ -z "$proc" ]; then
             _as_admin "qemu-system-x86_64 \
                -m $(_get_config_value "memory_size") \
                -smp $(_get_config_value "cores") \
                -net nic,model=virtio,macaddr=54:54:00:55:55:55 \
                -net tap,script=$NETWORK_DIR/tap-up,downscript=$NETWORK_DIR/tap-down \
                -nic hostfwd=tcp:127.0.0.1:2222-:22 \
                -vga virtio \
                -virtfs local,path=$(_get_config_value "file_butler_directory"),mount_tag=host0,security_model=mapped,id=host0 \
                -drive file=$DISC_DIR/devm.qcow2,if=virtio \
                -display default,show-cursor=on \
                -usb \
                -device usb-tablet \
                -cpu host \
                -machine type=q35,accel=hvf \
                -display none -daemonize -pidfile $TMP_DIR/pidfile.txt &"
        fi
    else
        _as_admin "qemu-system-x86_64 \
                -m $(_get_config_value "memory_size") \
                -smp $(_get_config_value "cores") \
                -net nic,model=virtio,macaddr=54:54:00:55:55:55 \
                -net tap,script=$NETWORK_DIR/tap-up,downscript=$NETWORK_DIR/tap-down \
                -nic hostfwd=tcp:127.0.0.1:2222-:22 \
                -vga virtio \
                -virtfs local,path=$(_get_config_value "file_butler_directory"),mount_tag=host0,security_model=mapped,id=host0 \
                -drive file=$DISC_DIR/devm.qcow2,if=virtio \
                -display default,show-cursor=on \
                -usb \
                -device usb-tablet \
                -cpu host \
                -machine type=q35,accel=hvf \
                -display none -daemonize -pidfile $TMP_DIR/pidfile.txt &"
    fi  
    _print_style "Dev machine is starting\n" "info"
    create_mount_point
}

create_mount_point() {
    # TODO: check if GLOBAL_system_user has sudo group and execute command
    ssh -p 2222 -t $GLOBAL_system_user@127.0.0.1 " 
    sudo mkdir -p /home/shared &&\
    sudo mountpoint -q /home/shared && echo \"Ready!\" || sudo mount -t 9p -o trans=virtio,version=9p2000.L host0 /home/shared" 2>/dev/null
    # TODO: Add napasswd to user
    # TODO: Add "allow-hotplug enp0s3  iface enp0s3 inet dhcp" => /etc/network/interfaces

    # sudu echo $GLOBAL_system_user ALL=(ALL) NOPASSWD: ALL >> /etc/sudoers
    ssh -p 2222 -t $GLOBAL_system_user@127.0.0.1 "hostname -I | awk '{print \$1}'" >$TMP_DIR/ip 2>/dev/null
}

connect() {
    ssh -p 2222 $GLOBAL_system_user@127.0.0.1
}

shutdown() {
    _print_style "Dev machine shutdown\n" "info"
    ssh -p 2222 -t $GLOBAL_system_user@127.0.0.1 "sudo shutdown -P now"
    _as_admin "echo "" > $TMP_DIR/pidfile.txt"
}

kill() {
    if [ -f "$TMP_DIR/pidfile.txt" ]; then
        shutdown
        _as_admin "kill -9 $(cat $TMP_DIR/pidfile.txt) && echo "" > $TMP_DIR/pidfile.txt"
    fi
}

install() {
    sudo qemu-system-x86_64 \
        -m $(_get_config_value "memory_size") \
        -smp $(_get_config_value "cores") \
        -cdrom $(_get_config_value "os_image") \
        -nic hostfwd=tcp:127.0.0.1:22222-:22 \
        -drive file=$DISC_DIR/devm.qcow2,if=virtio \
        -vga virtio \
        -display default,show-cursor=on \
        -usb \
        -device usb-tablet \
        -cpu host \
        -machine type=q35,accel=hvf
}

create_disc() {
    if [ ! -f ~/.dev-machine/discs/devm.qcow2 ]; then
        qemu-img create -f qcow2 ~/.dev-machine/discs/devm.qcow2 $(_get_config_value "volume_size")
    else
        _print_style "Disc already exist exist\n" "info"
        _print_style "Remove image by 'rm -rf ~/.dev-machine/discs/devm.qcow2' and run the command again\n"
    fi
}

init_doc="Builds console image, starts, and opens started container"
init() {
    echo $(_get_config_value "volume_size")
    setup
    create_disc
    install
}

if ! [ -z $1 ]; then
    _run $1 $@
else
    help
fi
