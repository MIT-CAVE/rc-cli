#!/bin/sh
set -eu

is_docker_running() {
  while ! docker ps; do
    sleep 1
  done
}

printf "Starting the Docker daemon... "
/usr/local/bin/dockerd-entrypoint.sh dockerd >& /dev/null &

is_docker_running >& /dev/null

printf "done\n"
printf "Loading the Docker image... "
docker load --quiet --input "/mnt/${IMAGE_FILE}" >& /dev/null
printf "done\n"

printf "\n============================\n"
printf "Running the Solution Image [$IMAGE_FILE]\n\n"
# TODO: Allow for two docker different run items instead of run.sh -> setup.sh and eval.sh
# TODO: Time both container runs (setup.sh and eval.sh)
docker run --name=app \
  --mount type=bind,source=${INPUTS_DIR},target=/home/app/data/inputs,readonly \
  --mount type=bind,source=${OUTPUTS_DIR},target=/home/app/data/outputs \
  "${IMAGE_FILE:0:-7}:rc-cli" # Remove the '.tar.gz' extension

# TODO: Run MLL Evaluation Script on `rc-out.json` along with the timings for `setup.sh` and `eval.sh`
exec "$@"
