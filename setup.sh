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
	su - box -c 'wget -O .rtorrent.rc https://github.com/ninstaah/seedbox/raw/master/rtorrent/rtorrent.rc'
	su - box -c 'mkdir -p .rtorrent downloads torrents'
	wget -O /etc/systemd/system/rtorrent.service https://github.com/ninstaah/seedbox/raw/master/systemd/rtorrent.service
	systemctl enable rtorrent
	systemctl start rtorrent
fi

# Flood js
if [ ! -d /home/box/flood ]; then
	su - box -c 'git clone https://github.com/jfurrow/flood.git'
	su - box -c 'cp flood/config.template.js flood/config.js'
	su - box -c 'cd flood/ && npm install'
	su - box -c 'cd flood/ && npm run build'
	wget -O /etc/systemd/system/flood.service https://github.com/ninstaah/seedbox/raw/master/systemd/flood.service
	wget -O /etc/nginx/conf.d/flood.conf https://github.com/ninstaah/seedbox/raw/master/nginx/flood.conf
	systemctl enable flood
	systemctl start flood
fi

# Plex media server
if [ ! -d /usr/lib/plexmediaserver ]; then
	PLEX_URL="https://plex.tv/downloads/latest/1?channel=8&build=linux-ubuntu-x86_64&distro=redhat"
	wget -O /tmp/plexmediaserver.rpm "$PLEX_URL"
	yum install -y /tmp/plexmediaserver.rpm
	rm -rf /tmp/plexmediaserver.rpm
	wget -O /etc/nginx/conf.d/plex.conf https://github.com/ninstaah/seedbox/raw/master/nginx/plex.conf
	systemctl enable plexmediaserver
	systemctl restart plexmediaserver
fi

# Python 3.7.2 (alt install, usage: python3.7)
# - upgrade pip aswell
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

python3.7 -m pip install --upgrade pip

# Flexget
if [ ! -f /usr/local/bin/flexget ]; then
	pip install flexget rarfile
fi

if [ ! -d /home/box/flexget ]; then
	su - box -c 'mkdir -p flexget/'
	su - box -c 'wget -O flexget/config.yml https://github.com/ninstaah/seedbox/raw/master/flexget/config.yml'
	su - box -c 'wget -O flexget/variables.yml https://github.com/ninstaah/seedbox/raw/master/flexget/variables.yml'
	su - box -c 'cd ~/flexget/ && flexget daemon start -d --autoreload-config'
fi

# Filebrowser
if [ ! -f /usr/local/bin/filebrowser ]; then
	curl -fsSL https://filebrowser.xyz/get.sh | bash
	wget -O /etc/nginx/conf.d/filebrowser.conf https://github.com/ninstaah/seedbox/raw/master/nginx/filebrowser.conf
	wget -O /etc/systemd/system/filebrowser.service https://github.com/ninstaah/seedbox/raw/master/systemd/filebrowser.service
	systemctl enable filebrowser
	systemctl restart filebrowser
fi

# Domæne opsætning
sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/plex.conf
sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/flood.conf
sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/filebrowser.conf

systemctl enable nginx
systemctl start nginx

# SSL certifikater
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email --redirect
certbot --nginx -d dl.$DOMAIN --non-interactive --agree-tos --register-unsafely-without-email --redirect
certbot --nginx -d file.$DOMAIN --non-interactive --agree-tos --register-unsafely-without-email --redirect

# Bruger vejledning
echo -e "### Opsætning af Plex"
echo -e "ssh root@$(curl -s ifconfig.me) -L 8888:localhost:32400"
echo -e "Gå til http://localhost:8888/web"

echo -e "### Opsætning af Flexget"
echo -e "Gå til https://file.$DOMAIN (admin/admin - husk at ændre dette!)"
echo -e "1. Gå til https://file.$DOMAIN/files/flexget/variables.yml"
echo -e "2. Åben tab med https://danishbits.org/rss.php"
echo -e "3. Kopier links fra step 2 til deres pladser i flexget/variables.yml (step 1)"
echo -e "4. Gem https://file.$DOMAIN/files/flexget/variables.yml)"
echo -e "5. Gå til https://file.$DOMAIN/files/flexget/config.yml)"
echo -e "6. Gå til linje 23 & 25, indsæt serie liste med danske/nordiske undertekster"
echo -e "7. Gå til linje 43 & 45, Indsæt serie liste med dansk tale (dvs. ingen subs!)"
echo -e "8. Gem filen og vent på Flexget genindlæser config.yml (ved fejl i filen, indlæses der ikke en ny)"