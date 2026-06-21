#!/bin/bash
set -euo pipefail

WORKDIR=digipi

reset_install() {
  rm -rf "$WORKDIR"
  rm -rf /etc/lighttpd/conf-enabled/*
  rm -rf /home/pi
  userdel -r pi
  if [ -f /lib/systemd/system/lighttpd.service.orig ]; then
    cp /lib/systemd/system/lighttpd.service.orig /lib/systemd/system/lighttpd.service
  fi
  rm -rf direwolf
}

reset_install

# Function to enforce root privileges
ensure_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "[-] Error: This script requires root privileges." >&2
        exit 1
    fi
}

build_direwolf() {
  git clone https://github.com/wb2osz/direwolf.git
  cd direwolf
  mkdir build && cd build
  cmake ..
  make -j2
  make install
  cd ../..
  rm -rf direwolf
}

# Run the check
ensure_root

# packages
echo Installing required packages
apt update
apt install -y sudo git curl lighttpd php-cgi libasound2 alsa-utils ax25-tools ax25-apps libax25 libhamlib-utils flrig fldigi hamradio-files wsjtx git gcc g++ cmake make libasound2-dev libudev-dev libgps-dev gpsd gpiod libgpiod-dev wmctrl xdotool fim

# user and group management
useradd -m -s /bin/bash pi
sudo usermod -aG sudo pi
sudo usermod -aG sudo www-data

# Direwolf permissions
touch /run/direwolf.log
touch /run/direwolf.tnc.conf
chown pi:pi /run/direwolf.log /run/direwolf.tnc.conf

# Get DigiPi
echo
echo Getting DigiPi
mkdir "$WORKDIR"
git clone https://github.com/craigerl/digipi.git "$WORKDIR"

# Binaries
echo
echo Copying binaries
cp -a "$WORKDIR"/usr/local/bin/* /usr/local/bin

# Direwolf
build_direwolf

# ARDOP
echo
echo Getting ARDOP
curl -L -o /usr/local/bin/ardopcf https://github.com/pflarue/ardop/releases/download/1.0.4.1.3/ardopcf_arm_Linux_64

# AX25 configuration files
echo
echo Copying ax25 conf files
cp -a "$WORKDIR"/etc/ax25/* /etc/ax25

# services
echo
echo Setting up services
cp -a "$WORKDIR"/systemd/system/* /etc/systemd/system
cp -a etc/systemd/system/tracker.service /etc/systemd/system
systemctl daemon-reload

# Backup the lighttpd service
if [ -f /lib/systemd/system/lighttpd.service.orig ]; then
    echo "Backup already exists, skipping."
else
    sudo cp -p /lib/systemd/system/lighttpd.service /lib/systemd/system/lighttpd.service.orig
    echo "Backup created."
fi
patch /lib/systemd/system/lighttpd.service lib/systemd/system/lighttpd.service.diff  

# pi home
echo
echo Setting Pi home
cp -a "$WORKDIR"/home/pi /home


# site
echo
echo Setting web interface
cp -a "$WORKDIR"/var/www/html/* /var/www/html

# webserver config
cp -av etc/lighttpd/conf-available/20-digipi.conf /etc/lighttpd/conf-available
cp -av etc/lighttpd/conf-available/90-javascript-alias.conf /etc/lighttpd/conf-available
lighty-enable-mod unconfigured
lighty-enable-mod fastcgi
lighty-enable-mod fastcgi-php
lighty-enable-mod javascript-alias
lighty-enable-mod digipi
systemctl daemon-reload
service lighttpd force-reload

echo
echo You can connect to DigiPI on the following address:
echo "http://$(hostname -I | awk '{print $1}')"

