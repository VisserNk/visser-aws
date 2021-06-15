#!/bin/bash

apt update
apt install -y apache2
apt install -y php php-xml php-mbstring php-intl php-curl php-mysql php-mysqli php-gd
apt install -y mysql-client
apt install -y awscli
apt install -y php-cli unzip composer
cat > /var/www/html/.env << EOF
# DB credentials
SS_DATABASE_CLASS="MySQLDatabase"
SS_DATABASE_SERVER="mysql.internal"
SS_DATABASE_USERNAME="ubuntu"
SS_DATABASE_PASSWORD="ubuntu"
SS_DATABASE_NAME="firstpwa"

SS_ENVIRONMENT_TYPE="dev"

SS_DEFAULT_ADMIN_USERNAME="admin"
SS_DEFAULT_ADMIN_PASSWORD="admin"
EOF
chown www-data:www-data /var/www/html/.env
rm -f /var/www/html/index.html
apt install -y ruby-full wget
cd /home/ubuntu
wget https://aws-codedeploy-eu-west-1.s3.eu-west-1.amazonaws.com/latest/install
chmod +x ./install
./install auto > /tmp/logfile