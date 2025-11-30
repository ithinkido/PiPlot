#!/bin/bash

DIR="/boot/firmware"
PP_SERVICE="/etc/systemd/system/piplot.service"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Fix DIR fallback
if [ ! -d "$DIR" ] ; then
    DIR="/boot"
fi
echo " Path: $DIR"

# Spinner function
spinner() {
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while ps -p $pid > /dev/null 2>&1 ; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

printf "\033[?25l"
lsb_release -ds
echo ""
echo "Updating apt. This could take a while ..."

# Run apt update + upgrade in background
(
    sudo apt-get update > /dev/null
    sudo apt-get -y upgrade -qq > /dev/null
) &
spinner $!

wait

# ---- config edits ----
if ! grep -q '#flow control serial' "$DIR/config.txt" ; then
    echo $'\n#flow control serial' | sudo tee -a "$DIR/config.txt" >/dev/null
fi

if ! grep -q 'dtoverlay=disable-bt' "$DIR/config.txt" ; then
    echo "dtoverlay=disable-bt" | sudo tee -a "$DIR/config.txt" >/dev/null
fi

if ! grep -q 'enable_uart=1' "$DIR/config.txt" ; then
    echo "enable_uart=1" | sudo tee -a "$DIR/config.txt" >/dev/null
    echo "UART 1 Enabled"
fi

if ! grep -q 'dtoverlay=uart-ctsrts' "$DIR/config.txt" ; then
    echo "dtoverlay=uart-ctsrts" | sudo tee -a "$DIR/config.txt" >/dev/null
    echo "CTS RTS Device tree enabled"
fi

sudo sed -i -E 's/console\s*=\s*\w+\s*,\s*[0-9]*//g' "$DIR/cmdline.txt"

sudo wget -q -c -P /boot/overlays https://raw.githubusercontent.com/ithinkido/PiPlot/main/uart-ctsrts.dtbo
sudo wget -q -c -P /boot/firmware/overlays https://raw.githubusercontent.com/ithinkido/PiPlot/main/uart-ctsrts.dtbo

sudo systemctl -q stop serial-getty@ttyAMA0.service
sudo systemctl -q disable serial-getty@ttyAMA0.service

sudo adduser -q "$USER" tty
echo ""

if [ -f "/etc/rc.local" ]; then
    if ! grep -q 'stty -F /dev/ttyAMA0 9600 crtscts' /etc/rc.local ; then
        sudo sed -i '/^exit 0/i stty -F /dev/ttyAMA0 9600 crtscts' /etc/rc.local
    fi
else
    echo "rc.local not found - using systemd service"

    if [ ! -f "$PP_SERVICE" ]; then
        sudo wget -q -O "$PP_SERVICE" \
            https://raw.githubusercontent.com/ithinkido/PiPlot/main/piplot.service

        sudo chmod 644 "$PP_SERVICE"

        sudo systemctl daemon-reload
        sudo systemctl enable piplot.service
        sudo systemctl start piplot.service

        echo "PiPlot service installed & enabled."

    else
        echo "Service already exists. Ensuring it is enabled..."
        sudo systemctl enable piplot.service
    fi
fi

echo "Done!"
echo ""
echo " _____ _    _____ _     _  "
echo "|  _  |_|  |  _  | |___| |_ "
echo "|   __| |  |   __| | . |  _|"
echo "|__|  |_|  |__|  |_|___|_|  "
echo ""

printf "Rebooting in 5 sec "
for i in $(seq 4 -1 1); do
    sleep 1
    printf "."
done

echo ""
printf "\033[?25h"
printf "Rebooting"
sleep 1
sudo reboot
