#!/bin/bash
read -p "Indtast domæne: " DOMAIN

yum update -y
yum install -y gcc gcc-c++ make openssl-devel bzip2-devel libffi-devel nginx python-certbot-nginx git rtorrent screen sqlite-devel 

if [ ! -f /usr/bin/node ]; then
	curl -sL https://rpm.nodesource.com/setup_11.x | sudo -E bash -
	yum install -y nodejs
fi

# Rar/Unrar 
if [ ! -f /usr/local/bin/rar ]; then
	wget https://rarlab.com/rar/rarlinux-x64-5.7.0.tar.gz
	tar xzf rarlinux-x64-5.7.0.tar.gz
	cp rar/{rar,unrar} /usr/local/bin/
	rm -rf rarlinux-x64-5.7.0.tar.gz rar/
fi

# Adduser
adduser box
mkdir -p /data /data/film /data/serier
chown box:box /data -R

# Rtorrent
if [ ! -f /home/box/.rtorrent.rc ]; then
	su - box -c 'wget -O .rtorrent.rc https://github.com/MrEgern/seedbox/raw/master/rtorrent/rtorrent.rc'
	su - box -c 'mkdir -p .rtorrent downloads torrents'
fi

# Flood js
if [ ! -d /home/box/flood ]; then
	su - box -c 'git clone https://github.com/jfurrow/flood.git'
	su - box -c 'cp flood/config.template.js flood/config.js'
	su - box -c 'cd flood/ && npm install'
	su - box -c 'cd flood/ && npm run build'
fi

# Plex media server
if [ ! -d /usr/lib/plexmediaserver ]; then
	PLEX_URL="https://plex.tv/downloads/latest/1?channel=8&build=linux-ubuntu-x86_64&distro=redhat"
	wget -O /tmp/plexmediaserver.rpm "$PLEX_URL"
	yum install -y /tmp/plexmediaserver.rpm
	rm -rf /tmp/plexmediaserver.rpm
fi

# Python 3.7.2 (alt install, usage: python3.7)
if [ ! -f /usr/local/bin/python3.7 ]; then
    echo "Installing Python 3.7.2 (compiling)"
    cd /usr/src
	wget https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tgz
	tar xzf Python-3.7.2.tgz
	cd Python-3.7.2
	./configure --enable-optimizations
	make altinstall
	rm -rf /usr/src/Python-3.7.2.tgz
fi

# Flexget
if [ ! -f /usr/local/bin/flexget ]; then
	python3.7 -m pip install --upgrade pip
	pip install flexget rarfile
fi

if [ ! -d /home/box/flexget ]; then
	su - box -c 'mkdir -p flexget/'
	su - box -c 'wget -O flexget/config.yml https://github.com/MrEgern/seedbox/raw/master/flexget/config.yml'
	su - box -c 'wget -O flexget/variables.yml https://github.com/MrEgern/seedbox/raw/master/flexget/variables.yml'
	su - box -c 'cd ~/flexget/ && flexget daemon start -d --autoreload-config'
fi

# Filebrowser
if [ ! -f /usr/local/bin/filebrowser ]; then
	curl -fsSL https://filebrowser.xyz/get.sh | bash
fi

# NGINX conf files
wget -O /etc/nginx/conf.d/flood.conf https://github.com/MrEgern/seedbox/raw/master/nginx/flood.conf
wget -O /etc/nginx/conf.d/plex.conf https://github.com/MrEgern/seedbox/raw/master/nginx/plex.conf
wget -O /etc/nginx/conf.d/filebrowser.conf https://github.com/MrEgern/seedbox/raw/master/nginx/filebrowser.conf

# Systemd service files
wget -O /etc/systemd/system/rtorrent.service https://github.com/MrEgern/seedbox/raw/master/systemd/rtorrent.service
wget -O /etc/systemd/system/flood.service https://github.com/MrEgern/seedbox/raw/master/systemd/flood.service
wget -O /etc/systemd/system/filebrowser.service https://github.com/MrEgern/seedbox/raw/master/systemd/filebrowser.service

systemctl enable --now rtorrent flood filebrowser plexmediaserver nginx
systemctl start rtorrent flood filebrowser plexmediaserver nginx

# Domæne opsætning
sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/plex.conf
sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/flood.conf
sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/filebrowser.conf

# SSL certifikater
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email --redirect
certbot --nginx -d dl.$DOMAIN --non-interactive --agree-tos --register-unsafely-without-email --redirect
certbot --nginx -d file.$DOMAIN --non-interactive --agree-tos --register-unsafely-without-email --redirect

# Bruger vejledning
echo -e "### Opsætning af Plex"
echo -e "ssh root@$(curl -s ifconfig.me) -L 8888:localhost:32400"
echo -e "Gå til http://localhost:8888/web"
