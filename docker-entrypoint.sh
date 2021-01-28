#!/bin/sh
set -eu

echo "Starting the Docker daemon..."
/usr/local/bin/dockerd-entrypoint.sh >/dev/null dockerd &  # TODO(luisvasq): supress the stdout
while ! docker ps >/dev/null; do sleep 1; done # TODO(luisvasq): use a wait command.
echo "'dockerd' is running now"

echo "Loading the Docker image..."
load=$(docker load --quiet --input "${IMAGE_BASE_DIR}/${IMAGE_NAME}")

echo "Running a Docker container..."
docker run --name=arc \
  --mount type=bind,source=$DATA_DIR,target=/home/arc/data,readonly \
  --mount type=bind,source=$OUTPUT_DIR,target=/home/arc/output \
  ${load:14}

echo "Done."

exec "$@"
