#!/bin/sh
set -u

readonly TIME_STATS_FILENAME="time_stats.json"
readonly CHARS_LINE="============================"
readonly TIMEOUT_SETUP=$((8*60*60))
readonly TIMEOUT_EVALUATE=$((2*60*60))

wait_for_docker() {
  while ! docker ps; do
    sleep 1
  done
}

load_image() {
  printf "Loading the $1 Image... "
  docker load --quiet --input "/mnt/$2" > /dev/null 2>&1
  printf "done\n"
}

run_app_image() {
  printf "\n${CHARS_LINE}\n"
  printf "Running the Solution Image [$1] ($2):\n\n"

  start_time=$(date +%s)
  timeout -s KILL $3 docker run --rm --entrypoint "$2.sh" $4 \
    --$()volume "/data/$2_inputs:/home/app/data/$2_inputs:ro" \
    --volume "/data/$2_outputs:/home/app/data/$2_outputs" \
    "$1:rc-cli" 2>/var/tmp/error
  secs=$(($(date +%s) - start_time))

  [ -f /var/tmp/error ] && error=$(cat /var/tmp/error) || error=""
  # Provide feedback for the user.
  case ${error} in
    Killed)
      status="timeout"
      printf "\nWARNING! test: Timeout has occurred when running '$2'\n"
      ;;
    "")
      status="success"
      ;;
    *)
      status="fail: ${error}"
      printf "\n${error}\n"
      ;;
  esac

  printf "{ \"time\": ${secs}, \"status\": \"${status}\" }" \
    > /data/$2_outputs/${TIME_STATS_FILENAME} # Write time stats to output file
  printf "\nTime Elapsed: %dh:%dm:%ds\n" \
    $((secs / 3600)) $((secs % 3600 / 60)) $((secs % 60))
}

printf "Starting the Docker daemon... "
/usr/local/bin/dockerd-entrypoint.sh dockerd > /dev/null 2>&1 &
wait_for_docker > /dev/null 2>&1
printf "done\n"

load_image "Solution" ${IMAGE_FILE}
image_name=${IMAGE_FILE:0:-7} # Remove the '.tar.gz' extension
run_app_image ${image_name} "setup" ${TIMEOUT_SETUP} ""
run_app_image ${image_name} "evaluate" ${TIMEOUT_EVALUATE} \
  "--volume /data/setup_outputs:/home/app/data/setup_outputs:ro"

printf "\n"
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
