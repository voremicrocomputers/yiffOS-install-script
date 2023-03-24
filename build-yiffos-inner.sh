#!/usr/bin/env bash
echo "build-yiffos-inner.sh: asserting correct files exist"
if [ ! -f /factory/install-yiffos.sh ]; then
  echo "build-yiffos-inner.sh: /factory/install-yiffos.sh not found! report to devs!"
  exit 1
fi
if [ ! -f /factory/mkiso.sh ]; then
  echo "build-yiffos-inner.sh: /factory/mkiso.sh not found! report to devs!"
  exit 1
fi

function script_fail() {
  echo "build-yiffos-inner.sh: $1 failed! exiting!"
  exit 1
}

echo "build-yiffos-inner.sh: installing required tools"

yes | bulge s
yes | bulge i xorriso squashfs-tools grub2 genfstab coreutils git dosfstools rsync
echo "build-yiffos-inner.sh: running install-yiffos.sh"

/factory/install-yiffos.sh || script_fail "install-yiffos.sh"

echo "build-yiffos-inner.sh: running mkiso.sh"

/factory/mkiso.sh || script_fail "mkiso.sh"

# copy the iso to the output directory
echo "build-yiffos-inner.sh: moving iso to output directory"

#mv /mnt/iso/yiffos.iso /output/yiffos.iso || script_fail "moving iso"
