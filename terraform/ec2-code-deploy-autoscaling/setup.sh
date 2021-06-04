#!/bin/bash

apt update
apt install -y ruby-full wget
cd /home/ubuntu
wget https://aws-codedeploy-eu-west-1.s3.eu-west-1.amazonaws.com/latest/install
chmod +x ./install
./install auto > /tmp/logfile

apt update
apt install -y apache2
apt install -y mysql-server
apt install -y mysql
apt install -y php
rm /var/www/html/index.html