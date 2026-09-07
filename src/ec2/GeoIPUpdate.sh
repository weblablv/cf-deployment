#!/usr/bin/env bash

if [[ $(whoami) != "root" ]]; then
  echo "Please run as root user"
  exit
fi

installDir=/usr/local/share/GeoIP

rm -rf $installDir
mkdir -p $installDir
cd $installDir || exit 1

wget https://wl-geo-ip.s3.eu-central-1.amazonaws.com/GeoLite2-Country.mmdb
wget https://wl-geo-ip.s3.eu-central-1.amazonaws.com/GeoLite2-City.mmdb
