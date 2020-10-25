echo "This is an arch install script for a system booted into UEFi mode."
reflector -c 'Australia' --sort rate --save /etc/pacman.d/mirrorlist
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
echo 'Which kernel would you like to install? [l]inux, linux-lt[s], linux-[z]en '
read kernel
if [ $kernel = z ]
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
  ln -sf /usr/share/zoneinfo/Australia/Melbourne /etc/localtime
  timedatectl set-ntp true
  hwclock --systohc
  echo archlinux > /etc/hostname
  cat <<EOF > /etc/hosts
  127.0.0.1	localhost
  ::1		localhost
  127.0.1.1	archlinux.localdomain archlinux
  EOF
  sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
  sed -i 's/#en_AU.UTF-8 UTF-8/en_AU.UTF-8 UTF-8/g' /etc/locale.gen
  locale-gen
  echo LANG=en_AU.UTF-8 > /etc/locale.conf
  echo 'Set root password'
  passwd root
  pacman -S grub efibootmgr networkmanager intel-ucode 
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
