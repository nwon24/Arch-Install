echo 'This is a post install setup script for Arch Linux.'
echo 'Enter user name for new user account: '
read username
useradd -m $username 
echo 'Set password'
passwd $username
usermod -aG users,wheel,power,optical,adm,lp $username
cp /etc/sudoers /etc/sudoers.tmp
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers.tmp
visudo -cf /etc/sudoers.tmp 
cp /etc/sudoers.tmp /etc/sudoers

echo 'Would you like to install additional software, such as the X Window Manager and a desktop environment? [Y/N] '
read software
if [ $softare = N ]
then 
  echo 'Changing into your user account and exiting... '
  su $username
else
  echo 'Installing software'
  pacman -S xorg xorg-drivers -y
  echo 'Select a desktop environment: [l]xde, [m]ate, [p]lasma, [g]nome, [x]fce, [c]innamon, [n]one '
  read desktop
  if [ $desktop = l ] 
  then
    pacman -S lxde
    systemctl enable lxdm
  elif [ $desktop = m ] 
  then 
    pacman -S mate
    echo 'Choose a display manager: '
    read dm
    if [ $dm = lightdm ]
    then 
      pacman -S lightdm lightdm-gtk-greeter
      systemctl enable lightdm
    fi
    pacman -S $dm
    systemctl enable $dm
  elif [ $desktop = p ]
  then 
    pacman -S plasma-desktop
    systemctl enable sddm
  elif [ $desktop = g ]
  then 
    pacman -S gnome
    systemctl enable gdm
  elif [ $desktop = x ] 
  then 
    pacman -S xfce4 xfce4-goodies
    echo 'Choose a display manager: '
    read dwm
    if [ $dm = lightdm ]
    then
      pacman -S ligthdm lightdm-gtk-greeter
      systemctl enable lightdm
    else
      pacman -S $dm
      systemctl enable $dm
  elif [ $desktop = c ]
  then 
    pacman -S cinnamon 
    echo 'Choose a display manager: '
    read dm
    if [ $dm = lightdm ]
    then
      pacman -S lightdm lightdm-gtk-greeter
      systemctl enable lightdm
    else
      pacman -S $dm
      systemct enable $dm
    fi
  else
    echo 'Not installing any desktop environment...'
  fi
  echo 'Installing fonts... '
  pacman -S gnu-free-fonts ttf-dejavu ttf-liberation ttf-ubuntu-font-family ttf-roboto
fi

