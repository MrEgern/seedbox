#!/bin/bash
yum update -y
yum install -y gcc gcc-c++ make openssl-devel bzip2-devel libffi-devel nginx git rtorrent screen sqlite-devel
curl -sL https://rpm.nodesource.com/setup_11.x | sudo -E bash -
yum install -y nodejs
yum install -y python-certbot-nginx

adduser box
mkdir -p /data /data/film /data/serier
chown box:box /data -R
cat > /home/box/.rtorrent.rc <<EOF
scgi_port = 127.0.0.1:5000
session = /home/box/.rtorrent
directory = /home/box/downloads
schedule = watch_directory,60,60,load_start=/home/box/torrents/*.torrent
max_uploads_global = 100
max_downloads_global = 200
max_uploads = 50
min_peers = 20
max_peers = 60
min_peers_seed = -1
max_peers_seed = -1
trackers.numwant.set = -1
check_hash = no
port_range = 55950-56000
port_random = yes
upload_rate = 0
download_rate = 0
pieces.memory.max.set = 1500M
network.max_open_files.set = 128
network.http.max_open.set = 16
dht = disable
peer_exchange = no
schedule = untied_directory,5,5,stop_untied=
schedule = low_diskspace,5,60,close_low_diskspace=100M
encryption = allow_incoming,enable_retry,prefer_plaintext
system.file.max_size.set = -1
pieces.preload.type.set = 1
pieces.preload.min_size.set = 262144
pieces.preload.min_rate.set = 5120
network.send_buffer.size.set = 0
network.receive_buffer.size.set = 0
pieces.sync.always_safe.set = no
pieces.sync.timeout.set = 600
pieces.sync.timeout_safe.set = 900
session.name.set =
session.use_lock.set = yes
session.on_completion.set = yes
system.file.split_size.set = -1
system.file.split_suffix.set = .part
trackers.use_udp.set = yes
use_udp_trackers = yes
print="Config successfully read!"
EOF

su - box -c 'mkdir .rtorrent downloads torrents'
cat > /etc/systemd/system/rtorrent.service <<EOF
[Unit]
Description=rTorrent Service
After=network.target

[Service]
Type=forking
KillMode=none
ExecStart=/usr/bin/screen -d -m -fa -S rtorrent /usr/bin/rtorrent
ExecStop=/usr/bin/killall -w -s 2 /usr/bin/rtorrent
WorkingDirectory=/home/box
User=box
Group=box

[Install]
WantedBy=multi-user.target
EOF

systemctl enable nginx
systemctl start nginx

su - box -c 'git clone https://github.com/jfurrow/flood.git'
su - box -c 'cp flood/config.template.js flood/config.js'
su - box -c 'cd flood/ && npm install'
su - box -c 'cd flood/ && npm run build'
cat > /etc/systemd/system/flood.service <<EOF
[Service]
WorkingDirectory=/home/box/flood
ExecStart=/usr/bin/npm start
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=notell
User=box
Group=box
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/nginx/conf.d/flood.conf <<EOF
server {
        listen 80;
        server_name dl.example.com;

        location / {
                proxy_pass http://localhost:3000/;
        }
}
EOF


systemctl enable flood
systemctl start flood

PLEX_URL="https://plex.tv/downloads/latest/1?channel=8&build=linux-ubuntu-x86_64&distro=redhat"
wget -O /tmp/plexmediaserver.rpm "$PLEX_URL"

yum install -y /tmp/plexmediaserver.rpm
rm -rf /tmp/plexmediaserver.rpm

cat <<'EOF' >> /etc/nginx/conf.d/plex.conf
upstream plex-upstream {
        server 127.0.0.1:32400;
}

server {
        listen 80;
        server_name example.com;

        location / {
                if ($http_x_plex_device_name = '') {
                        rewrite ^/$ http://$http_host/web/index.html;
                }

                # set some headers and proxy stuff.
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                # Plex headers
                proxy_set_header X-Plex-Client-Identifier $http_x_plex_client_identifier;
                proxy_set_header X-Plex-Device $http_x_plex_device;
                proxy_set_header X-Plex-Device-Name $http_x_plex_device_name;
                proxy_set_header X-Plex-Platform $http_x_plex_platform;
                proxy_set_header X-Plex-Platform-Version $http_x_plex_platform_version;
                proxy_set_header X-Plex-Product $http_x_plex_product;
                proxy_set_header X-Plex-Token $http_x_plex_token;
                proxy_set_header X-Plex-Version $http_x_plex_version;
                proxy_set_header X-Plex-Nocache $http_x_plex_nocache;
                proxy_set_header X-Plex-Provides $http_x_plex_provides;
                proxy_set_header X-Plex-Device-Vendor $http_x_plex_device_vendor;
                proxy_set_header X-Plex-Model $http_x_plex_model;
                proxy_redirect off;

                # include Host header
                proxy_set_header Host $http_host;

                # proxy request to plex server
                proxy_pass http://plex-upstream;
        }
}
EOF

systemctl enable plexmediaserver
systemctl restart plexmediaserver


cd /usr/src
wget https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tgz
tar xzf Python-3.7.2.tgz
cd Python-3.7.2
./configure --enable-optimizations
make altinstall
rm /usr/src/Python-3.7.2.tgz

python3.7 -m pip install --upgrade pip
pip install flexget rarfile

su - box -c 'mkdir flexget/'
su - box -c 'wget -O flexget/config.yml https://github.com/ninstaah/flexget.danishbits/raw/master/config.yml'
su - box -c 'wget -O flexget/variables.yml https://github.com/ninstaah/flexget.danishbits/raw/master/variables.yml'
su - box -c 'cd ~/flexget/ && flexget daemon start -d --autoreload-config'

curl -fsSL https://filebrowser.xyz/get.sh | bash

cat > /etc/nginx/conf.d/filebrowser.conf <<EOF
server {
    listen 80;
    server_name file.example.com;

    location / {
            proxy_pass http://localhost:8080/;
    }
}
EOF

cat > /etc/systemd/system/filebrowser.service <<EOF
[Service]
Type=simple
User=box
Group=box
ExecStart=/usr/local/bin/filebrowser -r /home/box/ -d /home/box/filebrowser.db -p 8080
TimeoutStartSec=0
Restart=always
[Install]
WantedBy=multi-user.target
EOF

wget https://rarlab.com/rar/rarlinux-x64-5.7.0.tar.gz
tar xzf rarlinux-x64-5.7.0.tar.gz
rm -rf rarlinux-x64-5.7.0.tar.gz
cd rar
cp -v rar unrar /usr/local/bin/

echo -e "\nIndtast domæne (example.com):"
read DOMAIN

sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/plex.conf
sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/flood.conf
sed -i "s/example.com/$DOMAIN/g" /etc/nginx/conf.d/filebrowser.conf

certbot --nginx -d $DOMAIN.com --non-interactive --agree-tos --register-unsafely-without-email --redirect
certbot --nginx -d dl.$DOMAIN.com --non-interactive --agree-tos --register-unsafely-without-email --redirect
certbot --nginx -d file.$DOMAIN.com --non-interactive --agree-tos --register-unsafely-without-email --redirect

echo -e 'På din client (Win m. openssh klient, Mac, Linux):'
echo -e 'ssh server.ip.address -L 8888:localhost:32400'
echo -e "\nGå til http://localhost:8888/web \n- for Plex opsætningen"
