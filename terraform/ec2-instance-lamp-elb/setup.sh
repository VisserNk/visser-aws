#!/bin/bash

apt update
apt install -y apache2
apt install -y mysql-server
apt install -y mysql
apt install -y php
rm /var/www/html/index.html
cat > /var/www/html/index.php << EOF
<?php

print_r($_SERVER["REMOTE_ADDR"]);

EOF