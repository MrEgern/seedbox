#!/bin/bash
PLEX_URL="https://plex.tv/downloads/latest/ \
          1?channel=8 \
          &build=linux-ubuntu-x86_64 \
          &distro=redhat"
PLEX_FILE=/tmp/plexmediaserver.rpm

wget -O $PLEX_FILE "$PLEX_URL"

yum localinstall -y $PLEX_FILE
rm -rf $PLEX_FILE
systemctl restart plexmediaserver