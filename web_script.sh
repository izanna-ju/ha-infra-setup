#!/bin/bash

apt-get update -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
apt-get install apache2 -y                    
systemctl start apache2.service
cd /var/www/html
aws s3 cp s3://izanna-web-bucket/sample_index.html .
systemctl restart apache2.service    