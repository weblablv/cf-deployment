#!/usr/bin/env bash

set -euo pipefail

APP="${1:-}"
if [[ "$APP" != "landing" && "$APP" != "booking" && "$APP" != "crm" ]]; then
  echo "Usage: $0 landing|booking|crm"
  exit 1
fi

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="${WORKSPACE}/${APP}"
IMAGE="${FULL_IMAGE_NAME:-ceoflights/deploy}:${VERSION:-latest}"

if [[ ! -d "${APP_DIR}/.git" ]]; then
  echo "Error: ${APP_DIR} is not a git repo."
  exit 1
fi

tmp="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

git -C "$APP_DIR" archive HEAD | tar -x -C "$tmp"

docker_env=(
  -e VALIDATE_ONLY=1
  -e APP_NAME="$APP"
  -e STAGE=prod
  -e BRANCH=release/prod
)

if [[ -f "${tmp}/.env.dist" ]]; then
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    docker_env+=(-e "${name}=x")
  done < <(awk -F= '!/^($|#)/ {print $1}' "${tmp}/.env.dist")
fi

echo "Validating ${APP} with ${IMAGE}"
docker run --rm --platform "${PLATFORM:-linux/amd64}" \
  -v "${tmp}:/app" -w /app \
  "${docker_env[@]}" \
  "$IMAGE" \
  bash /opt/weblablv/deploy.sh
