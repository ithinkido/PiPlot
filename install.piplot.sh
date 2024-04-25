#!/bin/bash

spinner()
{
    local pid=$!
    local delay=0.75
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}
printf "\033[?25l"
lsb_release -ds
echo ""
echo "Updating apt. This could take a while ..."
(sudo apt-get update > /dev/null
wait
sudo apt-get -y upgrade -qq > /dev/null) & spinner
wait

DIR="/boot/firmware"
if [ ! -d "$DIR" ]; then
    DIR="/boot"
fi

if ! grep -q '#flow control serial' "$DIR/config.txt"; then
    echo $'\n#flow control serial' | sudo tee -a "$DIR/config.txt" >/dev/null
fi
if ! grep -q 'dtoverlay=disable-bt' "$DIR/config.txt"; then
    echo "dtoverlay=disable-bt" | sudo tee -a "$DIR/config.txt" >/dev/null
fi    
if ! grep -q 'enable_uart=1' "$DIR/config.txt"; then
    echo "enable_uart=1" | sudo tee -a "$DIR/config.txt" >/dev/null
    echo ""
    printf "UART 1 Enabled \n"
fi    
if ! grep -q 'dtoverlay=uart-ctsrts'"$DIR/config.txt"; then
    echo "dtoverlay=uart-ctsrts" | sudo tee -a "$DIR/config.txt" >/dev/null
    echo ""
    printf "CTS RTS Device tree enabled \n"
fi
sudo sed -i -E 's/console\s*=\s*\w+\s*,\s*[0-9]*//g' "$DIR/cmdline.txt"

sudo wget -q -c -P /boot/overlays https://raw.githubusercontent.com/ithinkido/PiPlot/main/uart-ctsrts.dtbo
sudo wget -q -c -P /boot/firmware/overlays https://raw.githubusercontent.com/ithinkido/PiPlot/main/uart-ctsrts.dtbo
sudo systemctl -q stop serial-getty@ttyAMA0.service
sudo systemctl disable serial-getty@ttyAMA0.service
echo ""
sudo adduser -q $USER tty
if ! grep -q 'stty -F /dev/ttyAMA0 9600 crtscts' '/etc/rc.local' ; then
    sudo sed -i '/^exit 0/i stty -F /dev/ttyAMA0 9600 crtscts' /etc/rc.local >/dev/null    
fi 
echo "Done !"
echo ""
echo " _____ _    _____ _     _  " 
echo "|  _  |_|  |  _  | |___| |_ "
echo "|   __| |  |   __| | . |  _|"
echo "|__|  |_|  |__|  |_|___|_|  "
echo ""   
printf "Rebooting in 5 sec "
(for i in $(seq 4 -1 1); do
    sleep 1;
    printf ".";
done;)
echo ""
printf "\033[?25h"
printf "Rebooting"
sleep 1 
sudo reboot