# Resolve generic deploy identity from new names, with Bitbucket fallbacks.
# Safe to source more than once. Does not invent default values.
export APP_NAME="${APP_NAME:-${BITBUCKET_REPO_SLUG:-}}"
export STAGE="${STAGE:-${BITBUCKET_DEPLOYMENT_ENVIRONMENT:-}}"
export BRANCH="${BRANCH:-${BITBUCKET_BRANCH:-}}"
export COMMIT="${COMMIT:-${BITBUCKET_COMMIT:-}}"
export BUILD_ID="${BUILD_ID:-${BITBUCKET_BUILD_NUMBER:-}}"
