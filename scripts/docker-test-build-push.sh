#!/usr/bin/env bash

set -e  # Exit on error

# Configuration
DOCKER_USERNAME="${DOCKER_USERNAME:-ceoflights}"
IMAGE_NAME="${IMAGE_NAME:-deploy}"
FULL_IMAGE_NAME="${DOCKER_USERNAME}/${IMAGE_NAME}"
VERSION="${VERSION:-latest}"
PLATFORM="${PLATFORM:-linux/amd64}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  print_error "Docker is not running. Please start Docker and try again."
  exit 1
fi

# Check if user is logged in to Docker Hub
if ! docker info | grep -q "Username"; then
  print_warn "Not logged in to Docker Hub. Attempting to login..."
  if [ -z "${DOCKER_PASSWORD}" ]; then
    print_error "DOCKER_PASSWORD environment variable is not set."
    print_info "Please run: docker login"
    exit 1
  fi
  echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
fi

print_info "Using image: ${FULL_IMAGE_NAME}:${VERSION}"
print_info "Platform: ${PLATFORM}"

# Export variables for npm scripts to use
export DOCKER_USERNAME
export IMAGE_NAME
export FULL_IMAGE_NAME
export VERSION
export PLATFORM

# Run the npm workflow
print_info "Running tests..."
npm test

print_info "Building Docker image..."
npm run docker:build

print_info "Testing Docker image..."
npm run docker:test

print_info "Pushing Docker image..."
npm run docker:push

# If version is not 'latest', also tag and push as latest
if [ "${VERSION}" != "latest" ]; then
  print_info "Tagging as latest..."
  docker tag "${FULL_IMAGE_NAME}:${VERSION}" "${FULL_IMAGE_NAME}:latest"
  
  print_info "Pushing latest tag..."
  docker push "${FULL_IMAGE_NAME}:latest"
fi

print_info "Successfully pushed ${FULL_IMAGE_NAME}:${VERSION} to Docker Hub!"

