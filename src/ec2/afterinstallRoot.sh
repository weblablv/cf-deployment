#!/usr/bin/env bash

cd /home/production/prod/app || exit 1

# WLCMS
if [ -f "config.php" ]; then
    HTTPDUSER=$(ps axo user:50,comm | grep -E '[a]pache|[h]ttpd|[_]www|[w]ww-data|[n]ginx' | grep -v root | awk '{print $1}' | head -n1)

    if [[ -z "$HTTPDUSER" ]]; then
      echo "ERROR: Could not determine HTTPDUSER. Exiting."
      exit 1
    fi

    mkdir -p files
    sudo setfacl -R -m u:"$HTTPDUSER":rwX -m u:production:rwX files
    sudo setfacl -dR -m u:"$HTTPDUSER":rwX -m u:production:rwX files
fi

if [[ -f "www.nginx" ]]; then
  mkdir -p /etc/nginx/sites-enabled
  rm -f /etc/nginx/sites-enabled/*
  mv www.nginx /etc/nginx/sites-enabled/

  nginx -t || exit 1
  service nginx reload || exit 1
fi

mv GeoIPUpdate.sh /root/ || exit 1
chmod +x /root/GeoIPUpdate.sh

if [[ -f "rootCrontab" ]]; then
  crontab rootCrontab || exit 1
  rm rootCrontab
fi

if [[ -f "awslogs" ]]; then
  mv awslogs /var/awslogs/etc/config/app.config
  service awslogs restart
fi

if [[ -f "cloudWatchAgentConfig.json" ]]; then
  sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:cloudWatchAgentConfig.json
fi

rm -f /home/production/prod/app/afterinstallRoot.sh
rm -f /home/production/prod/app/appspec.yml

# Remove any .md files in the project root
find /home/production/prod/app -maxdepth 1 -type f -name "*.md" -exec rm -f {} \;
