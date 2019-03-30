#!/bin/bash
yum update -y
yum install -y gcc gcc-c++ make openssl-devel bzip2-devel libffi-devel nginx python-certbot-nginx git rtorrent screen sqlite-devel 
curl -sL https://rpm.nodesource.com/setup_11.x | sudo -E bash -
yum install -y nodejs

# Rar/Unrar 
wget https://rarlab.com/rar/rarlinux-x64-5.7.0.tar.gz
tar xzf rarlinux-x64-5.7.0.tar.gz
cp rar/{rar,unrar} /usr/local/bin/
rm -rf rarlinux-x64-5.7.0.tar.gz rar/

# Adduser
adduser box
mkdir -p /data /data/film /data/serier
chown box:box /data -R

# Rtorrent
su - box -c 'wget -O .rtorrent.rc https://github.com/ninstaah/seedbox/raw/master/rtorrent/rtorrent.rc'
su - box -c 'mkdir .rtorrent downloads torrents'

wget -O /etc/systemd/system/rtorrent.service https://github.com/ninstaah/seedbox/raw/master/systemd/rtorrent.service

systemctl enable rtorrent
systemctl start rtorrent

# Flood js
su - box -c 'git clone https://github.com/jfurrow/flood.git'
su - box -c 'cp flood/config.template.js flood/config.js'
su - box -c 'cd flood/ && npm install'
su - box -c 'cd flood/ && npm run build'

wget -O /etc/systemd/system/flood.service https://github.com/ninstaah/seedbox/raw/master/systemd/flood.service
wget -O /etc/nginx/conf.d/flood.conf https://github.com/ninstaah/seedbox/raw/master/nginx/flood.conf

systemctl enable flood
systemctl start flood

# Plex media server
PLEX_URL="https://plex.tv/downloads/latest/1?channel=8&build=linux-ubuntu-x86_64&distro=redhat"
wget -O /tmp/plexmediaserver.rpm "$PLEX_URL"

yum install -y /tmp/plexmediaserver.rpm
rm -rf /tmp/plexmediaserver.rpm

wget -O /etc/nginx/conf.d/plex.conf https://github.com/ninstaah/seedbox/raw/master/nginx/plex.conf

systemctl enable plexmediaserver
systemctl restart plexmediaserver

# Python 3.7.2 (alt install, usage: python3.7)
# - upgrade pip aswell
cd /usr/src
wget https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tgz
tar xzf Python-3.7.2.tgz
cd Python-3.7.2
./configure --enable-optimizations
make altinstall
rm -rf /usr/src/Python-3.7.2.tgz
python3.7 -m pip install --upgrade pip

# Flexget
pip install flexget rarfile

su - box -c 'mkdir flexget/'
su - box -c 'wget -O flexget/config.yml https://github.com/ninstaah/seedbox/raw/master/config.yml'
su - box -c 'wget -O flexget/variables.yml https://github.com/ninstaah/seedbox/raw/master/variables.yml'
su - box -c 'cd ~/flexget/ && flexget daemon start -d --autoreload-config'


# Filebrowser
curl -fsSL https://filebrowser.xyz/get.sh | bash

wget -O /etc/nginx/conf.d/filebrowser.conf https://github.com/ninstaah/seedbox/raw/master/nginx/filebrowser.conf
wget -O /etc/systemd/system/filebrowser.service https://github.com/ninstaah/seedbox/raw/master/systemd/filebrowser.service

systemctl enable filebrowser
systemctl restart filebrowser

echo -e "\nIndtast domæne (example.com):"
read DOMAIN

sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/plex.conf
sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/flood.conf
sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/filebrowser.conf

systemctl enable nginx
systemctl start nginx

certbot --nginx -d $DOMAIN.com --non-interactive --agree-tos --register-unsafely-without-email --redirect
certbot --nginx -d dl.$DOMAIN.com --non-interactive --agree-tos --register-unsafely-without-email --redirect
certbot --nginx -d file.$DOMAIN.com --non-interactive --agree-tos --register-unsafely-without-email --redirect

echo -e 'På din client (Win m. openssh klient, Mac, Linux):'
echo -e 'ssh server.ip.address -L 8888:localhost:32400'
echo -e "\nGå til http://localhost:8888/web \n- for Plex opsætningen"