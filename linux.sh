#!/bin/sh

# Set LINUX_PARTITION variable to the linux's partition on the SD card: LINUX_PARTITION="/dev/block/mmcblk1p1"
LINUX_PARTITION=""

# Set linux partition's file system in the PARTITION_FS variable
PARTITION_FS="ext4"



LINUX_ROOT="/data/debian"
BIND_MOUNTS="dev dev/pts proc sys"

### Check if LINUX_PARTITION is set
if [ "$LINUX_PARTITION" == "" ]; then
    echo "'LINUX_PARTITION' variable is not set in the $0 file!"
    exit
fi

### If -h or --help switch is passed, then show the help and exit
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
	echo "Chroot to linux"
	echo "Usage: $0 [OPTIONS]"
	echo "OPTIONS:"
	echo -e "  -f\tForce chrooting if already chrooted."
	echo -e "  -k\tKill the current chroot."
	exit
fi

clear

### If -k switch is passed, then kill the previus chroot and exit
if [ "$1" == "-k" ]; then
    ### Kill linux processes
    echo "Killing linux processes:"
    PID=$(lsof | grep $LINUX_ROOT | /bin/head -n 1 | /bin/awk '{print $2}') # Get linux PID
    while [ "$PID" ]
    do
        echo -n "    PID: $PID: "
        kill "$PID"
        echo "done"
        PID=$(lsof | grep /data/debian | /bin/head -n 1 | /bin/awk '{print $2}') # Get linux PID
    done

    ### Unmount bind mounts
    echo "Unmounting bind mounts: "
    ### Reverse bind mounts order to unmount them
    BIND_UNMOUNTS=""
    for f in $BIND_MOUNTS
    do
        BIND_UNMOUNTS="$f $BIND_UNMOUNTS"
    done

    ### Unmount bind mounts
    for f in $BIND_UNMOUNTS
    do
        echo -n "    $f: "
        if grep -qs "$LINUX_ROOT/$f" /proc/mounts; then
            umount "$LINUX_ROOT/$f"
            echo "done"
        else
            echo "already unmounted"
        fi
    done

    ### Unmount other mounts
    echo "Unmounting other mounts: "
    MP=$(mount | grep /data/debian/ | /bin/awk '{print $2}') # Get other mount points
    while [ "$MP" ]
    do
        echo -n "    $MP: "
        umount "$MP"
        echo "done"
        MP=$(mount | grep /data/debian/ | /bin/awk '{print $2}') # Get other mount points
    done

    ### Unmount linux partition
    echo -n "Unmounting linux partition: "
    if grep -qs "$LINUX_ROOT" /proc/mounts; then
        umount "$LINUX_ROOT"
        echo "done"
    else
        echo "already unmounted"
    fi

    exit
fi

### Do chroot
### Create linux root directory
echo -n "Creating linux root directory: "
mkdir -p "$LINUX_ROOT"
echo "done"

### Mount linux partition
echo -n "Mounting linux partition: "
if grep -qs "$LINUX_ROOT" /proc/mounts; then
    CHROOTED="1"
    echo "already mounted"
else
    CHROOTED="0"
    mount -o exec,dev,suid -t "$PARTITION_FS" "$LINUX_PARTITION" "$LINUX_ROOT"
    echo "done"
fi

### Bind mount required files
echo "Bind mounting:"
for f in $BIND_MOUNTS
do
    echo -n "    $f: "
    if grep -qs "$LINUX_ROOT/$f" /proc/mounts; then
        echo "already mounted"
    else
        mount -o bind /$f "$LINUX_ROOT/$f"
        echo "done"
    fi
done

### Prepare for chroot
echo -n "Preparing for chroot: "
export USER=root
export HOME=/root
export SHELL=/bin/bash
export TERM=linux
export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin
export LC_ALL=C
export LANGUAGE=C
export LANG=C
export TMPDIR=/tmp
echo "done"

### chroot
if [ "$CHROOTED" == "0" ] || [ "$1" == "-f" ]; then
    echo "Chrooting..."
    chroot "$LINUX_ROOT" /bin/bash --login
else
    echo "Already chrooted. Use -f to force chrooting. Use -k to kill chroot."
fi
