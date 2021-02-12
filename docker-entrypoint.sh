#!/bin/sh
set -eu

readonly TIMEOUT_SETUP=$((8*60*60))
readonly TIMEOUT_EVALUATE=$((2*60*60))
readonly BENCHMARK_FILENAME="benchmark.json"
readonly CHARS_LINE="============================"

wait_for_docker() {
  while ! docker ps; do
    sleep 1
  done
}

load_image() {
  printf "Loading the $1 Image... "
  docker load --quiet --input "/mnt/$2" >& /dev/null
  printf "done\n"
}

run_app_image() {
  printf "\n${CHARS_LINE}\n"
  printf "Running the Solution Image [$1] ($2):\n\n"
  start_time=$(date +%s)
  timeout -s TERM $3 docker run --rm --entrypoint "$2.sh" $4 \
    --volume "/data/$2_inputs:/home/app/data/$2_inputs:ro" \
    --volume "/data/$2_outputs:/home/app/data/$2_outputs" \
    "$1:rc-cli"
  secs=$(($(date +%s) - start_time))
  # FIXME: consider different outcomes (fail, success, timeout, ...)
  printf "{ \"time\": ${secs}, \"status\": \"success\" }" > /data/$2_outputs/${BENCHMARK_FILENAME}
  printf "\nBenchmark Results:\n\n"
  printf "Time Elapsed: %dh:%dm:%ds\n" \
    $((secs / 3600)) $((secs % 3600 / 60)) $((secs % 60))
}

printf "Starting the Docker daemon... "
/usr/local/bin/dockerd-entrypoint.sh dockerd >& /dev/null &
wait_for_docker >& /dev/null
printf "done\n"

load_image "Solution" ${IMAGE_FILE}
image_name=${IMAGE_FILE:0:-7} # Remove the '.tar.gz' extension
run_app_image ${image_name} "setup" ${TIMEOUT_SETUP} ""
run_app_image ${image_name} "evaluate" ${TIMEOUT_EVALUATE} \
  "--volume /data/setup_outputs:/home/app/data/setup_outputs:ro"

# TODO: Run MLL Evaluation Script on `rc-out.json` along with the timings for `setup.sh` and `eval.sh`
load_image "Scoring" ${SCORING_IMAGE}
scoring_name=${SCORING_IMAGE:0:-7}
printf "\n${CHARS_LINE}\n"
printf "Running the Scoring Image [${scoring_name}]:\n\n"
docker run --rm \
  --volume "/data/evaluate_outputs:/home/scoring/data/evaluate_outputs:ro" \
  --volume "/data/scoring_inputs:/home/scoring/data/scoring_inputs:ro" \
  --volume "/data/scoring_outputs:/home/scoring/data/scoring_outputs" \
  "${scoring_name}:rc-cli"

exec "$@"
