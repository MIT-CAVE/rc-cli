#!/bin/sh
set -eu

is_docker_running() {
  while ! docker ps; do; sleep 1; done
}

echo -n "Starting the Docker daemon... "
/usr/local/bin/dockerd-entrypoint.sh dockerd >& /dev/null & # TODO(luisvasq): supress the stdout

is_docker_running() 2>/dev/null

echo "done"
echo -n "Loading the Docker image... "
docker load --quiet --input "/mnt/${IMAGE_FILE}"
echo "done"

echo -n "Running the solution container... "
# TODO: Allow for two docker different run items instead of run.sh -> setup.sh and eval.sh
# TODO: Time both container runs (setup.sh and eval.sh)
docker run --name=app \
  --mount type=bind,source=${INPUTS_DIR},target=/home/app/data/inputs,readonly \
  --mount type=bind,source=${OUTPUTS_DIR},target=/home/app/data/outputs \
  "${IMAGE_FILE:0:-7}:rc-cli" # Remove the '.tar.gz' extension
echo "done"

# TODO: Run MLL Evaluation Script on `rc-out.json` along with the timings for `setup.sh` and `eval.sh`

echo "Finished!"

exec "$@"
