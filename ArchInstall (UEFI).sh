echo "This is an arch install script for a system booted into UEFi mode."
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
  mount $(disk)3 /mnt
  mkdir /mnt/efi && mkdir /mnt/home
  mount ${disk}1 /mnt/efi
  mount ${disk}4 /mnt/home
  swapon ${disk}2
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
  ls /usr/share/zoneinfo/$region/
  echo 'Enter timezone city (look at avobe if unsure) '
  read city
  ln -sf /usr/share/zoneinfo/$reigon/$city /etc/localtime
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
  sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
  echo 'Do you need other locales other than en_US.UTF-8? [Y/N] '
  read locale_edit
  if [ $locale_edit = Y ] 
  then 
    echo 'Comment out needed locales from the locale.gen file.'
    sleep 6
    nano /etc/locale.gen
  fi
  locale-gen
  echo 'What would you like to set the LANG variable in locale.conf? (Press enter for en_US.UTF-8) '
  read locale
  if [ $locale = '' ] 
  then 
    echo LANG=en_US.UTF-8 > /etc/locale.conf
  else
    echo LANG=$locale > /etc/locale.conf
  fi
  echo 'Set root password'
  passwd root
  echo '[I]ntel or [A]MD ucode? '
  read ucode
  if [ $ucode = I ]
  then
    pacman -S grub efibootmgr networkmanager intel-ucode 
  else
    pacman -S grub efibootmgr networkmanager amd-ucode
  fi
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
  grub-mkconfig -o /boot/grub/grub.cfg
  systemctl enable NetworkManager 
EOF
chmod 777 /mnt/chroot.sh
sed -i 's/  //g' /mnt/chroot.sh
arch-chroot /mnt /chroot.sh
rm -rf /mnt/chroot.sh
umount -a
swapoff ${disk}2
reboot
