# QEMU wrapper to create VM designed for software development


### Build for MAC OS X

🔥This is jest the beginning of the project.🔥

## BEFORE
Install:
* **QEMU** - MUST! (https://www.qemu.org/download/#macos)
* **GO** - OPTIONAL (to be able to rebuild forwarding tool) (https://go.dev/doc/install)

## INSTALL
```bash
cd ~ && git clone git@github.com:lukeurban/dev-machine.git && sudo cd ./dev-machine/install.sh
```

## Steps to create a working VM

### Command
```bash
dev-machine vm init
```
### What is happening during init?
During init you will:
* create a config file
* create a VM disc
* install distro on newly created disc

#### Example config 
```yml
version: 0.0.1
dev_machine:
  volume_size: 100G
  memory_size: 16G
  cores: 6
  os_image: /Users/luke/.dev-machine/image/debian.iso
  file_butler_directory:  /Users/luke/dev-machine
system:
  user: luke
```
#### Config explanation
1. Keep in mind that you need to download a .iso file and paste an absolute path to it in `os_image`. I recommend debian (https://www.debian.org/distrib/)
2. `file_butler_directory` is the ONLY directory shared between host and VM. Sometimes we need to copy some files. That's what is it for. **DO NOT PLACE YOUR ENTIRE PROJECTS THERE** It's just a middleman.
3. `system.user` is the user you're planning to create during the install process inside your VM.


## Tips on DISTRO installation
1. Don't close QEMU window immediatel -> log in as `root` and:
a. install sudo and make `system.user` to use sudo without password
b. Enable paswordless login to `system.user` using ssh-key and authorized_keys -> you won't need to type you VM users password each time you log into a VM.

### AFTER INSTALLATION
#### 1.Enable VMs `enp0s3` network interface or add:
```
allow-hotplug enp0s3
iface enp0s3 inet dhcp
```
 at the end of  **/etc/network/interface** file inside VM
####2.Add VM `enp0s3` IP to HOSTs /ets/hosts

bu running ip addr in VM you can see that our VM IP is `192.168.2.3` 
```
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 54:54:00:55:55:55 brd ff:ff:ff:ff:ff:ff
    inet 192.168.2.3/24 brd 192.168.2.255 scope global dynamic enp0s3
       valid_lft 82518sec preferred_lft 82518sec
```
Now we can add this to out HOST /etc/hosts
```
192.168.2.3 develop
```
and access our apps in the browser on `http://develop:X`

## Usage
After installation you can type `dev-tools` and you'll see all available commands
```bash
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


Usage:
   dev-machine  [target]

Available targets in :
   Name:                     Doc:
   c                         Short for connect to dev VM
   connect                   Connect dev VM
   help                      Help menu
   network                   Host <-> VM network tools
   start                     Start dev VM
   stop                      Start dev VM
   update                    Self update method
   vm                        All VM tools
```
But on daily basis you'll need few:
`dev-machine start` -> to start the VM
`dev-machine stop` -> to stop the VM
`dev-machine connect` or  `dev-machine c`-> to connect to the VM

#### Bonus tool
Sometimes we need to test out frontend and backend on our physical devices. In my case when I develop an API for my Flutter app I need to access the API on my physical device. It's easy to connect to out host machine, we just type our local network IP address. The problem is that our API is living on our VM not out HOST. So we need to be able to access VM **through** our HOST.
In order to do that I have to forward all traffic form HOST_PORT to VM_PORT.
That why I wrote a forward command:
```bash
dev-machine network forward HOST_PORT VM_PORT
```
**Example: `dev-machine network forward 4201 4200`**
Use case from the example command execution above:
I ran an Angular frontend app inside VM on port `4200`. I want to test the app on my phone.
My host Mac is connected to the same network as my phone and my Mac(HOST) has the IP address `192.168.0.56`.
After running forward command I can type `192.168.0.56:4001` on my phones browser and access my Angular app.

#### KNOWN ISSUES:
* stoping VM can throw permission error
* Everything is not out of the box
* version is in config file 😂

## CONTRIBUTING
Anybody is welcome to contribute!

## License

[MIT](https://github.com/lukeurban/dev-machine/blob/master/LICENSE.md)

## MOTIVATION

I work a lot with docker and it sucks on mac. I think I don't need file sharing between host and docker VM. 
That's why I created a tool to create VM using QEMU. Every line of code is remote and I use VSCode remote features to access them.

## Links

If you find this to be of value maybe consider buying me a coffee??

<a href="https://www.buymeacoffee.com/thatlukeurban">
<img src="https://github.com/lukeurban/cdn/blob/main/images/bmc-button.png?raw=true" width="200" />
</a>
