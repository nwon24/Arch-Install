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
  mkfs.fat -F32 ${disk}1
  mkswap ${disk}2
  mkfs.ext4 ${disk}3
  mount ${disk}3 /mnt
  mkdir /mnt/efi
  mount ${disk}1 /mnt/efi
  swapon ${disk}2
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
  mkfs.fat -F32 ${disk}1
  mkswap ${disk}2
  mkfs.ext4 ${disk}3
  mkfs.ext4 ${disk}4
<<<<<<< HEAD
  mount $(disk)3 /mnt
=======
  mount ${disk}3 /mnt
>>>>>>> 2a85998e78bd8726bd903eb9dddcfe0664a8870a
  mkdir /mnt/efi && mkdir /mnt/home
  mount ${disk}1 /mnt/efi
  mount ${disk}4 /mnt/home
  swapon ${disk}2
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
cat <<EOF > /mnt/chroot.sh
  echo 'Enter timezone (e.g. Australia/Melbourne) '
  read timezone
  ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
  timedatectl set-ntp true
  hwclock --systohc
  echo 'Enter hostname '
  read hostname
  echo $hostname > /etc/hostname
  cat <<EOF > /etc/hosts
  127.0.0.1	localhost
  ::1		localhost
  127.0.1.1	$hostname.localdomain $hostname
  EOF
  sed -i 's/#en_AU.UTF-8 UTF-8/en_AU.UTF-8 UTF-8/g' /etc/locale.gen
  sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
  locale-gen
  echo LANG=$locale > /etc/locale.conf
  echo 'Set root password'
  passwd root
  echo '[I]ntel or [A]MD ucode? '
  read ucode
  if [ $ucode == I ]
  then
    pacman -S grub efibootmgr networkmanager intel-ucode 
  else
    pacman -S grub efibootmgr networkmanager amd-ucode
  fi
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
  grub-mkconfig -o /boot/grub/grub.cfg
  systemctl enable NetworkManager 
EOF
sed 's/  //g' /mnt/chroot/sh
arch-chroot /mnt /chroot.sh
umount -a
swapoff ${disk}2
reboot
