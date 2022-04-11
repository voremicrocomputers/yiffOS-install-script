#!/bin/bash
export R=/mnt/root
mkdir -p $R
mount $2 $R

mkdir -p $R/boot/efi
mount $1 $R/boot/efi
swapon

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
mount -vt tmpfs tmpfs $R/run

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

ln -sfv /run $R/var/run
ln -sfv /run/lock $R/var/lock

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

echo "root:x:0:" > $R/etc/groups
echo "bin:x:1:daemon" >> $R/etc/groups
echo "sys:x:2:" >> $R/etc/groups
echo "kmem:x:3:" >> $R/etc/groups
echo "tape:x:4:" >> $R/etc/groups
echo "tty:x:5:" >> $R/etc/groups
echo "daemon:x:6:" >> $R/etc/groups
echo "floppy:x:7:" >> $R/etc/groups
echo "disk:x:8:" >> $R/etc/groups
echo "lp:x:9:" >> $R/etc/groups
echo "dialout:x:10:" >> $R/etc/groups
echo "audio:x:11:" >> $R/etc/groups
echo "video:x:12:" >> $R/etc/groups
echo "utmp:x:13:" >> $R/etc/groups
echo "usb:x:14:" >> $R/etc/groups
echo "cdrom:x:15:" >> $R/etc/groups
echo "adm:x:16:" >> $R/etc/groups
echo "messagebus:x:18:" >> $R/etc/groups
echo "systemd-journal:x:23:" >> $R/etc/groups
echo "input:x:24:" >> $R/etc/groups
echo "mail:x:34:" >> $R/etc/groups
echo "kvm:x:61:" >> $R/etc/groups
echo "systemd-journal-gateway:x:73:" >> $R/etc/groups
echo "systemd-journal-remote:x:74:" >> $R/etc/groups
echo "systemd-journal-upload:x:75:" >> $R/etc/groups
echo "systemd-network:x:76:" >> $R/etc/groups
echo "systemd-resolve:x:77:" >> $R/etc/groups
echo "systemd-timesync:x:78:" >> $R/etc/groups
echo "systemd-coredump:x:79:" >> $R/etc/groups
echo "uuidd:x:80:" >> $R/etc/groups
echo "systemd-oom:x:81:" >> $R/etc/groups
echo "wheel:x:97:" >> $R/etc/groups
echo "nogroup:x:99:" >> $R/etc/groups
echo "users:x:999:" >> $R/etc/groups

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
yes | bulge s
yes | bulge setup # to be removed in the future, keep for now though
yes | bulge gi base
# yes | bulge i corefiles # this was to fix a bug
yes | bulge i gnutls libxcrypt libgcrypt grub2 btrfs-progs grep
yes | bulge i bulge

mount -vt proc proc $R/proc

grub-install --target=x86_64-efi --efi-directory=$R/boot/efi --boot-directory=$R/boot --bootloader-id=yiffOS

case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $R/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $R/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $R/lib64/ld-lsb-x86-64.so.3
    ;;
esac

genfstab -U $R > $R/etc/fstab

cp /usr/sbin/chroot $R/usr/sbin/chroot

echo '#!/bin/bash' > $R/root/yiffosP2
echo 'ln -s /usr/bin/bash /usr/bin/sh' >> $R/root/yiffosP2
echo 'systemd-machine-id-setup' >> $R/root/yiffosP2
echo 'systemctl preset-all' >> $R/root/yiffosP2
echo 'systemctl disable systemd-time-wait-sync.service' >> $R/root/yiffosP2
echo 'dracut --kver 5.16.11-yiffOS --force' >> $R/root/yiffosP2
echo 'grub-mkconfig -o /boot/grub/grub.cfg' >> $R/root/yiffosP2
echo 'touch /etc/shadow' >> $R/root/yiffosP2
echo 'touch cock' >> $R/root/yiffosP2
echo 'touch grass' >> $R/root/yiffosP2
echo 'passwd root' >> $R/root/yiffosP2
echo 'echo "yiffos installed (:"' >> $R/root/yiffosP2
chmod +x $R/root/yiffosP2

chroot "/mnt/root" /usr/bin/env -i   \
	HOME=/root                  \
	TERM="$TERM"                \
	PS1='(yiffOS chroot) \u:\w\$ ' \
	PATH=/usr/bin:/usr/sbin     \
	/bin/bash /root/yiffosP2

