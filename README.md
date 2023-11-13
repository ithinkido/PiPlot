<p align="center"><img src="https://raw.githubusercontent.com/ithinkido/PiPlot/main/images/logo.svg?sanitize=true" width=100%></p>

# PiPlot
***
The PiPlot is a hardware shield that adds RS232 connectivity with serial hardware flow control to your Pi. It was designed to eliminate the need for USB -> Serial adapters and null modem cables when connecting to vintage plotters.
This page has useful info on setting up your Pi for use with the PiPlot shield. The shiled enables hardware flow control using the Pi GPIO serial port /dev/ttyAMA0. It has been tested on the Pi4, Pi3b+,Pi Zero W and Pi Zero 2 W running (Raspbian) PiOS Lite. I would highly recomend the Pi Zero 2 W for this project, as it makes for a fast and compact solution.

## The quick and easy  way
If you are running the recomended (Raspbian) PiOS, this simple one liner will do all of the steps below:

    curl -sSL https://raw.githubusercontent.com/ithinkido/PiPlot/main/install.piplot.sh | bash  

## Step by step install

Download the `uart-ctsrts.dtbo` file into your `/boot/overlays` folder.

     sudo wget -P /boot/overlays https://raw.githubusercontent.com/ithinkido/PiPlot/main/uart-ctsrts.dtbo

Add the following lines to your `/boot/config.txt` file:

    #flow control serial
    dtoverlay=disable-bt
    enable_uart=1
    dtoverlay=uart-ctsrts

Change the read write permissions on the port

    sudo chmod a+rw /dev/ttyAMA0
    
Set the baud rate and flow control

    stty -F /dev/ttyAMA0 9600 crtscts

You can now send a file to your plotter using the `cat` command e.g.

    cat PATH/TO/YOUR/FILE > /dev/ttyAMA0

Sadly, the Pi is not good at remembering port config. These setting will be lost on reboot. In order to make them permanent,

add your user to tty groups,

    sudo adduser $USER tty

remove the line `console=serial0,115200` from your `/boot/cmdline.txt` file.

    sudo nano /boot/cmdline.txt

By default the Raspberry Pi uses this serial port for the console login via the software service “getty”. This will override your settings on this serial port. To disable getty use this:  

    sudo systemctl stop serial-getty@ttyAMA0.service
    sudo systemctl disable serial-getty@ttyAMA0.service
 
 By adding the following to your cron tab, your Pi will automagically configure the AMA0 port with hardware flow control and the correct baud on boot: 
 Open the crontab.  

    crontab -e   

 Add this to the bottom:    

    @reboot sudo stty -F /dev/ttyAMA0 9600 crtscts

 And reboot...
 You will now have a permanent hardware flow controll configured on port dev/ttyAMA0 with read write permissions for your user profile on start up.

 # Pen Plotter Web Server
 
 [@henrytriplette](https://github.com/henrytriplette/ "@henryTriplette's Github home page") has done a amazing job creating a plotter web server. This, in combo with the PiPlot, takes all the hard work out of pen plotters. A modified fork of this , adapted for the Pi Plot, can be found here:

https://github.com/ithinkido/penplotter-webserver/tree/PiPlot  


[<p align="center"><img src="https://raw.githubusercontent.com/ithinkido/penplotter-webserver/PiPlot/docs/img/Demo.gif?sanitize=true" width=80%></p>](https://github.com/ithinkido/penplotter-webserver/tree/PiPlot "Pen-plotter web server screen shot")  


# Manually sending files to your plotter  

If you would like to manually send files to your plotter, the following notes will be useful.  

As the PiPlot shield handles full hardware flow conrol there is no need for using any form of software buffer control. You can simply use `cat`. eg.  
    
    cat myfile.hpgl > /dev/ttyAMA0

The port should be configured on boot for the correct baud and flow control, if you have omitted adding this to the crontab, you should call`sudo stty -F /dev/ttyAMA0 9600 crtscts` before sending the file  
    
    sudo stty -F /dev/ttyAMA0 9600 crtscts
    
# `wget` (the easy way to plot stuff you found online)

The wget command opens up the way to easily getting files you found on-line and sending them directly to the plotter all in one quick move.   
eg. Lets say you found [this](https://github.com/ithinkido/PiPlot/blob/main/images/columbia_A4_VS15.hpgl "HPGL file of the Colubia space shuttle") nice 80's classic plot of the space shuttle already in HPGL format. Throw this through the Pi Plot and watch the magic. 
    
    wget -O - https://raw.githubusercontent.com/ithinkido/PiPlot/main/images/columbia_A4_VS15.hpgl | cat > /dev/ttyAMA0

If you found an svg file, then vpype makes it easy, (presuming you have [vpype](https://github.com/abey79/vpype "vpype") installed - you really should - it rocks !)  
[<p align="center"><img src="https://raw.githubusercontent.com/abey79/vpype/master/docs/images/banner.png?sanitize=true" width= "50%"></p>](https://github.com/abey79/vpype "vpype")
    
    wget -O - https://raw.githubusercontent.com/ithinkido/PiPlot/main/images/columbia_A4.svg | vpype read - layout --landscape a4  write -f hpgl -d hp7475a - | cat > /dev/ttyAMA0

[<p align="center"><img src="https://raw.githubusercontent.com/ithinkido/PiPlot/main/images/columbia_A4.svg?sanitize=true" width=80%></p>](https://github.com/ithinkido/PiPlot/blob/main/images/columbia_A4.svg "Columbia space shuttle")

# Netcat and streaming  

Netcat can be used "stream" the files to your plotter wirelessly. To do this, first configure your Pi to listen on the port of your choice ( here 1234 ) using baud rate 9600 with hardware flow control enabled.
    
     sudo stty -F /dev/ttyAMA0 9600 crtscts
     nc -l -k 1234 > /dev/ttyAMA0

Sending data can be done from the terminal program of your choice by openning up a telnet session to the Pi on the port you chose earlier ( 1234 in this case).  

Alternatively you can set up Netcat on your local machine and send your file using this command: 

    nc PI-IP-ADRESS 1234 < yourfile.hpgl

By adding this all as a boot entry to your cron tab, you have a wireless "plotter server" all setup and waiting after boot.

    sudo crontab -e

add
    
    @reboot stty -F /dev/ttyUSB0 9600 crtscts && nc -l -k 1234 > /dev/ttyUSB0

## Foot Notes

* The Pi does not remember port configuration very well. It is good practice to call `sudo stty -F /dev/ttyAMA0 9600 crtscts` to reconfigure the port for hardware flow control before each plot( adjust baud to match your machine).
* The Pi shares the serial port with bluetooth. This is why it is necessary to disbale BT by adding the `dtoverlay=disable-bt` to your `/boot/config.txt`.
* On board LEDs are for buffer state (red) and TX data (green). When you plug in the PiPlot and power up the plotter the red buffer LED will turn **off**. This is a hardware a pre-check. It shows that the PiPlot and plotter are talking nicely to each other. In this case, on powering up, the plotter has said "I have space in the buffer", to which the PiPlot replies, "OK, I will turn off the buffer full LED then". The red LED is not a power indicator LED.
* Netcat relies on a constant connection to stream the files during the plot. You will not be able to complete the plot if this connection is broken. Under normal use this is not an issue, but it does mean that you will not be able to continue plotting if you shut down your laptop/PC during the plot while streaming over Netcat.

<br><br>

![visitors](https://visitor-badge.glitch.me/badge?page_id=ithinkido.PiPlot)
