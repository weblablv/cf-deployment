#!/usr/bin/env bash

# Hard deprecation: APP_AWS_KEY is no longer supported. Use AWS_ACCESS_KEY_ID instead.
if [[ -n "${APP_AWS_KEY:-}" ]]; then
  echo "DEPRECATION ERROR: APP_AWS_KEY is deprecated and no longer supported."
  echo "Use AWS_ACCESS_KEY_ID instead. Deployment aborted."
  exit 1
fi

# shellcheck source=../resolve-env.sh
source /opt/weblablv/src/resolve-env.sh

export APPLICATION_NAME="${APP_NAME:-}"
if [[ -z "${APPLICATION_NAME}" ]]; then
  echo "Error: APP_NAME or BITBUCKET_REPO_SLUG is not set"
  exit 1
fi

export AWS_DEFAULT_REGION='eu-central-1'

cp /opt/weblablv/src/ec2/appspec.yml ./
cp /opt/weblablv/src/ec2/afterinstallRoot.sh ./
cp /opt/weblablv/src/ec2/afterinstall.sh ./
cp /opt/weblablv/src/ec2/GeoIPUpdate.sh ./

cp /opt/weblablv/src/ec2/rootCrontab.sh ./
bash rootCrontab.sh
rm rootCrontab.sh

cp /opt/weblablv/src/ec2/php-env.sh ./
bash php-env.sh || exit 1
rm php-env.sh

# Clean up .env.dist after php-env.sh has used it
rm -f .env.dist

tar -zcf /tmp/artifact.tar.gz .

if [[ -z ${AWS_ACCESS_KEY_ID} ]]; then
  echo "Error: AWS_ACCESS_KEY_ID is not set"
  exit 1
fi

if [[ -z ${AWS_SECRET_ACCESS_KEY} ]]; then
  echo "Error: AWS_SECRET_ACCESS_KEY is not set"
  exit 1
fi

S3BuildPath="s3://$S3_BUCKET/$APPLICATION_NAME/latest_bitbucket_builds.tar.gz"
# Check if bucket exists
if ! aws s3 ls "s3://$S3_BUCKET" 2>/dev/null; then
  echo "Error: S3 bucket $S3_BUCKET does not exist or you don't have permissions to access it"
  exit 1
fi

aws s3 cp /tmp/artifact.tar.gz "$S3BuildPath"

echo "Running CodeDeploy deployment."
python3 /opt/weblablv/src/ec2/codedeploy_deploy.py || exit 1
aws s3 rm "$S3BuildPath"
