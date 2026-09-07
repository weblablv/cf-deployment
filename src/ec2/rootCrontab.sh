#!/usr/bin/env bash

echo "# m h  dom mon dow   command

" >rootCrontab

if [[ -z ${S3_LOG_BUCKET+x} ]]; then
  echo "#No S3_LOG_BUCKET defined." >>rootCrontab
  # Print deprecation warning to the console in yellow with warning sign
  echo -e "\033[1;33m⚠️  WARNING: This cron setup will be deprecated as of Apr 1 2026. Please update your deployment processes accordingly.\033[0m"
else
  echo "* * * * * aws s3 sync /home/production/cronlog s3://$S3_LOG_BUCKET/$APP_NAME/cronlog --delete
* * * * * aws s3 sync /var/log/nginx s3://$S3_LOG_BUCKET/$APP_NAME/nginx --delete
* * * * * aws s3 sync /home/production/prod/app/files/logs s3://$S3_LOG_BUCKET/$APP_NAME/files/logs --delete
0 0 * * 6 rm -rf /home/production/cronlog/*
" >>rootCrontab
fi

echo "0 0 1 * * ~/GeoIPUpdate.sh
1 0 * * * journalctl --vacuum-time=2d && journalctl --vacuum-size=100M
2 0 * * * apt autoremove -y && apt autoclean -y
" >>rootCrontab
