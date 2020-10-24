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
