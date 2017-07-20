# Chroot Debian On Android

### Requirements
1. Rooted android device
2. PC with a debian based linux installed on it
3. SD card

### Debootstrap debian
First debootstrap the debian linux on the PC to be install on the android device:

`sudo debootstrap --arch=i386 --variant=minbase --foreign stable ~/debian_bootstrap http://ftp.debian.org/debian/`
  - The above command debootstrap debian in ~/debian_bootstrap directory.
  - Set `--arch` to match the android's architecture to fetch proper linux for it.
  - Specify the desired debian release to fetch: stable, testing, stretch, jessie, etc.

### Prepare SD card
At least one partition in the SD card is needed for linux. Format the partition to ext3 or ext4 filesystem:

Hint: use `lsblk` command to identify the partition to be formated, for example `/dev/mmcblk0p1`:
  - ext3: `sudo mkfs.ext3 -L "linux" /dev/mmcblk0p1`
  - ext4: `sudo mkfs.ext4 -O ^metadata_csum -L "linux" /dev/mmcblk0p1`
    - Note: Some android devices may not recognize ext4 partition with "metadata_csum" feature, so disable it when formatting.

### Copy files to SD card partition
Mount the formatted SD card partition:

`sudo mount /dev/mmcblk0p1 /mnt/sdcard`

Copy debootstraped files to mounted partition:

`sudo cp -pfr ~/debian_bootstrap/* /mnt/sdcard`

### Chroot on android
Insert the SD card in the android device and get access to the android's shell via android apps like ConnectBot, JuiceSSH, etc.
Or connect the device to the PC with a USB cable and get access to it's shell using `adb shell` command from the PC (USB debugging must be enabled in the android device).

Hint: Identify the linux partition on the android device by viewing the partitions file: `cat /proc/partitions`. For example `/dev/block/mmcblk1p1`

Copy the `linux.sh` file to the android device in the desired location: `/data/linux.sh` and make it executable:

`chmod 770 /data/linux.sh`

Set the linux partition's path in the `linux.sh` file as the `LINUX_PARTITION` variable.
Default filesystem of SD card's partition is set to ext4.
If the SD card's partition is formatted using ext3 filesystem, set the `PARTITION_FS` variable to ext3 in the `linux.sh` file.

### Initial setup
Execute the following commands on the android's shell in the first run only:

Login as root user:

`su`

Mount and chroot to linux:

`/data/linux.sh`

Finalize debootstrap process:

`debootstrap/debootstrap --second-stage`

Add password for the root user:

`passwd root`

Add desired DNS server to the `resolve.conf` file in order to enable domain name lookups:

`echo 208.67.222.222 > /etc/resolv.conf`

Create goups that are recognized by the andoird OS:

`groupadd -g 3001 aid_net_bt_admin`

`groupadd -g 3002 aid_net_bt`

`groupadd -g 3003 aid_inet`

`groupadd -g 3004 aid_net_raw`

`groupadd -g 3005 aid_net_admin`

`groupadd -g 3006 aid_net_bw_stats`

`groupadd -g 3007 aid_net_bw_acct`

`groupadd -g 3008 aid_net_bt_stack`

Any user in the chrooted linux that wants to access to the android's network should be in the `aid_inet` group. To add a USERNAME to that group execute the following command:

`usermod -G 3003 -a USERNAME`

In order to let the `apt-get` command to access to the internet via android's network, `_apt` user should be in the `aid_inet` group, too.
Also the primary group of `_apt` user can be set to `aid_inet` by `-g` switch:

`usermod -g 3003 -G 3003,3004 -a _apt`

Prepare sources.list file:

`echo deb http://security.debian.org/ stretch/updates main contrib non-free > /etc/apt/sources.list`

`echo deb http://ftp.debian.org/debian/ stretch-updates main contrib non-free >> /etc/apt/sources.list`

`echo deb http://ftp.debian.org/debian/ stretch main contrib non-free >> /etc/apt/sources.list`

Update apt repository:

`apt-get update`

Install ssh server to be able to login to the chrooted linux remotely:

`apt-get install ssh`

Note: To enable root login, add `PermitRootLogin Yes` in the `/etc/ssh/sshd_config` file.

To start ssh service automatically after chroot, add `service ssh start` command to the `/etc/profile` file:

`echo service ssh start >> /etc/profile`

Install desired packages and enjoy...

### Using chrooted linux
In order to chroot to the linux simpley execute `linux.sh` script: `/data/linux.sh`

To exit chroot, execute `exit` command in the chrooted linux.

To rechroot to the exited chroot, execute: `/data/linux.sh -f`

To unmount and kill chroot, after exiting chroot, execute: `/data/linux.sh -k`

To get help pass `-h` or `--help` switch to the `linux.sh` script: `/data/linux.sh -h`

### Running GUI apps and desktop environment
In order to start a desktop environment and run GUI apps, install a X server app on the android and run it.
One example is "XServer XSDL".

To forward the chroot display to the "XServer XSDL", execute the following command:

`export DISPLAY=127.0.0.1:0 PULSE_SERVER=tcp:127.0.0.1:4712`

To execute the above command automatically after chroot, add the above command to the `/etc/profile` file:

`echo export DISPLAY=127.0.0.1:0 PULSE_SERVER=tcp:127.0.0.1:4712 >> /etc/profile`

Install desired desktop environment, for example LXDE:

`apt-get install lxde`

To start LXDE desktop environment execute:

`startlxde`

To exit LXDE desktop environment simply press `ctrl` + `c`
