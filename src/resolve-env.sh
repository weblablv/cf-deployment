# Deploy identity from CI. Required names only; no Bitbucket fallbacks.
# Safe to source more than once. Does not invent default values.
export APP_NAME="${APP_NAME:-}"
export STAGE="${STAGE:-}"
export BRANCH="${BRANCH:-}"
export COMMIT="${COMMIT:-}"
export BUILD_ID="${BUILD_ID:-}"
