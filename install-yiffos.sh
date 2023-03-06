#!/usr/bin/env bash
echo ""
echo ""
echo ""
echo "=== yiffOS containerised system generation script (for real systems) ==="
echo ""

# check if root
if [ "$(id -u)" != "0" ]; then
  echo "error: this script must be run as root!"
  echo "if you experience this error in production, please report it to the developers!"
  exit 1
fi

echo "storing temporary root in /mnt/root"
export R="/mnt/root"
mkdir -p "$R"

echo "creating base filesystem"
mkdir -pv $R/{etc,var}
mkdir -pv $R/usr/{bin,lib,sbin}
for i in bin lib sbin; do
	ln -sv usr/$i $R/$i
done
case $(uname -m) in
	x86_64) mkdir -pv $R/lib64 ;;
esac

mkdir -pv $R/{dev,proc,sys,run}
mount -v --bind /dev $R/dev
mount -vt proc proc $R/proc
mount -vt sysfs sysfs $R/sys

mkdir -pv $R/{boot,home,mnt,opt,srv}
mkdir -pv $R/etc/{opt,sysconfig}
mkdir -pv $R/lib/firmware
mkdir -pv $R/media/{floppy,cdrom}
mkdir -pv $R/usr/{,local/}{include,src}
mkdir -pv $R/usr/local/{bin,lib,sbin}
mkdir -pv $R/usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv $R/usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv $R/usr/{,local/}share/man/man{1..8}
mkdir -pv $R/var/{cache,local,log,mail,opt,spool}
mkdir -pv $R/var/lib/{color,misc,locate}

install -dv -m 0750 $R/root
install -dv -m 1777 $R/tmp $R/var/tmp

echo "root:x:0:0:root:/root:/bin/bash" > $R/etc/passwd
echo "bin:x:1:1:bin:/dev/null:/usr/bin/false" >> $R/etc/passwd
echo "daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false" >> $R/etc/passwd
echo "messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false" >> $R/etc/passwd
echo "systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false" >> $R/etc/passwd
echo "systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false" >> $R/etc/passwd
echo "systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false" >> $R/etc/passwd
echo "systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false" >> $R/etc/passwd
echo "systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false" >> $R/etc/passwd
echo "systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false" >> $R/etc/passwd
echo "systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false" >> $R/etc/passwd
echo "uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false" >> $R/etc/passwd
echo "systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false" >> $R/etc/passwd
echo "nobody:x:99:99:Unprivileged User:/dev/null:/usr/bin/false" >> $R/etc/passwd

echo "root:x:0:" > $R/etc/group
echo "bin:x:1:daemon" >> $R/etc/group
echo "sys:x:2:" >> $R/etc/group
echo "kmem:x:3:" >> $R/etc/group
echo "tape:x:4:" >> $R/etc/group
echo "tty:x:5:" >> $R/etc/group
echo "daemon:x:6:" >> $R/etc/group
echo "floppy:x:7:" >> $R/etc/group
echo "disk:x:8:" >> $R/etc/group
echo "lp:x:9:" >> $R/etc/group
echo "dialout:x:10:" >> $R/etc/group
echo "audio:x:11:" >> $R/etc/group
echo "video:x:12:" >> $R/etc/group
echo "utmp:x:13:" >> $R/etc/group
echo "usb:x:14:" >> $R/etc/group
echo "cdrom:x:15:" >> $R/etc/group
echo "adm:x:16:" >> $R/etc/group
echo "messagebus:x:18:" >> $R/etc/group
echo "systemd-journal:x:23:" >> $R/etc/group
echo "input:x:24:" >> $R/etc/group
echo "mail:x:34:" >> $R/etc/group
echo "kvm:x:61:" >> $R/etc/group
echo "systemd-journal-gateway:x:73:" >> $R/etc/group
echo "systemd-journal-remote:x:74:" >> $R/etc/group
echo "systemd-journal-upload:x:75:" >> $R/etc/group
echo "systemd-network:x:76:" >> $R/etc/group
echo "systemd-resolve:x:77:" >> $R/etc/group
echo "systemd-timesync:x:78:" >> $R/etc/group
echo "systemd-coredump:x:79:" >> $R/etc/group
echo "uuidd:x:80:" >> $R/etc/group
echo "systemd-oom:x:81:" >> $R/etc/group
echo "wheel:x:97:" >> $R/etc/group
echo "nogroup:x:99:" >> $R/etc/group
echo "users:x:999:" >> $R/etc/group

echo "/bin/bash" > $R/etc/shells

touch $R/var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp $R/var/log/lastlog
chmod -v 664  $R/var/log/lastlog
chmod -v 600  $R/var/log/btmp

# don't need this unless on a non-yiffos system
# curl -O "https://yiffos.gay/bulge-openssl3"
# mv bulge-openssl3 bulge
# chmod +x ./bulge

umount -l $R/proc
rm -rf $R/proc/self

export INSTALL_ROOT=$R
yes | bulge setup # fixme: bulge setup may be removed in the future, we need to find a better way to do this

# fixme: bulge setup will also use the wrong mirrors
sed -i 's/\/\/repo/\/\/mirror/g' $R/etc/bulge/mirrors

yes | bulge s
yes | bulge gi base
yes | bulge i gnutls libxcrypt libgcrypt
yes | bulge i bulge

# insert your favourite packages here!
yes | bulge i linux-firmware networkmanager vim nano grub2 e2fsprogs grep btrfs-progs squashfs-tools xorriso
yes | bulge i lvm2 cryptsetup util-linux
yes | bulge i yiffos-installer-gtk

# fixme: hack because mutter isn't currently being installed despite being required
yes | bulge i mutter gnome-shell

# hack, move $R/var/run/* to $R/run/
rsync -a $R/var/run/ $R/run/
rm -rf $R/var/run
rsync -a $R/var/lock/ $R/run/lock/
rm -rf $R/var/lock

ln -sfv /run $R/var/run
ln -sfv /run/lock $R/var/lock

# make everyone sudo with no password!
echo "installer ALL=(ALL) NOPASSWD:ALL" >> $R/etc/sudoers

mount -vt proc proc $R/proc

grub-install --target=x86_64-efi --efi-directory=$R/boot/efi --boot-directory=$R/boot --bootloader-id=yiffOS

case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $R/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $R/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $R/lib64/ld-lsb-x86-64.so.3
    ;;
esac

#genfstab -U $R > $R/etc/fstab
#echo "/dev/sr0 /mnt/live iso9660 defaults 0 0" >> $R/etc/fstab
#echo "/mnt/live/rootfs.squashfs / squashfs defaults 0 0" >> $R/etc/fstab

echo '#!/bin/bash' > $R/root/yiffosP2
echo 'ln -s /usr/bin/bash /usr/bin/sh' >> $R/root/yiffosP2
#echo 'ln -s /run/dbus/ /var/run/dbus' >> $R/root/yiffosP2
echo 'systemd-machine-id-setup' >> $R/root/yiffosP2
echo 'systemctl preset-all' >> $R/root/yiffosP2
echo 'systemctl disable systemd-time-wait-sync.service' >> $R/root/yiffosP2
KVER=$(bulge list | grep -e "^linux " | grep -oP "[\d\.]+-")
echo "dracut --kver ${KVER}yiffOS --force" >> $R/root/yiffosP2
echo 'grub-mkconfig -o /boot/grub/grub.cfg' >> $R/root/yiffosP2
echo 'pwconv' >> $R/root/yiffosP2
echo 'grpconv' >> $R/root/yiffosP2
echo 'touch cock' >> $R/root/yiffosP2
echo 'touch grass' >> $R/root/yiffosP2
echo 'systemd-sysusers' >> $R/root/yiffosP2
echo 'glib-compile-schemas /usr/share/glib-2.0/schemas' >> $R/root/yiffosP2
echo 'for f in /usr/share/icons/*/; do' >> $R/root/yiffosP2
# shellcheck disable=SC2016
echo 'gtk4-update-icon-cache -t -f "$f"' >> $R/root/yiffosP2
# shellcheck disable=SC2016
echo 'gtk-update-icon-cache -t -f "$f"' >> $R/root/yiffosP2
echo 'done' >> $R/root/yiffosP2
echo 'systemctl enable gdm' >> $R/root/yiffosP2
echo 'systemctl enable NetworkManager' >> $R/root/yiffosP2

# fixme: temporary hack for polkit
echo 'groupadd -fg 27 polkitd' >> $R/root/yiffosP2
echo 'useradd -c "PolicyKit Daemon Owner" -d /etc/polkit-1 -u 27 -g polkitd -s /bin/false polkitd' >> $R/root/yiffosP2

echo 'passwd root' >> $R/root/yiffosP2
echo 'chmod +x /usr/bin/ping' >> $R/root/yiffosP2 # won't be needed in the future
echo 'echo "yiffos installed (:"' >> $R/root/yiffosP2
chmod +x $R/root/yiffosP2

chroot "/mnt/root" /usr/bin/env -i   \
	HOME=/root                  \
	TERM="$TERM"                \
	PS1='(yiffOS chroot) \u:\w\$ ' \
	PATH=/usr/bin:/usr/sbin     \
	/bin/bash /root/yiffosP2

