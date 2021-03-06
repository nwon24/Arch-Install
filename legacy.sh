echo "This is an arch install script for a system booted into BIOS mode."
pacman -Sy
lsblk

echo 'Enter disk name (e.g. /dev/sda) '
read disk
echo 'If installing Arch over an existing operating system, fdisk will ask if you if you want to continue. Type in y and then enter to continue.'
echo 'Would you like a separate home partition? (Y/N) '
read home
if [ $home = N ]
then
  fdisk $disk <<EOF
  o
  n
  p
  1
  
  +2G
  t
  82
  n
  p
  2
  
  
  a
  2
  w
EOF
  mkswap ${disk}1
  mkfs.ext4 ${disk}2
  mount ${disk}2 /mnt
  swapon ${disk}1
else
  fdisk $disk <<EOF
  o
  n
  p
  1
  
  +2G
  t
  82
  n
  p
  2
  
  +24G
  a
  2
  n
  p
  3
  
  
  w
EOF
  mkswap ${disk}1
  mkfs.ext4 ${disk}2
  mkfs.ext4 ${disk}3
  mount $(disk)2 /mnt
  mkdir /mnt/home
  mount ${disk}3 /mnt/home
  swapon ${disk}1
fi
echo 'Would you like to edit the pacman mirror list before installing the base system? (Y/N) '
read mirrorlist
if [ $mirrorlist = Y ] 
then 
  nano /etc/pacman.d/mirrorlist
fi 
echo 'Which kernel would you like to install? [l]inux, linux-lt[s], linux-[z]en '
read kernel
if [ $kernel = lz ]
then 
  pacstrap /mnt base linux-zen linux-firmware base-devel vim nano
elif [ $kernel = s ] 
then 
  pacstrap /mnt base linux-lts linux-firmware base-devel vim nano
else 
  pacstrap /mnt base linux linux-firmware base-devel vim nano
fi
genfstab -U /mnt >> /mnt/etc/fstab
cat <<EOF > /mnt/chroot.sh
  ls /usr/share/zoneinfo/
  echo 'Enter timezone reigon (look at above if unsure) '
  read reigon
  ls /usr/share/zoneinfo/\$region/
  echo 'Enter timezone city (look at avobe if unsure) '
  read city
  ln -sf /usr/share/zoneinfo/\$reigon/\$city /etc/localtime
  timedatectl set-ntp true
  hwclock --systohc
  echo 'Enter hostname '
  read hostname
  echo \$hostname > /etc/hostname
  cat <<EOF > /etc/hosts
  127.0.0.1	localhost
  ::1		localhost
  127.0.1.1	\$hostname.localdomain \$hostname
  EOF
  sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
  echo 'Do you need other locales other than en_US.UTF-8? [Y/N] '
  read locale_edit
  if [ \$locale_edit = Y ] 
  then 
    echo 'Comment out needed locales from the locale.gen file.'
    sleep 6
    nano /etc/locale.gen
  fi
  locale-gen
  echo 'What would you like to set the LANG variable in locale.conf? (Press enter for en_US.UTF-8) '
  read locale
  if [ \$locale = '' ] 
  then 
    echo LANG=en_US.UTF-8 > /etc/locale.conf
  else
    echo LANG=\$locale > /etc/locale.conf
  fi
  echo 'Set root password'
  passwd root
  echo '[I]ntel or [A]MD ucode? '
  read ucode
  if [ \$ucode = I ]
  then
    pacman -S grub networkmanager intel-ucode 
  else
    pacman -S grub networkmanager amd-ucode
  fi
  grub-install --target=i386-pc $disk
  grub-mkconfig -o /boot/grub/grub.cfg
  systemctl enable NetworkManager 
EOF
chmod 777 /mnt/chroot.sh
sed -i 's/  //g' /mnt/chroot.sh
arch-chroot /mnt /chroot.sh
rm -rf /mnt/chroot.sh
umount -a
swapoff ${disk}1
reboot
