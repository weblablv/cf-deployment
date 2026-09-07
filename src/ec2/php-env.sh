#!/bin/bash

set -euo pipefail

# Only generate .env if .env.dist exists
if [[ ! -f ".env.dist" ]]; then
  echo "No .env.dist found, skipping generation of .env for PHP."
  exit 0
fi

echo "Generating .env from .env.dist for PHP app..."
# Extract variable names from .env.dist (non-empty, non-comment),
# exclude AWS keys, and emit NAME=VALUE pairs from the current environment.
awk -F= '!/^($|#)/ {print $1}' .env.dist \
  | grep -Ev '^(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY)$' \
  | while read -r NAME; do
      VALUE="${!NAME:-}"
      ESCAPED_VALUE="${VALUE//\"/\\\"}"
      printf '%s="%s"\n' "$NAME" "$ESCAPED_VALUE"
    done > .env

echo ".env generated successfully."
