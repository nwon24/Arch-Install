echo "This is an arch install script for a system booted into UEFi mode."
pacman -Sy
reflector -c 'Australia' --sort rate --save /etc/pacman.d/mirrorlist
lsblk
echo 'Enter disk name (e.g. /dev/sda) '
read disk
echo 'Would you like a separate home partition? (Y/N) '
read home
if [ $home = N ]
then
  fdisk $disk <<EOF
  g
  n
  1

  +500M
  t
  1
  n
  2

  +2G
  t
  2
  19
  n
  3


  w
  EOF
  mkfs.fat -F32 ($disk)1
  mkswap ($disk)2
  mkfs.ext4 ($disk)3
  mount ($disk)3 /mnt
  mkdir /mnt/efi
  mount ($disk)1 /mnt/efi
  swapon ($disk)2
else
  fdisk $disk <<EOF
  g
  n
  1
  
  +500M
  t
  1
  n
  2
  
  +2G
  t
  2
  19
  n
  3
  
  +24G
  n
  4
  
  
  w
  EOF
  mkfs.fat -F32 ($disk)1
  mkswap ($disk)2
  mkfs.ext4 ($disk)3
  mkfs.ext4 ($disk)4
  mount ($disk3) /mnt
  mkdir /mnt/efi && mkdir /mnt/home
  mount ($disk)1 /mnt/efi
  mount ($disk)4 /mnt/home
  swapon ($disk)2
fi
echo 'Which kernel would you like to install? [l]inux, linux-lt[s], linux-[z]en '
read kernel
if [ $kernel = l ]
then 
  pacstrap /mnt base linux base-devel vim 
elif [ $kernel = s ] 
then 
  pacstrap /mnt base linux-lts base-devel vim
else 
  pacstrap /mnt base linux-zen base-devel vim
fi
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
  
