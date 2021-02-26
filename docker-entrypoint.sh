#!/bin/sh
set -u

readonly CHARS_LINE="============================"
readonly RC_IMAGE_TAG="rc-cli"
readonly MODEL_BUILD_TIMEOUT=$((8*60*60))
readonly MODEL_APPLY_TIMEOUT=$((2*60*60))
readonly APP_DEST_MNT="/home/app/data"

wait_for_docker() {
  while ! docker ps; do
    sleep 1
  done
}

#######################################
# Load a Docker image created by rc-cli.
# Globals:
#   None
# Arguments:
#   image_file
# Returns:
#   None
#######################################
load_image() {
  image_file=$1
  printf "Loading the Image... "
  docker load --quiet --input "/mnt/${image_file}" > /dev/null 2>&1
  printf "done\n"
}

# Convert a number of seconds to the ISO 8601 standard.
secs_to_iso_8601() {
  printf "%dh:%dm:%ds" $(($1 / 3600)) $(($1 % 3600 / 60)) $(($1 % 60))
}

# Get a status message from a given stderr value
get_status() {
  error=$1
  case ${error} in
    Killed)
      printf "\nWARNING! production-test: Timeout has occurred when running '$1'\n" >&2
      printf "timeout"
      ;;
    "")
      printf "success"
      ;;
    *)
      printf "\n${error}\n" >&2
      printf "fail: ${error}"
      ;;
  esac
}

#######################################
# Send the output and time stats of the running app container
# to the standard output and a given output file.
# Globals:
#   None
# Arguments:
#   secs, error, out_file
# Returns:
#   None
#######################################
print_stdout_stats() {
  secs=$1
  error=$2
  out_file=$3
  printf "{ \"time\": ${secs}, \"status\": \"$(get_status "${error}")\" }" > ${out_file}
  printf "\nTime Elapsed: $(secs_to_iso_8601 ${secs})\n"
}

#######################################
# Run a snapshot (Docker image) for a given 'model-*' command
# Globals:
#   None
# Arguments:
#   cmd, image_name, timeout_in_secs, run_opts
# Returns:
#   None
#######################################
run_app_image() {
  cmd=$1
  image_name=$2
  timeout_in_secs=$3
  run_opts=$4

  printf "\n${CHARS_LINE}\n"
  printf "Running the Image [${image_name}] (${cmd}):\n\n"

  start_time=$(date +%s)
  # TODO: Improve redirection to avoid using a file for stderr
  timeout -s KILL ${timeout_in_secs} \
    docker run --rm --entrypoint "${cmd}.sh" ${run_opts} \
    --volume "/data/${cmd}_inputs:${APP_DEST_MNT}/${cmd}_inputs:ro" \
    --volume "/data/${cmd}_outputs:${APP_DEST_MNT}/${cmd}_outputs" \
    ${image_name}:${RC_IMAGE_TAG} 2>/var/tmp/error
  secs=$(($(date +%s) - start_time))

  [ -f /var/tmp/error ] && error=$(cat /var/tmp/error) || error=""
  print_stdout_stats "${secs}" "${error}" \
    "/data/model_score_timings/${cmd}_time.json"
}

printf "Starting the Docker daemon... "
/usr/local/bin/dockerd-entrypoint.sh dockerd > /dev/null 2>&1 &
wait_for_docker > /dev/null 2>&1
printf "done\n"

load_image ${IMAGE_FILE}
image_name=${IMAGE_FILE:0:-7} # Remove the '.tar.gz' extension
run_app_image "model_build" ${image_name} ${MODEL_BUILD_TIMEOUT} ""
run_app_image "model_apply" ${image_name} ${MODEL_APPLY_TIMEOUT} \
  "--volume /data/model_build_outputs:${APP_DEST_MNT}/model_build_outputs:ro"

printf "\n"
load_image ${SCORING_IMAGE}
scoring_name=${SCORING_IMAGE:0:-7}
printf "\n${CHARS_LINE}\n"
printf "Running the Scoring Image [${scoring_name}]:\n\n"
# The time stats file is mounted in a different directory
docker run --rm \
  --volume "/data/model_apply_inputs:${APP_DEST_MNT}/model_apply_inputs:ro" \
  --volume "/data/model_apply_outputs:${APP_DEST_MNT}/model_apply_outputs:ro" \
  --volume "/data/model_score_inputs:${APP_DEST_MNT}/model_score_inputs:ro" \
  --volume "/data/model_score_timings:${APP_DEST_MNT}/model_score_timings:ro" \
  --volume "/data/model_score_outputs:${APP_DEST_MNT}/model_score_outputs" \
  ${scoring_name}:${RC_IMAGE_TAG}

exec "$@"
