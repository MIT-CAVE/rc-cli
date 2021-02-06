#!/bin/sh
set -eu

wait_for_docker() {
  while ! docker ps; do
    sleep 1
  done
}

run_app_image() {
  printf "\n============================\n"
  printf "Running the Solution Image [$1] ($2):\n\n"
  docker run --rm --entrypoint "$2.sh" $3 \
    --volume "/data/$2_inputs:/home/app/data/$2_inputs:ro" \
    --volume "/data/$2_outputs:/home/app/data/$2_outputs" \
    "$1:rc-cli"
}

printf "Starting the Docker daemon... "
/usr/local/bin/dockerd-entrypoint.sh dockerd >& /dev/null &
wait_for_docker >& /dev/null
printf "done\n"

printf "Loading the Docker image... "
docker load --quiet --input "/mnt/${IMAGE_FILE}" >& /dev/null
printf "done\n"

# TODO: Time both container runs (setup.sh and evaluate.sh)
image_name=${IMAGE_FILE:0:-7} # Remove the '.tar.gz' extension
run_app_image ${image_name} "setup" ""
run_app_image ${image_name} "evaluate" \
  "--volume /data/setup_outputs:/home/app/data/setup_outputs:ro"

# TODO: Run MLL Evaluation Script on `rc-out.json` along with the timings for `setup.sh` and `eval.sh`
exec "$@"
