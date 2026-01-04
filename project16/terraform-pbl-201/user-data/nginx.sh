#!/bin/bash
sudo apt update -y
sudo apt install -y nginx
echo "Nginx Reverse Proxy" > /var/www/html/index.html
sudo systemctl start nginx
sudo systemctl enable nginx