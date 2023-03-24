#!/usr/bin/env bash

# check if root
if [ "$(id -u)" != "0" ]; then
  echo "error: this script must be run as root!"
  exit 1
fi

# the I_PREFER variable should specify either "docker" or "podman", but if not set, it will default to "podman"
if [ -z "$I_PREFER" ]; then
  I_PREFER="podman"
fi

# the CONTAINER_NAME variable should specify the name of the container to use, but if not set, it will default to "yiffos-minimal"
# if you get an error early on in the build process, you may want to pull this image
if [ -z "$CONTAINER_NAME" ]; then
  CONTAINER_NAME="yiffos-minimal"
fi

SCRIPTS_DIR=$(realpath "$(dirname "$0")")

OUTPUT_DIR="$1"
if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="$SCRIPTS_DIR/output"
fi

mkdir -p "$OUTPUT_DIR"

echo "running container $CONTAINER_NAME with output directory $OUTPUT_DIR"
# sys_chroot is required for chroot (during build we need to chroot into the new system and set some things up)
# cap_mknod is required for mknod (we need to make device nodes in certain places so things mount properly)
# cap_sys_admin is required for mount (we need to mount an img file. if there was a stricter capability for this, we would use it)
"$I_PREFER" run --rm -it --cap-add sys_chroot --cap-add cap_mknod --cap-add cap_sys_admin --privileged -v "$OUTPUT_DIR":/output -v "$SCRIPTS_DIR":/factory "$CONTAINER_NAME" /factory/build-yiffos-inner.sh

# chown the output directory to the current user
chown -R "$(id -u):$(id -g)" "$OUTPUT_DIR"

echo "done! your output is in $OUTPUT_DIR!"