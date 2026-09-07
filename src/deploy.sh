#!/usr/bin/env bash

export AWS_DEFAULT_REGION='eu-central-1'

# shellcheck source=resolve-env.sh
source /opt/weblablv/src/resolve-env.sh

LOG_DIR="/tmp"
LOG_APP="${APP_NAME:-unknown-app}"
LOG_STAGE="${STAGE:-unknown-stage}"
LOG_BUILD="${BUILD_ID:-unknown-build}"
LOG_COMMIT="${COMMIT:-unknown-commit}"

LOG_FILE="${LOG_DIR}/deployment-${LOG_BUILD}-${LOG_COMMIT}.log"
S3_LOG_URI="s3://${S3_BUCKET:-}/logs/${LOG_APP}/${LOG_STAGE}/${LOG_BUILD}-${LOG_COMMIT}.log"

is_validate_only() {
  [[ "${VALIDATE_ONLY:-}" == "1" || "${VALIDATE_ONLY:-}" == "true" ]]
}

upload_deployment_log_to_s3() {
  # Always try at exit, but never fail deployment if upload fails.
  if is_validate_only; then
    return 0
  fi
  if [[ -z "${S3_BUCKET:-}" ]]; then
    echo "WARN: S3_BUCKET is not set; skipping deployment log upload."
    return 0
  fi

  if [[ "$LOG_APP" == "unknown-app" || "$LOG_STAGE" == "unknown-stage" || "$LOG_BUILD" == "unknown-build" || "$LOG_COMMIT" == "unknown-commit" ]]; then
    echo "WARN: Missing deploy identity env vars; skipping deployment log upload."
    echo "WARN: Expected APP_NAME, STAGE, BUILD_ID, COMMIT (or BITBUCKET_REPO_SLUG, BITBUCKET_DEPLOYMENT_ENVIRONMENT, BITBUCKET_BUILD_NUMBER, BITBUCKET_COMMIT)."
    return 0
  fi

  if [[ ! -f "$LOG_FILE" ]]; then
    echo "WARN: Log file not found at $LOG_FILE; skipping deployment log upload."
    return 0
  fi

  echo "Uploading deployment log to ${S3_LOG_URI}"
  local aws_cp_out=""
  aws_cp_out="$(aws s3 cp "$LOG_FILE" "$S3_LOG_URI" 2>&1)"
  local aws_cp_rc=$?
  if [[ $aws_cp_rc -eq 0 ]]; then
    echo "Deployment log uploaded to ${S3_LOG_URI}"
  else
    echo "WARN: Failed to upload deployment log to ${S3_LOG_URI} (continuing)."
    echo "WARN: aws s3 cp output: ${aws_cp_out}"
  fi
}

on_exit() {
  exit_code=$?
  echo ""
  echo "Deployment finished with exit code ${exit_code}"
  upload_deployment_log_to_s3
  echo "Local deployment log: ${LOG_FILE}"
  if ! is_validate_only; then
    echo "Remote deployment log: ${S3_LOG_URI}"
  fi
  exit "${exit_code}"
}

trap on_exit EXIT

# Capture all stdout/stderr to log file, while still printing to console.
mkdir -p "$LOG_DIR" 2>/dev/null || true
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================="
echo "Deployment started at $(date)"
echo "App: ${LOG_APP}"
echo "Stage: ${LOG_STAGE}"
echo "Build: ${LOG_BUILD}"
echo "Commit: ${LOG_COMMIT}"
echo "Validate only: ${VALIDATE_ONLY:-no}"
echo "Log file: ${LOG_FILE}"
echo "S3 log: ${S3_LOG_URI}"
echo "========================================="

cat /root/versions.txt

if [[ ! -f "config.php" ]]; then
  echo "Error: config.php not found. This deployer only supports PHP EC2 apps."
  exit 1
fi

node /opt/weblablv/src/validation/index.js || exit 1

if is_validate_only; then
  echo "VALIDATE_ONLY is set. Skipping package and CodeDeploy."
  exit 0
fi

# Clean up Git-related files before deployment
rm -rf .git
rm -f .gitignore
rm -f bitbucket-pipelines.yml

printf "Running PHP deployment to EC2\n"
bash /opt/weblablv/src/ec2/deploy.sh || exit 1
node /opt/weblablv/src/createCloudFrontInvalidation.js || exit 1
