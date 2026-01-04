#!/bin/bash
sudo apt update -y
sudo apt install -y mysql-client nginx
echo "Bastion Host" > /var/www/html/index.html
sudo systemctl start nginx
sudo systemctl enable nginx