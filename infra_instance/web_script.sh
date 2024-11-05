#!/bin/bash
set -e
set -x

# Update and install prerequisites
apt update -y
apt upgrade -y
apt install unzip -y

# Install AWS CLI
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo ./aws/install

# Install Apache
apt-get install apache2 -y
systemctl start apache2.service

# Copy file from S3 bucket
cd /var/www/html

sudo rm -r *
sudo aws s3 cp s3://izanna-web-bucket/barista_cafe_web.zip .
sudo unzip barista_cafe_web.zip
sudo mv 2137_barista_cafe/* .
sudo rm -r *cafe*

# Restart Apache 
systemctl restart apache2.service