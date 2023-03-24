#!/usr/bin/env bash

ROOT="/mnt/root"
KVER=$(env INSTALL_ROOT=/mnt/root bulge list | grep -e "^linux " | grep -oP "[\d\.]+-")

if [ ! -d "$ROOT" ]; then
	echo "directory not found: $ROOT"
	exit 1
fi

echo "mkiso.sh: creating iso"

if [ "$(which mksquashfs)" = "" ]; then
	echo "mkiso.sh: mksquashfs not found in your path! please add mksquashfs to your path (:"
	exit 1
fi

if [ "$(which xorriso)" = "" ]; then
	echo "mkiso.sh: xorriso not found in your path! please add xorriso to your path (:"
	exit 1
fi

rm -f "$ROOT"/{s,}bin/init

# using https://github.com/Tomas-M/linux-live/ cause i'm lazy
INITRAMFS_DIR=/tmp/MKINITRAMFS
rm -rf "$INITRAMFS_DIR"
mkdir -p "$INITRAMFS_DIR"

# nevermind, using my own solution B)

cd "$ROOT" || exit 1

ROOTIMG=$(mktemp -d)/rootfs.img
truncate -s 8G "$ROOTIMG"
mkfs.ext4 "$ROOTIMG"

MROOT="/mnt/rootimg"
mkdir -p "$MROOT"
mount -o loop "$ROOTIMG" "$MROOT" || exit 1
# move everything to the new root
rsync -aAX --exclude=dev/* --exclude=proc/* --exclude=sys/* --exclude=run/* . "$MROOT" || exit 1
# unmount the new root
umount "$MROOT"

umount proc sys dev

SQUASHFS_DIR=$(mktemp -d)
mkdir -p "$SQUASHFS_DIR/LiveOS"

mv "$ROOTIMG" "$SQUASHFS_DIR/LiveOS/rootfs.img"

cd "$SQUASHFS_DIR" || exit 1

mksquashfs ./* "$SQUASHFS_DIR"/squashfs.img -comp xz -b 1024K -Xbcj x86 -always-use-fragments -keep-as-directory || exit 1

mkdir -pv $ROOT/{dev,proc,sys,run}
mount -v --bind /dev $ROOT/dev
mount -vt proc proc $ROOT/proc
mount -vt sysfs sysfs $ROOT/sys

cd "$INITRAMFS_DIR" || exit 1

# uefi stuff (https://askubuntu.com/questions/1110651/how-to-produce-an-iso-image-that-boots-only-on-uefi)
BOOT_IMG_DATA=$(mktemp -d)
BOOT_IMG=$(mktemp -d)/efi.img

mkdir -p $(dirname "$BOOT_IMG")
mkdir -p "$BOOT_IMG_DATA"

truncate -s 8M "$BOOT_IMG"
mkfs.vfat "$BOOT_IMG"

mknod /dev/loop0 b 7 0
losetup /dev/loop0 "$BOOT_IMG"
mount /dev/loop0 "$BOOT_IMG_DATA"

mkdir -p "$BOOT_IMG_DATA"/EFI/Boot

cat > "$BOOT_IMG_DATA"/EFI/Boot/embedgrub.cfg << EOF
search.fs_label YIFFOS root
set prefix=(\$root)/boot
configfile \$prefix/grub.cfg
EOF

grub-mkimage \
    -C xz \
    -O x86_64-efi \
    -p /boot/grub \
    -o $BOOT_IMG_DATA/efi/boot/bootx64.efi \
    --config="$BOOT_IMG_DATA"/EFI/Boot/embedgrub.cfg \
    boot linux search normal configfile \
    part_gpt btrfs ext2 fat iso9660 loopback \
    test keystatus gfxmenu regexp probe \
    efi_gop efi_uga all_video gfxterm font \
    echo read ls cat png jpeg halt reboot

umount "$BOOT_IMG_DATA"
losetup -d /dev/loop0
rm -rf "$BOOT_IMG_DATA"

mv "$BOOT_IMG" "$ROOT"/boot/efi.img

echo '#!/bin/bash' > $ROOT/root/gencdinitramfs
KVER=$(bulge list | grep -e "^linux " | grep -oP "[\d\.]+-")
echo "dracut cdinitramfs.img --kver ${KVER}yiffOS --force \
-a 'dmsquash-live convertfs pollcdrom'" >> $ROOT/root/gencdinitramfs
chmod +x $ROOT/root/gencdinitramfs

chroot "/mnt/root" /usr/bin/env -i   \
	HOME=/root                  \
	TERM="$TERM"                \
	PS1='(yiffOS chroot) \u:\w\$ ' \
	PATH=/usr/bin:/usr/sbin     \
	/bin/bash /root/gencdinitramfs

mkdir -p "$INITRAMFS_DIR"/boot
mv "$ROOT"/cdinitramfs.img "$INITRAMFS_DIR"/boot/cdinitramfs.img
mv "$ROOT"/boot/efi.img "$INITRAMFS_DIR"/boot/efi.img
cp "$ROOT"/boot/vmlinuz-"$KVER"yiffOS "$INITRAMFS_DIR"/boot/vmlinuz

cat > "$INITRAMFS_DIR"/boot/grub.cfg << EOF
set default=0
set timeout=7

menuentry "yiffOS" {
  linux /boot/vmlinuz root=live:CDLABEL=YIFFOS
  initrd /boot/cdinitramfs.img
}
EOF

cd "$ROOT" || exit 1
umount proc sys dev

#git clone https://github.com/voremicrocomputers/linux-live-yiffOS.git linux-live || exit 1
#cd linux-live || exit 1

#cd initramfs || exit 1
#IMAGE=$(./initramfs_create || exit 1)
#cd .. || exit 1


# copy linux-live's boot stuff cause i'm still lazy

#cp "$ROOT"/boot/vmlinuz-"$KVER"yiffOS "$ROOT"/boot/vmlinuz

# once again copying linux-live's corefs stuff cause i'm lazy
#MKMOD="bin etc home lib lib64 opt root sbin srv usr var"
#COREFS=""
#for i in $MKMOD; do
#	if [ -d /$i ]; then
#		COREFS="$COREFS /$i"
#	fi
#done
#
ISODIR="$ROOT"/../iso
mkdir -p "$ISODIR"
cd "$ISODIR" || exit 1
rm -rf "${ISODIR:?}"/*
mv "$INITRAMFS_DIR"/* "$ISODIR"
mkdir -p "$ISODIR"/LiveOS
mv "$SQUASHFS_DIR"/squashfs.img "$ISODIR"/LiveOS/squashfs.img || exit 1

# todo: add non-uefi support if yiffOS gets non-uefi support
# todo: add isolinux support if yiffOS gets an isolinux bootloader, for now just use grub2 with efi only
xorriso -as mkisofs \
    -iso-level 3 \
    -r -R -V "YIFFOS" \
    -J -joliet-long \
    -e boot/efi.img \
    -no-emul-boot -isohybrid-gpt-basdat \
    -o /output/yiffos.iso \
    .