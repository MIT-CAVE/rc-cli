#!/bin/bash
#
# A library of Docker-related functions.

# Check if the Docker daemon is running.
docker::check_status() {
  if ! docker ps > /dev/null; then
    excep::err "cannot connect to the Docker daemon. Is the Docker daemon running?"
    exit 1
  fi
}

# Check if the given Docker image is already built in the host
docker::is_image_built() {
  local image_and_tag=$1
  docker image inspect ${image_and_tag} &> /dev/null
}
