#!/bin/bash
set -e
set -x

# Update and install prerequisites
apt update -y
apt upgrade -y
apt install unzip -y

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Apache
apt-get install apache2 -y                    
systemctl start apache2.service

# Copy file from S3 bucket
cd /var/www/html
aws s3 cp s3://izanna-web-bucket/sample_index.html .

cp sample_index.html index.html

# Restart Apache
systemctl restart apache2.service
