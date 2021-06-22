#!/bin/bash

apt update
apt install -y mysql-server
mysqladmin -u root password ubuntu
mysql -u root -pubuntu -e "CREATE DATABASE firstpwa;"
mysql -u root -pubuntu -e "CREATE USER 'ubuntu'@'%' IDENTIFIED BY 'ubuntu'; GRANT ALL PRIVILEGES ON * . * TO 'ubuntu'@'%'; flush privileges;"
IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
sed -i "s/^bind-address.*/bind-address = ${IP}/g" /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql
apt install -y net-tools