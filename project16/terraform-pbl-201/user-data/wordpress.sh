#!/bin/bash
sudo apt update -y
sudo apt install -y nginx php-fpm php-mysql
echo "WordPress Server" > /var/www/html/index.html
sudo systemctl start nginx
sudo systemctl enable nginx