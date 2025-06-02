#!/bin/bash
set -euo pipefail

disk="/dev/sdb"
vg_name="vg_containerd"
lv_name="lv_containerd"
mount_point="/var/lib/containerd"
filesystem_type="ext4"

partitions=(
  "1 1MB 87GB"
  "2 87GB 175GB"
  "3 175GB 262GB"
  "4 262GB 350GB"
)

echo "Installing parted package if missing..."
if ! command -v parted &>/dev/null; then
  apt-get update && apt-get install -y parted
fi

echo "Wiping existing partitions and signatures on $disk..."
wipefs -a "$disk" || true
dd if=/dev/zero of="$disk" bs=512 count=2048 status=none || true

echo "Creating msdos partition table on $disk..."
parted "$disk" mklabel msdos --script

echo "Creating partitions on $disk..."
for p in "${partitions[@]}"; do
  read -r num start end <<<"$p"
  parted "$disk" mkpart primary "$start" "$end" --script
done

echo "Informing kernel of partition changes..."
partprobe "$disk"

# Wait a moment for partitions to be recognized
sleep 3

# Clean up existing LVM components if any
if lvdisplay "/dev/${vg_name}/${lv_name}" &>/dev/null; then
  echo "Removing existing logical volume $lv_name..."
  lvremove -f "/dev/${vg_name}/${lv_name}"
fi

if vgdisplay "$vg_name" &>/dev/null; then
  echo "Removing existing volume group $vg_name..."
  vgremove -f "$vg_name"
fi

if pvdisplay /dev/sdb1 &>/dev/null; then
  echo "Removing existing physical volume on /dev/sdb1..."
  pvremove -ff -y /dev/sdb1
fi

echo "Creating physical volume on /dev/sdb1..."
pvcreate /dev/sdb1

echo "Creating volume group $vg_name on /dev/sdb1..."
vgcreate "$vg_name" /dev/sdb1

echo "Creating logical volume $lv_name using 100% free space in $vg_name..."
lvcreate -y -l 100%FREE -n "$lv_name" "$vg_name"

echo "Formatting logical volume with $filesystem_type filesystem..."
mkfs."$filesystem_type" "/dev/${vg_name}/${lv_name}"

echo "Creating mount point directory $mount_point..."
mkdir -p "$mount_point"

echo "Mounting logical volume to $mount_point..."
mount "/dev/${vg_name}/${lv_name}" "$mount_point"

echo "Adding mount to /etc/fstab for persistence..."
grep -q "/dev/${vg_name}/${lv_name}" /etc/fstab || \
  echo "/dev/${vg_name}/${lv_name} $mount_point $filesystem_type defaults 0 2" >> /etc/fstab

echo "Storage setup completed successfully!"
