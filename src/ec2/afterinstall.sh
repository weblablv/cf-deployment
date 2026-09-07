#!/usr/bin/env bash

cd /home/production/prod/app

# Composer
if [ -f "composer.lock" ]; then
    composer install --no-ansi --no-dev --no-progress --optimize-autoloader
fi

# WLCMS
if [ -f "config.php" ]; then
    php vendor/bin/doctrine-migrations migrations:migrate --no-interaction
fi

if [ -f "crontab" ]; then
    crontab crontab
fi

if [ -f "package-lock.json" ]; then
  echo "package-lock.json found running npm ci"
  npm ci --no-audit || exit 1
  if [ -f "gulpfile.js" ]; then
    echo "gulpfile.js running gulp build"
    gulp build || exit 1
  fi
fi

rm -rf /home/production/prod/app/migrations
rm -f /home/production/prod/app/afterinstall.sh
