#! /bin/bash
# This script deploys a MariaDB database using Podman.

QUAY_USER="your quay username"

podman build -t quay.io/$QUAY_USER/demolab-database:latest -t quay.io/$QUAY_USER/demolab-database:rhel9.6 -f Containerfile
podman push quay.io/$QUAY_USER/demolab-database:latest && podman push quay.io/$QUAY_USER/demolab-database:rhel9.6

sudo podman pull quay.io/$QUAY_USER/demolab-database:latest
sudo podman run \
--rm \
-it \
--privileged \
--pull=newer \
--security-opt label=type:unconfined_t \
-v $(pwd)/config.toml:/config.toml:ro \
-v $(pwd):/output \
-v /var/lib/containers/storage:/var/lib/containers/storage registry.redhat.io/rhel9/bootc-image-builder:latest \
--type qcow2 \
--tls-verify=false \
quay.io/$QUAY_USER/demolab-database:latest

sudo mv qcow2/disk.qcow2 /var/lib/libvirt/images/database.qcow2

sudo virt-install \
  --connect qemu:///system \
  --name database \
  --import \
  --boot uefi \
  --memory 4096 \
  --graphics none \
  --osinfo rhel9-unknown \
  --noautoconsole \
  --noreboot \
  --disk /var/lib/libvirt/images/database.qcow2

sudo virsh start database