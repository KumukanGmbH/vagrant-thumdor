#!/bin/bash

# OpenCV is the only really complex aspect in this install
# we requrie it for face and edge recognition for image cropping
# https://medium.com/@manuganji/installation-of-opencv-numpy-scipy-inside-a-virtualenv-bf4d82220313
# https://github.com/edx/discern/wiki/Setup-Guide
# http://stackoverflow.com/questions/23040428/error-no-module-named-cv2
#

#
# Pillow
# http://codeinthehole.com/writing/how-to-install-pil-on-64-bit-ubuntu-1204/
#

# if [ -f .thumbor_installed ]
# then
#     exit
# fi

# Required for cmake of open-computer-vision
VIRTUAL_ENV=$HOME/.virtualenvs/thumbor

sudo aptitude update -yq

# Base Packages
sudo aptitude -yq install build-essential python-setuptools python-dev libcurl4-openssl-dev apache2-utils
# Image libraries
sudo apt-get install -yq libjpeg-dev libfreetype6-dev zlib1g-dev
sudo apt-get install -yq gfortran libopenblas-dev liblapack-dev
sudo ln -s /usr/lib/`uname -i`-linux-gnu/libfreetype.so /usr/lib/
sudo ln -s /usr/lib/`uname -i`-linux-gnu/libjpeg.so /usr/lib/
sudo ln -s /usr/lib/`uname -i`-linux-gnu/libz.so /usr/lib/

# Utils
sudo aptitude -yq install nmap htop vim unzip

# Applications
sudo aptitude -yq install supervisor
sudo aptitude -yq install nginx
sudo aptitude -yq install redis-server

# # Install pip and thumb
sudo easy_install pip
sudo pip install virtualenv virtualenvwrapper

# Create virtualenvs
echo "WORKON_HOME=/home/vagrant/.virtualenvs" >> "/home/vagrant/.bash_profile"
echo "source /usr/local/bin/virtualenvwrapper.sh" >> "/home/vagrant/.bash_profile"
source "/home/vagrant/.bash_profile"
mkdir -p "$WORKON_HOME"
mkvirtualenv thumbor

# OpenCv
sudo aptitude install -yq cmake python-opencv
if [ ! -f "/home/vagrant/.virtualenvs/thumbor/bin/cv2.so" ]
then
  wget -Oopencv-2.4.10.zip http://sourceforge.net/projects/opencvlibrary/files/opencv-unix/2.4.10/opencv-2.4.10.zip/download
  unzip opencv-2.4.10.zip
  cd opencv-2.4.10
  mkdir release
  sudo cmake '-D CMAKE_INSTALL_PREFIX=$VIRTUAL_ENV/local/ -D PYTHON_EXECUTABLE=$VIRTUAL_ENV/bin/python -D PYTHON_PACKAGES_PATH=$VIRTUAL_ENV/lib/python2.7/site-packages -D INSTALL_PYTHON_EXAMPLES=OFF'
  # numpy and scipy must be installed seperately
  pip install numpy==1.6.2
  pip install scipy==0.11.0
  # Copy Computervisions modules to
  cp /usr/lib/pymodules/python2.7/cv2.so /home/vagrant/.virtualenvs/thumbor/bin
fi

# Setup dirs
sudo mkdir -p /var/log/thumbor/
cd "$HOME"

# Create the ports
THUMBOR_PORT=`cat /home/vagrant/host/etc/thumbor.port`
NUM_THUMBOR_INSTANCES=`cat /home/vagrant/host/etc/thumbor.instances`
BASE_PORT=9000
PORTS=''
SERVERS=''
for ((i=1 ; i<=$NUM_THUMBOR_INSTANCES ; i++))
do
    PORTS="${PORTS}$(($BASE_PORT-1 + $i)),"
    SERVERS="${SERVERS}    server 127.0.0.1:$(($BASE_PORT-1 + $i));\n"
done
sudo cp /home/vagrant/host/etc/thumbor.nginx /etc/nginx/conf.d/thumbor.conf
sudo perl -pi -e "s/SERVER_STUB/$SERVERS/;s/PORT/$THUMBOR_PORT/" /etc/nginx/conf.d/thumbor.conf

sudo cp /home/vagrant/host/etc/thumbor.default /etc/default/thumbor
echo "port="$PORTS | sudo tee -a /etc/default/thumbor > /dev/null

# Supervisor
sudo cp /home/vagrant/host/etc/supervisor.thumbor.conf /etc/supervisor/conf.d/thumbor.conf
sudo perl -pi -e "s/NUM_THUMBOR_INSTANCES/$NUM_THUMBOR_INSTANCES/" /etc/supervisor/conf.d/thumbor.conf

# Thumbor defaults
sudo cp /home/vagrant/host/etc/thumbor.conf.default /etc/thumbor.conf
cat /home/vagrant/host/etc/thumbor.conf.custom | sudo tee -a /etc/thumbor.conf > /dev/null

if [ -s /home/vagrant/host/etc/thumbor.key ]
then
    sudo cp /home/vagrant/host/etc/thumbor.key /etc/thumbor.key
else
    < /dev/urandom tr -dc a-z0-9 | head -c16 | sudo tee /etc/thumbor.key > /dev/null
fi

# install thumbor
workon thumbor
pip install thumbor redis -U


sudo service nginx restart > /dev/null
sudo service supervisor restart > /dev/null
sudo service redis-server restart > /dev/null

# sudo rm /var/lib/dhcp/*
# # Makes the packaged box a bit smaller but takes a while to run:
# dd if=/dev/zero of=/tmp/ZEROS bs=1M ; rm /tmp/ZEROS

touch .thumbor_installed
