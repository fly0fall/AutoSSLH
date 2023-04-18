#!/bin/bash

#Run this script as a root
echo 'Welcome to nginx and SSLH Auto installer';
sleep 2;
read -p 'Email: ' email
read -p 'Domain: ' domain
#Change ssh port
echo ""
echo -n "Please enter the port you would like SSH to run on > "
while read SSHPORT; do
	if [[ "$SSHPORT" =~ ^[0-9]{2,5}$ || "$SSHPORT" = 22 ]]; then
		if [[ "$SSHPORT" -ge 1024 && "$SSHPORT" -le 65535 || "$SSHPORT" = 22 ]]; then
			# Create backup of current SSH config
			NOW=$(date +"%m_%d_%Y-%H_%M_%S")
			cp /etc/ssh/sshd_config /etc/ssh/sshd_config.inst.bckup.$NOW
			# Apply changes to sshd_config
			sed -i -e "/Port /c\Port $SSHPORT" /etc/ssh/sshd_config
			echo -e "Restarting SSH in 5 seconds. Please wait.\n"
			sleep 5
			# Restart SSH service
			service sshd restart
			echo ""
			echo -e "The SSH port has been changed to $SSHPORT. Please login using that port to test BEFORE ending this session.\n"
			break
		else
			echo -e "Invalid port: must be 22, or between 1024 and 65535."
			echo -n "Please enter the port you would like SSH to run on > "
		fi
	else
		echo -e "Invalid port: must be numeric!"
		echo -n "Please enter the port you would like SSH to run on > "
	fi
done

echo ""


#update system
echo 'Update the system first';
sleep 2;
sudo apt-get update ;
sudo apt-get -y upgrade;

#install dependencies
echo 'Install dependencies';
sleep 2;
sudo apt-get -y install build-essential zlib1g-dev libpcre3 libpcre3-dev unzip apache2-utils;


#install Nginx
cd;
echo 'Install Nginx...';
sleep 2;
apt install nginx -y
systemctl start nginx
sudo ufw allow 'Nginx Full'
sudo ufw delete allow 'Nginx HTTP'
sudo apt install certbot python3-certbot-nginx -y

#install and configure SSL with Certbot
cd;
echo 'Install and configure SSL';
sleep 2;
sudo certbot -n --agree-tos --nginx -d $domain -m $email
sudo systemctl status certbot.timer
sudo certbot renew --dry-run
echo 'Change port SSL on Nginx';
sleep 2;
sed -i 's/443/8443/g' /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl reload nginx
sudo systemctl restart nginx

#install SSLH service
sudo apt install sslh -y
sed -i 's/<change-me>:443/0.0.0.0:443/g' /etc/default/sslh
sed -i 's/127.0.0.1:22/127.0.0.1:'$SSHPORT'/g' /etc/default/sslh
sed -i 's/127.0.0.1:443/127.0.0.1:8443/g' /etc/default/sslh
systemctl restart sslh


