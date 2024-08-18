#!/bin/bash

# This script automates the lab setup described in the book, Black Hat GraphQL by Dolev Farhi, Nick Aleks (https://nostarch.com/black-hat-graphql). A few tools have changed since the book was published, so for them the steps mentioned in the book do not work anymore. This script uses the updated steps to install / setup / configure those tools.

# Author: Uday Mittal (Yaksas Security) | https://github.com/yaksas443 | https://discord.gg/7PtbAxg | https://courses.yaksas.in

# It is tested on Ubuntu 22.04 (64-bit) Desktop Edition.

# Download and install Burp Suite Community edition from https://portswigger.net/burp/releases/professional-community-2023-7-1?requestededition=community

# This script can be run on a freshly installed Ubuntu 22.04 VM. Follow the steps below:
# 1. Copy and paste contents of this script in file. Save the file with .sh extension. For example, lab-setup.sh
# 2. Open a terminal (CTRL+ALT+T) and navigate to the folder where this script is stored.
# 3. Issue this command (gives execute permission to the script): chmod +x lab-setup.sh
# 4. Execute the script: ./lab-steup.sh

# Updating packages 
sudo apt update -y

# Creating a base directory to install / store all tools
cd /opt
sudo mkdir graphql-tools

# DON'T FORGET TO CHANGE THE USERNAME HERE
sudo chown ubuntu:ubuntu graphql-tools  

# Installing tools which can be installed via apt or snap

sudo apt install -y curl
sudo apt install -y git
sudo apt install -y nmap
sudo apt install -y fuse libfuse2
sudo apt install -y openjdk-17-jdk
sudo apt install -y snapd
sudo snap install altair
sudo snap install code
sudo snap install postman
sudo apt install -y docker.io

# Enabling docker service
sudo systemctl enable docker --now

# Adding a few commonly used tools to the Favorites bar in Ubuntu (works only on Gnome)
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'altair_altair.desktop']"	
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'code_code.desktop']"	
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'postman_postman.desktop']"	


# Cloning other tools from their respective GitHub Repositories

cd /opt/graphql-tools
git clone -b blackhatgraphql https://github.com/dolevf/Damn-Vulnerable-GraphQL-Application.git
git clone https://github.com/dolevf/graphw00f.git
git clone https://github.com/assetnote/batchql.git
git clone https://github.com/dolevf/graphql-cop.git
git clone https://github.com/commixproject/commix.git
git clone https://github.com/RedSiege/EyeWitness.git
git clone https://github.com/nicholasaleks/CrackQL.git
git clone https://github.com/doyensec/inql.git

# Downloading InQL v4.0.7 to install inql-cli
cd /tmp
wget https://github.com/doyensec/inql/archive/refs/tags/v4.0.7.zip
unzip v4.0.7.zip -d /opt/graphql-tools/inql-cli
mv /opt/graphql-tools/inql-cli/inql-4.0.7/* /opt/graphql-tools/inql-cli/
rm /tmp/v4.0.7.zip



# Building InQL v5.0 Burp extension. This can be loaded from build/InQL.jar post build.

cd /opt/graphql-tools/inql
git checkout dev
git submodule init
git submodule update
./gradlew

# Installing Clairvoyance as Python3 module and setting up other tools that require additional installation steps

python3 -m pip install clairvoyance

cd /opt/graphql-tools/EyeWitness/Python/setup
chmod +x setup.sh
sudo ./setup.sh

cd /opt/graphql-tools/graphql-cop
sudo python3 -m pip install -r /opt/graphql-tools/graphql-cop/requirements.txt

cd /opt/graphql-tools/CrackQL
sudo python3 -m pip install -r /opt/graphql-tools/CrackQL/requirements.txt

cd /opt/graphql-tools
mkdir graphql-path-enum
cd graphql-path-enum
wget "https://gitlab.com/dee-see/graphql-path-enum/-/jobs/artifacts/v1.1/raw/target/release/graphql-path-enum?job=build-linux" -O graphql-path-enum
chmod u+x graphql-path-enum

cd /opt/graphql-tools
wget https://github.com/graphql/graphql-playground/releases/download/v1.8.10/graphql-playground-electron-1.8.10-x86_64.AppImage -O graphql-playground.AppImage
chmod +x /opt/graphql-tools/graphql-playground.AppImage

cd /opt/graphql-tools/inql-cli/
rm -rf  inql-4.0.7
sudo python3 setup.py install

# Building and launching DVGA container. The app will be available at http://localhost:5013

cd /opt/graphql-tools/Damn-Vulnerable-GraphQL-Application
sudo docker build -t dvga .
sudo docker run -t --rm -d --name dvga -p 5013:5013 -e WEB_HOST=0.0.0.0 dvga

# Creating  and enabling a service to start the DVGA container or boot (this might not be the best approach to achieve this but it serves the purpose)

sudo touch /etc/systemd/system/docker-dvga.service
echo "[Unit]" | sudo tee --append /etc/systemd/system/docker-dvga.service
echo "Description=DVGA Container" | sudo tee --append /etc/systemd/system/docker-dvga.service
echo "Requires=docker.service" | sudo tee --append /etc/systemd/system/docker-dvga.service
echo "After=docker.service" | sudo tee --append /etc/systemd/system/docker-dvga.service
echo "" | sudo tee --append /etc/systemd/system/docker-dvga.service
echo "[Service]" | sudo tee --append /etc/systemd/system/docker-dvga.service
echo "ExecStart=/usr/bin/docker run -t --rm -d --name dvga -p 5013:5013 -e WEB_HOST=0.0.0.0 dvga" | sudo tee --append /etc/systemd/system/docker-dvga.service
echo "" | sudo tee --append /etc/systemd/system/docker-dvga.service
echo "[Install]" | sudo tee --append /etc/systemd/system/docker-dvga.service
echo "WantedBy=default.target" | sudo tee --append /etc/systemd/system/docker-dvga.service

sudo systemctl enable docker-dvga.service
