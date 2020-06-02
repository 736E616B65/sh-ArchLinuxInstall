#!/bin/sh
DRED="\033[1;31m"
DGREEN="\033[1;32m"
DYELLW="\033[1;33m"
DBLUE="\033[1;34m"
DMAGENTA="\033[1;35m"
END="\033[0m"

color=0 # color set

# efi support check #
if test ! -d "/sys/firmware/efi/efivars"; then
    printf "$DMAGENTA efi not support $END\n" # efi not support is exit -1
    exit -1
else
    printf "$DMAGENTA efi support $END\n" # efi support is next
fi
# efi support check #

# ping test and time set #
printf "$DMAGENTA ping test $END\n"
ping archlinux.org # CTL + C use
timedatectl set-ntp true # time set
# ping and time set #

# system upgrade #
printf "$DMAGENTA system updating.. $END\n"
yes | pacman -Sy
# system upgrade #

while true;do # main
# rom or loop drive without another drive input #
echo "----------------------------------------"
lsblk | while read line;do # lsblk line read
    # $line is rom(DVD drive) or loop(arch linux install drive) check
	if [[ "$line" = "loop"* ]] || [[ "$line" = "sr"* ]];then
		continue # true is loop(rom), no input
	fi

	printf "\033[1;3${color}m $line $END\n" 
	color=`expr $color + 1` # next color set
done
# rom or loop drive without another drive input #

color=0 # color init

# cfdisk error check, error is continue but noerror next #
echo "----------------------------------------"
while true;do
	printf "$DMAGENTA partition selection: $END"
	read DiskChoice
    cfdisk /dev/$DiskChoice 2> /dev/null 

    if [[ $? = 1 ]];then
        printf "$DMAGENTA not exists  $DRED $DiskChoice $DMAGENTA disk $END\n"
        continue
    else
        break
    fi
done
# cfdisk error test, error is continue but noerror next #

clear 

# Choice disk input and check 
echo "----------------------------------------"    
lsblk | while read line;do
    # if DiskChoice is disk(+number) name input
	if [[ "$line" = *"$DiskChoice"* ]];then 
		printf "$DRED $line $END \n"
	fi
done
# Choice disk input and check 

# all test ok #
echo "----------------------------------------"
printf "$DBLUE check partition: y/n: $END"
read YorN
    
# y is next but not y is main while #
if [ "$YorN" = "y" ];then
	break
fi
done # end main

mkfs.vfat -F32 /dev/${DiskChoice}1 # bootloader create
mkfs.ext4 /dev/${DiskChoice}2 # root create

mount /dev/${DiskChoice}2 /mnt # root mount
mkdir /mnt/boot # boot dir create
mount /dev/${DiskChoice}1 /mnt/boot # bootloader mount

yes | pacman -S vim # vim install
vim /etc/pacman.d/mirrorlist # vim use set mirr 

clear

pacstrap /mnt base linux linux-firmware # base package install
genfstab -U /mnt >> /mnt/etc/fstab # fstab create


echo "#!/bin/bash
yes | pacman -S vim
printf 'root \n'
passwd
vim /etc/locale.gen
locale-gen

echo LANG=en_US.UTF-8 > /etc/locale.conf
export LANG=en_US.UTF-8

printf 'hostname: '
read hostname
echo \"\$hostname\" > /etc/hostname

ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
hwclock --systohc --utc

printf 'UserName: '
read user
useradd -m -g users -G wheel -s /bin/bash \"\$user\"
printf \"\$user \"
passwd \"\$user\"

yes | pacman -S grub efibootmgr

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=\"\$name\" --recheck
grub-mkconfig -o /boot/grub/grub.cfg
yes | pacman -S networkmanager
systemctl enable NetworkManager
rm install
exit" > /mnt/install

arch-chroot /mnt

