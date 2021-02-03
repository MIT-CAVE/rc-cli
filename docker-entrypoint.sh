#!/bin/sh
set -eu

echo "Starting the Docker daemon..."
/usr/local/bin/dockerd-entrypoint.sh dockerd >& /dev/null & # TODO(luisvasq): supress the stdout
while ! docker ps >/dev/null; do sleep 1; done # TODO(luisvasq): use a wait command.
echo "'dockerd' is running now"

echo "Loading the Docker image..."
docker load --quiet --input "/mnt/${IMAGE_FILE}"

echo "Running a Docker container..."
docker run --name=app \
  --mount type=bind,source=${INPUTS_DIR},target=/home/app/data/inputs,readonly \
  --mount type=bind,source=${OUTPUTS_DIR},target=/home/app/data/outputs \
  ${IMAGE_FILE:0:-7} # Remove the '.tar.gz' extension

echo "Done."

exec "$@"
