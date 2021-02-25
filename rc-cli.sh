#!/bin/bash
#
# A CLI for the Routing Challenge.

# Constants
readonly CHARS_LINE="============================"

readonly RC_CLI_DEFAULT_TEMPLATE="rc_python"
readonly RC_CLI_PATH="${HOME}/.rc-cli"
readonly RC_CLI_LONG_NAME="Routing Challenge CLI"
readonly RC_CLI_SHORT_NAME="RC CLI"
readonly RC_CLI_VERSION=$(<${RC_CLI_PATH}/VERSION)
readonly RC_IMAGE_TAG="rc-cli"
readonly RC_SCORING_IMAGE="rc-scoring"
readonly RC_TEST_IMAGE="rc-test"

readonly APP_DEST_MNT="/home/app/data"
readonly SCORING_DEST_MNT="/home/scoring/data"
readonly TMP_DIR="/tmp"

#######################################
# Display an error message when the user input is invalid.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
err() {
  printf "$(basename $0): $1\n" >&2
}

# Convert string from kebab case to snake case.
kebab_to_snake() {
  printf $1 | sed s/-/_/
}

# Determine if the current directory contains a valid RC app
valid_app_dir() {
  [[
    -f Dockerfile \
 && -f model_apply.sh \
 && -f model_build.sh \
 && -d src \
 && -d snapshots \
 && -d data/model_apply_inputs \
 && -d data/model_apply_outputs \
 && -d data/model_build_inputs \
 && -d data/model_build_outputs
 && -d data/model_score_inputs \
 && -d data/model_score_outputs \
 && -d data/model_score_timings
 ]]
}

is_image_built() {
  docker image inspect $1:${RC_IMAGE_TAG} &> /dev/null
}

# Check if the Docker daemon is running.
check_docker() {
  if ! docker ps > /dev/null; then
    err "cannot connect to the Docker daemon. Is the Docker daemon running?"
    exit 1
  fi
}

# Get the current date and time expressed according to ISO 8601.
timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%:z"
}

# Convert a number of seconds to the ISO 8601 standard.
secs_to_iso_8601() {
  printf "%dh:%dm:%ds" $(($1 / 3600)) $(($1 % 3600 / 60)) $(($1 % 60))
}

# Check that the CLI is run from a valid app
# directory and returns the base name directory.
check_app() {
  if ! valid_app_dir; then
    err "not a valid app directory"
    exit 1
  fi
  app_name=$(basename "$(pwd)")
}

# Run basic checks on requirements for some commands.
basic_checks() {
  check_app
  check_docker
}

get_templates () {
RC_TEMPLATES="$(\
  ls -d $RC_CLI_PATH/templates/*/ | \
  awk -F'/' ' {print $(NF-1)} ' \
  )"
}

get_new_template_string () {
  get_templates
  RC_NEW_TEMPLATE_STRING="$(\
    printf "$RC_TEMPLATES" | \
    tr '\n' ',' | \
    sed 's/,/\n- /g' \
    )"
}

get_help_template_string () {
  get_templates
  RC_HELP_TEMPLATE_STRING="$(\
    printf "$RC_TEMPLATES" | \
    tr '\n' ',' | \
    sed 's/,/\n      - /g'\
    )"
}

# Strips off any leading directory components.
get_snapshot() {
  # Allows easy autocompletion in bash using created folder names
  # Example: my-image/ -> my-image, path/to/snapshot
  printf "$(basename ${1:-''})"
}

check_snapshot() {
  local snapshot=$1

  local f_name
  f_name="$(get_snapshot ${snapshot})"
  if [[ ! -f "snapshots/${f_name}/${f_name}.tar.gz" ]]; then
    err "${f_name}: snapshot not found"
    exit 1
  fi
  printf ${f_name}
}

# Prompts for a 'snapshot' name if the given snapshot exists
get_image_name() {
  local src_cmd=$1
  local snapshot=$2

  local input=${snapshot}
  while [[ -f "snapshots/${input}/${input}.tar.gz" && -n ${input} ]]; do
    # Prompt confirmation to overwrite or rename image
    printf "WARNING! ${src_cmd}: Snapshot with name '${snapshot}' exists\n" >&2
    read -r -p "Enter a new name or overwrite [${snapshot}]: " input
    [[ -n ${input} ]] && snapshot=${input}
    printf "\n" >& 2
  done
  printf ${input}
}

select_template() {
  get_new_template_string
  while ! printf "$RC_TEMPLATES" | grep -w -q "$template"; do
    # Prompt confirmation to select proper template
    if [[ -z ${template} ]]; then
      printf "WARNING! new: A template was not provided:\n"
    else
      printf "WARNING! new: The supplied template (${template}) does not exist.\n"
    fi
    printf "The following are valid templates:\n- ${RC_NEW_TEMPLATE_STRING}\n"
    template="$RC_CLI_DEFAULT_TEMPLATE"
    read -r -p "Enter your selection [${template}]: " input
    [[ -n ${input} ]] && template=${input}
    printf "\n"
  done
}

#######################################
# Build a Docker image based on the given arguments.
# Globals:
#   None
# Arguments:
#   src_cmd, image_name, context, build_opts
# Returns:
#   None
#######################################
build_image() {
  local src_cmd=$1
  local image_name=$2
  local context="${3:-.}"
  local build_opts=${@:4} # FIXME

  local f_name
  local out_file
  f_name="$(kebab_to_snake ${src_cmd})"
  printf "${CHARS_LINE}\n"
  printf "Build Image [${image_name}]:\n\n"
  printf "Building the '${image_name}' image... "
  docker rmi ${image_name}:${RC_IMAGE_TAG} &> /dev/null
  [[ -d "logs/${f_name}" ]] \
    && out_file="logs/${f_name}/${image_name}_build_$(timestamp).log" \
    || out_file="/dev/null"
  docker build --file ${context}/Dockerfile --tag ${image_name}:${RC_IMAGE_TAG} \
    ${build_opts} ${context} &> ${out_file}
  printf "done\n\n"
}

# Load the Docker image for a given snapshot name.
load_snapshot() {
  local snapshot=$1

  local f_name
  f_name="$(kebab_to_snake ${snapshot})"
  docker rmi ${snapshot}:${RC_IMAGE_TAG} &> /dev/null
  docker load --quiet --input "snapshots/${f_name}/${f_name}.tar.gz" &> /dev/null
}

# Get the relative path of the data directory based
# on the existence or not of a given 'snapshot' arg.
get_data_context() {
  local snapshot=$1

  [[ -z ${snapshot} ]] \
    && printf "data" \
    || printf "snapshots/$(kebab_to_snake ${snapshot})/data"
}

# Same than 'get_data_context' but return the absolute path.
get_data_context_abs() {
  printf "$(pwd)/$(get_data_context $1)"
}

# Save a Docker image to the 'snapshots' directory.
save_image() {
  local image_name=$1

  local f_name
  f_name="$(kebab_to_snake ${image_name})"
  printf "${CHARS_LINE}\n"
  printf "Save Image [${image_name}]:\n\n"
  printf "Saving the '${image_name}' image to 'snapshots'... "
  snapshot_path="snapshots/${f_name}"
  mkdir -p ${snapshot_path}
  cp -R "${RC_CLI_PATH}/data" "${snapshot_path}/data"
  docker save ${image_name}:${RC_IMAGE_TAG} \
    | gzip > "${snapshot_path}/${f_name}.tar.gz"
  printf "done\n\n"
}

#######################################
# Retrieve a clean copy of 'data' from the 'rc-cli' sources.
# Globals:
#   None
# Arguments:
#   src_cmd, data_path
# Returns:
#   None
#######################################
reset_data_prompt() {
  local src_cmd=$1
  local data_path=$2

  local f_name
  f_name="$(kebab_to_snake ${src_cmd})"
  printf "WARNING! ${src_cmd}: This will reset the data directory at '${data_path}' to a blank state\n"
  read -r -p "Are you sure you want to continue? [y/N] " input
  case ${input} in
    [yY][eE][sS] | [yY])
      printf "Resetting the data... "
      rm -rf "${data_path}"
      cp -R "${RC_CLI_PATH}/data" "${data_path}"
      printf "done\n"
      ;;
    [nN][oO] | [nN] | "")
      printf "${src_cmd} was canceled by the user\n"
      exit 0
      ;;
    *)
      err "invalid input: The ${src_cmd} was canceled"
      exit 1
      ;;
  esac
}

get_status() {
  [[ -z $1 ]] \
    && printf "success" \
    || printf "fail" # : $(printf $1 | sed s/\"/\"/)" # TODO: handle newlines
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
  local secs=$1
  local error=$2
  local out_file=$3
  printf "{ \"time\": ${secs}, \"status\": \"$(get_status ${error})\" }" > ${out_file}
  printf "\nTime Elapsed: $(secs_to_iso_8601 ${secs})\n"
  printf "\n${CHARS_LINE}\n"
}

#######################################
# Run a Docker image for the specified 'model-*' command
# Globals:
#   None
# Arguments:
#   src_cmd, image_type, image_name, src_mnt, run_opts
# Returns:
#   None
#######################################
run_app_image() {
  local src_cmd=$1
  local image_type=$2
  local image_name=$3
  local src_mnt=$4
  local run_opts=${@:5}

  local f_name
  f_name="$(kebab_to_snake ${src_cmd})"

  printf "${CHARS_LINE}\n"
  printf "Running ${image_type} [${image_name}] (${src_cmd}):\n\n"
  start_time=$(date +%s)
  { error=$(docker run --rm --entrypoint "${f_name}.sh" ${run_opts} \
    --volume ${src_mnt}/${f_name}_inputs:${APP_DEST_MNT}/${f_name}_inputs:ro \
    --volume ${src_mnt}/${f_name}_outputs:${APP_DEST_MNT}/${f_name}_outputs \
    ${image_name}:${RC_IMAGE_TAG} 2>&1 >&3 3>&-); } 3>&1; echo ${error} \
    | tee "logs/${f_name}/${image_name}_$(timestamp).log"
  secs=$(($(date +%s) - start_time))

  print_stdout_stats ${secs} ${error} \
    "${src_mnt}/model_score_timings/${f_name}_time.json"
}

#######################################
# Run a Docker image for the specified 'model-*' command
# Globals:
#   None
# Arguments:
#   src_cmd, image_type, image_name, src_mnt, run_opts
# Returns:
#   None
#######################################
run_dev_image() {
  local src_cmd=$1
  local image_type=$2
  local image_name=$3
  local src_mnt=$4
  local run_opts=${@:5}

  local f_name
  # Remove '-dev' and convert to snake_case:
  # 'model-build-dev' => 'model_build'
  f_name=$(printf ${src_cmd} | sed s/-dev// | kebab_to_snake)

  printf "${CHARS_LINE}\n"
  printf "Running ${image_type} [${image_name}] (${src_cmd}):\n\n"
  start_time=$(date +%s)
  { error=$(docker run --rm --entrypoint "" ${run_opts} \
    --volume "$(pwd)/src:/home/app/src" \
    --volume "$(pwd)/${f_name}.sh:/home/app/${f_name}.sh" \
    --volume $4/${f_name}_inputs:${APP_DEST_MNT}/${f_name}_inputs:ro \
    --volume $4/${f_name}_outputs:${APP_DEST_MNT}/${f_name}_outputs \
    --interactive --tty ${image_name}:${RC_IMAGE_TAG} ${f_name}.sh 2>&1 >&3 3>&-); } \
    3>&1; echo ${error} | tee "logs/${f_name}/${image_name}_$(timestamp).log" sh
  secs=$(($(date +%s) - start_time))

  print_stdout_stats ${secs} ${error} \
    "${src_mnt}/model_score_timings/${f_name}_time.json"
}

#######################################
# Run a production test with the '${RC_TEST_IMAGE}'
# Globals:
#   None
# Arguments:
#   src_cmd, image_name, data_path
# Returns:
#   None
#######################################
run_test_image() {
  local src_cmd=$1
  local image_name=$2
  local data_path=$3

  local src_mnt
  local src_mnt_image
  local image_file="$2.tar.gz"
  local scoring_image="${RC_SCORING_IMAGE}.tar.gz"
  src_mnt="$(pwd)/${data_path}"

  # Check if the 'snapshot' argument was not specified, i.e.
  # "get_data_context $2" in 'production-test' returned 'data'.
  [[ ${data_path} == 'data' ]] \
    && src_mnt_image="${TMP_DIR}/${image_file}" \
    || src_mnt_image="$(pwd)/snapshots/${image_name}/${image_file}"
  printf "${src_cmd}: The data at '${data_path}' has been reset to the initial state\n\n"
  printf "${CHARS_LINE}\n"
  printf "Preparing Test Image [${image_name}] to Run With [${RC_TEST_IMAGE}]:\n\n"

  docker run --privileged --rm \
    --env IMAGE_FILE=${image_file} \
    --env SCORING_IMAGE=${scoring_image} \
    --volume "${RC_CLI_PATH}/scoring/${scoring_image}:/mnt/${scoring_image}:ro" \
    --volume "${src_mnt_image}:/mnt/${image_file}:ro" \
    --volume "${src_mnt}/model_build_inputs:/data/model_build_inputs:ro" \
    --volume "${src_mnt}/model_build_outputs:/data/model_build_outputs" \
    --volume "${src_mnt}/model_apply_inputs:/data/model_apply_inputs:ro" \
    --volume "${src_mnt}/model_apply_outputs:/data/model_apply_outputs" \
    --volume "${src_mnt}/model_score_inputs:/data/model_score_inputs:ro" \
    --volume "${src_mnt}/model_score_outputs:/data/model_score_outputs" \
    --volume "${src_mnt}/model_score_timings:/data/model_score_timings" \
    ${RC_TEST_IMAGE}:${RC_IMAGE_TAG} 2>&1 \
    | tee "logs/$(kebab_to_snake ${src_cmd})/${image_name}_run_$(timestamp).log"
}

#######################################
# Run the scoring Docker image for the model.
# Globals:
#   None
# Arguments:
#   src_cmd, image_name, data_path
# Returns:
#   None
#######################################
run_scoring_image() {
  local src_cmd=$1
  local image_type=$2
  local image_name=$3
  local src_mnt=$4

  printf "${CHARS_LINE}\n"
  printf "Enabling the ${image_type} [${image_name}] to Run With [${RC_SCORING_IMAGE}]:\n\n"
  docker run --rm \
    --volume "${src_mnt}/model_apply_outputs:${SCORING_DEST_MNT}/model_apply_outputs:ro" \
    --volume "${src_mnt}/model_score_inputs:${SCORING_DEST_MNT}/model_score_inputs:ro" \
    --volume "${src_mnt}/model_score_timings:${SCORING_DEST_MNT}/model_score_timings:ro" \
    --volume "${src_mnt}/model_score_outputs:${SCORING_DEST_MNT}/model_score_outputs" \
    ${RC_SCORING_IMAGE}:${RC_IMAGE_TAG} 2>&1 \
    | tee "logs/$(kebab_to_snake ${src_cmd})/${image_name}_$(timestamp).log"
  printf "\n${CHARS_LINE}\n"
}

make_logs() { # Ensure the necessary log file structure for the calling command
  mkdir -p "logs/$(kebab_to_snake $1)"
}

# Single main function
main() {
  if [[ $# -lt 1 ]]; then
    err "missing command operand"
    exit 1
  elif [[ $# -gt 2 && $1 != "new-model" && $1 != "new" && $1 != "nm" ]]; then
    err "too many arguments"
    exit 1
  fi

  # Select the command
  case $1 in
    new-model | new | nm)
      # Create a new app based on a template
      if [[ $# -lt 2 ]]; then
        err "Missing arguments. Try using:\nrc-cli help"
        exit 1
      elif [[ -d "$2" ]]; then
        err "Cannot create app '$2': This folder already exists in the current directory"
        exit 1
      fi
      template=${3:-"None Provided"}
      select_template
      template_path="${RC_CLI_PATH}/templates/${template}"
      cp -R "${template_path}" "$2"
      cp "${RC_CLI_PATH}/templates/README.md" "$2"
      cp -R "${RC_CLI_PATH}/data" "$2"
      chmod +x $(echo "$2/*.sh")
      [[ -z $3 ]] && optional="by default "
      printf "the '${template}' template has been created ${optional}at '$(pwd)/$2'\n"
      ;;

    save-snapshot | save | ss)
      # Build the app image and save it to the 'snapshots' directory
      cmd="save-snapshot"
      make_logs ${cmd}
      basic_checks
      snapshot="$(basename ${2:-''})"
      [[ -z ${snapshot} ]] && tmp_name=${app_name} || tmp_name=${snapshot}
      printf "${CHARS_LINE}\n"
      printf "Save Precheck for App [${tmp_name}]:\n\n"
      get_image_name ${cmd} ${tmp_name}
      printf "Save Precheck Complete\n\n"
      build_image ${cmd} ${image_name}
      save_image ${image_name}
      printf "${CHARS_LINE}\n"
      ;;

    model-build | build | mb | model-apply | apply | ma)
      # Build and run the 'model-[build,apply].sh' script
      [[ $1 == "model-build" || $1 == "build" || $1 == "mb" ]] \
        && cmd="model-build" \
        || cmd="model-apply"
      make_logs ${cmd}
      basic_checks
      if [[ -z $2 ]]; then
        image_name=${app_name}
        build_image ${cmd} ${app_name}
        image_type="App"
      else
        check_snapshot $2
        image_name=$(get_snapshot $2)
        load_snapshot ${image_name}
        image_type="Snapshot"
      fi

      src_mnt=$(get_data_context_abs $2)
      [[ ${cmd} == "model-apply" ]] \
        && run_opts="--volume ${src_mnt}/model_build_outputs:${APP_DEST_MNT}/model_build_outputs:ro"
      run_app_image ${cmd} ${image_type} ${image_name} ${src_mnt} ${run_opts}
      ;;

    model-build-dev | build-dev | mb-dev | model-apply-dev | apply-dev | ma-dev)
      # Build a Docker image (if it doesn't exist) and run the 'model-*.sh' script
      if [[ $# -gt 1 ]]; then
        err "too many arguments"
        exit 1
      fi
      [[ $1 == "model-build-dev" || $1 == "build-dev" || $1 == "mb-dev" ]] \
        && cmd="model-build-dev" || cmd="model-apply-dev"
      make_logs ${cmd}
      basic_checks
      image_name=${app_name}
      if ! is_image_built ${app_name}; then
        build_image ${cmd} ${app_name}
      fi
      image_type="App"

      src_mnt="$(pwd)/data"
      [[ ${cmd} == "model-apply-dev" ]] \
        && run_opts="--volume ${src_mnt}/model_build_outputs:${APP_DEST_MNT}/model_build_outputs:ro"
      run_dev_image ${cmd} ${image_type} ${image_name} ${src_mnt} ${run_opts}
      ;;

    production-test | test | pt)
      # Run the tests with the '${RC_TEST_IMAGE}'
      basic_checks
      [[ -n $2 ]] && check_snapshot $2 # Sanity check

      cmd="production-test"
      data_path=$(get_data_context $2)
      reset_data_prompt ${cmd} ${data_path}
      printf '\n' # Improve formatting

      make_logs ${cmd}

      if [[ -z $2 ]]; then
        image_name=${app_name}
        build_image ${cmd} ${image_name}
        docker save ${image_name}:${RC_IMAGE_TAG} | gzip > "${TMP_DIR}/${image_name}.tar.gz"
      else
        image_name=$(get_snapshot $2)
        load_snapshot ${image_name}
      fi

      # Saving time if some images exist.
      if ! is_image_built ${RC_TEST_IMAGE}; then
        build_image ${cmd} ${RC_TEST_IMAGE} ${RC_CLI_PATH}
      fi
      if ! is_image_built ${RC_SCORING_IMAGE}; then
        build_image ${cmd} ${RC_SCORING_IMAGE} ${RC_CLI_PATH}/scoring
      fi
      if [[ ! -f "scoring/${RC_SCORING_IMAGE}.tar.gz" ]]; then
        docker save ${RC_SCORING_IMAGE}:${RC_IMAGE_TAG} \
          | gzip > "${RC_CLI_PATH}/scoring/${RC_SCORING_IMAGE}.tar.gz"
      fi
      run_test_image ${cmd} ${image_name} ${data_path}
      printf "\n${CHARS_LINE}\n"
      ;;

    model-score | score | ms)
      # Calculate the score for the app or the specified snapshot.
      basic_checks
      # 'model_build_outputs' and 'model_apply_outputs' must exist,
      # as well as 'model_score_outputs' and 'model_score_timings'
      src_mnt=$(get_data_context_abs $2)
      model_build_time="${src_mnt}/model_score_timings/model_build_time.json"
      model_apply_time="${src_mnt}/model_score_timings/model_apply_time.json"
      if [[ ! -d "${src_mnt}/setup_outputs" ]]; then
        err "'${src_mnt}/setup_outputs': data not found"
        exit 1
      elif [[ ! -d "${RC_CLI_PATH}/data/model_score_inputs" ]]; then
        err "'${RC_CLI_PATH}/data/model_score_inputs': data not found"
        exit 1
      elif [[ ! -d "${RC_CLI_PATH}/data/model_score_timings" ]]; then
        err "'${RC_CLI_PATH}/data/model_score_timings': data not found"
        exit 1
      elif [[ ! -f "${model_build_time}" ]]; then
        err "'${model_build_time}': file not found"
        exit 1
      elif [[ ! -f "${model_apply_time}" ]]; then
        err "'${model_apply_time}': file not found"
        exit 1
      fi
      cmd="model-score"
      make_logs ${cmd}

      if [[ -z $2 ]]; then
        image_name=${app_name}
        image_type="App"
        build_image ${cmd} ${app_name}
      else
        check_snapshot $2
        image_name=$(get_snapshot $2)
        image_type="Snapshot"
        load_snapshot ${image_name}
      fi

      if ! is_image_built ${RC_SCORING_IMAGE}; then
        build_image ${cmd} ${RC_SCORING_IMAGE} ${RC_CLI_PATH}/scoring
      fi
      run_scoring_image ${cmd} ${image_type} ${image_name} ${src_mnt}
      ;;

    model-debug | debug | md)
      # Enable an interactive shell at runtime to debug the app container.
      cmd="model-debug"
      make_logs ${cmd}
      basic_checks
      if [[ -z $2 ]]; then
        image_name=${app_name}
        build_image ${cmd} ${app_name}
      else
        check_snapshot $2
        image_name=$(get_snapshot $2)
        load_snapshot ${image_name}
      fi
      # Find all available shells in container and choose bash if available
      valid_sh=$(docker run --rm --entrypoint="" ${image_name}:${RC_IMAGE_TAG} cat /etc/shells)
      [[ -n $(echo ${valid_sh} | grep "/bin/bash") ]] \
        && app_sh="/bin/bash" || app_sh="/bin/sh"
      printf "Debug mode:\n"
      printf "  - the default shell is ${app_sh}\n"
      printf "  - find all valid login shells: cat /etc/shells\n"
      printf "  - switch to a preferred shell if available, e.g. /bin/zsh\n"
      printf "  - $(tput bold)no '*.sh' script has been run yet$(tput sgr0)\n"
      printf "  - use the 'exit' command to exit the current shell\n"
      printf "\nEnabling an interactive shell with the snapshot container...\n"
      src_mnt=$(get_data_context_abs $2)
      docker run --rm --entrypoint="" --user root \
        --volume "${src_mnt}/setup_inputs:${APP_DEST_MNT}/setup_inputs:ro" \
        --volume "${src_mnt}/setup_outputs:${APP_DEST_MNT}/setup_outputs" \
        --volume "${src_mnt}/evaluate_inputs:${APP_DEST_MNT}/evaluate_inputs:ro" \
        --volume "${src_mnt}/evaluate_outputs:${APP_DEST_MNT}/evaluate_outputs" \
        --interactive --tty ${image_name}:${RC_IMAGE_TAG} ${app_sh}
      ;;

    purge) # Remove all the logs, images and snapshots created by 'rc-cli'.
      if [[ $# -gt 1 ]]; then
        err "too many arguments"
        exit 1
      fi
      # Prompt confirmation to delete user
      printf "WARNING! purge: This will remove all logs, Docker images and snapshots created by ${RC_CLI_SHORT_NAME}\n"
      read -r -p "Are you sure you want to continue? [y/N] " input
      case ${input} in
        [yY][eE][sS] | [yY])
          printf "Removing logs... "
          rm -rf "logs/"
          printf "done\n"
          printf "Removing images... "
          rc_images=$(docker images --all --filter reference="*:${RC_IMAGE_TAG}" --quiet)
          if [[ ${rc_images} ]]; then
            docker rmi --force ${rc_images} &> /dev/null
          fi
          printf "done\n"

          printf "Removing snapshots... "
          rm -rf snapshots/*/ # Remove only directories
          printf "done\n"
          printf "Finished!\n"
          ;;
        [nN][oO] | [nN] | "")
          printf "$1 was canceled by the user\n"
          ;;
        *)
          err "invalid input: The $1 was canceled"
          exit 1
          ;;
      esac
      ;;

    reset) # Flush the output data in the directories
      data_path=$(get_data_context $2)
      reset_data_prompt $1 ${data_path}
      ;;

    update) # Run maintenance commands after breaking changes on the framework.
      printf "${CHARS_LINE}\n"
      printf "Checking Installation\n"
      source "${RC_CLI_PATH}/DATA_URLS"
      bash <(curl -s "https://raw.githubusercontent.com/MIT-CAVE/rc-cli/main/install.sh")  "$SCORING_DATA_URL" "$DATA_URL"
      printf "\n${CHARS_LINE}\n"
      printf "Running other update maintenance tasks\n"
      check_docker
      build_image $1 ${RC_TEST_IMAGE} ${RC_CLI_PATH}
      build_image $1 ${RC_SCORING_IMAGE} ${RC_CLI_PATH}/scoring
      docker save ${RC_SCORING_IMAGE}:${RC_IMAGE_TAG} | gzip > "${RC_CLI_PATH}/scoring/${RC_SCORING_IMAGE}.tar.gz"

      printf "Finished!\n"
      ;;

    uninstall)
      if [[ $# -gt 1 ]]; then
        err "too many arguments"
        exit 1
      fi
      printf "${CHARS_LINE}\n"
      # Prompt confirmation to delete
      printf "WARNING! uninstall: This will remove: \
              \n- ${RC_CLI_SHORT_NAME} (${RC_CLI_VERSION}) \
              \n- All associated docker images.\n"
      read -r -p "Are you sure you want to continue? [y/N] " input
      case ${input} in
        [yY][eE][sS] | [yY])
          printf "Removing all Docker images..."
          rc_images=$(docker images --all --filter reference="*:${RC_IMAGE_TAG}" --quiet)
          if [[ ${rc_images} ]]; then
            docker rmi --force ${rc_images} &> /dev/null
          fi
          printf "done\n"

          printf "Uninstalling ${RC_CLI_SHORT_NAME} (${RC_CLI_VERSION})\n"
          rm -rf s"${RC_CLI_PATH}"
          printf "Uninstall Complete!\n"
          ;;
        [nN][oO] | [nN] | "")
          printf "$1 was canceled by the user\n"
          ;;
        *)
          err "invalid input: The $1 was canceled"
          exit 1
          ;;
      esac
      ;;

    help | --help) # Display the help
      get_help_template_string
      cat 1>&2 <<EOF
${RC_CLI_LONG_NAME}

General Usage:  rc-cli COMMAND [SNAPSHOT]

Commands:
  debug                     Enable an interactive shell at runtime to debug the current app or snapshot in a Docker container
  evaluate                  Build and run the 'evaluate.sh' script
  help                      Print help information
  new                       Create a new RC app within the current directory
  purge                     Remove all the logs, images and snapshots created by ${RC_CLI_SHORT_NAME}
  reset                     Reset the data directory to the initial state
  save                      Build the snapshot image and save it to the 'snapshots' directory
  setup                     Build and run the 'setup.sh' script
  test                      Run the tests for a snapshot image with the '${RC_TEST_IMAGE}'
  uninstall                 Uninstall the rc-cli and all rc-cli created docker images
  update                    Run maintenance commands after any breaking changes on the ${RC_CLI_SHORT_NAME}
  version                   Display the current version

Usage Examples:
  debug [snapshot-name]
    - Debug your current app
      ${CHARS_LINE}
      rc-cli debug
      ${CHARS_LINE}
    - Debug a snapshot
      ${CHARS_LINE}
      rc-cli debug my-snapshot
      ${CHARS_LINE}

  evaluate(-dev) [snapshot-name]
    - Run the evaluate phase for your current app
      ${CHARS_LINE}
      rc-cli evaluate
      ${CHARS_LINE}
    - Run the evaluate phase for a snapshot
      ${CHARS_LINE}
      rc-cli evaluate my-snapshot
      ${CHARS_LINE}
    - Run the evaluate phase for your current app without rebuilding the docker image
      ${CHARS_LINE}
      rc-cli evaluate-dev
      ${CHARS_LINE}
      - This will not take in snapshot arguments
      - This uses:
        - The current state of your local filesystem at:
          - evaluate.sh
          - src/
        - Everything else is pulled from the previous docker build
          - You can rebuild the docker image using \`rc-cli setup\` or \`rc-cli evaluate\`

  help
    - Get all cli commands
      ${CHARS_LINE}
      rc-cli help
      ${CHARS_LINE}

  new [app-name] [template-name]
    - Currently, the following templates are available:
      - ${RC_HELP_TEMPLATE_STRING}
    - Create a new app with the default template ${RC_CLI_DEFAULT_TEMPLATE}
      ${CHARS_LINE}
      rc-cli new my-app
      ${CHARS_LINE}
    - Create a new app with a specified template
      ${CHARS_LINE}
      rc-cli new my-app ${RC_CLI_DEFAULT_TEMPLATE}
      ${CHARS_LINE}

  purge
    - Purge data, logs and containers created by the ${RC_CLI_SHORT_NAME}
      - rc-cli purge

  reset [snapshot-name]
    - Reset my-app/data to the values that will be used for competition scoring
      ${CHARS_LINE}
      rc-cli reset
      ${CHARS_LINE}
    - Reset my-app/snapshots/my-snapshot/data to the values that will be used for competition scoring
      ${CHARS_LINE}
      rc-cli reset my-snapshot
      ${CHARS_LINE}

  save [snapshot-name]
    - Save the current app as a snapshot with the same name as your app
      ${CHARS_LINE}
      rc-cli save
      ${CHARS_LINE}
    - Save the current app as a snapshot named my-snapshot
      ${CHARS_LINE}
      rc-cli save my-snapshot
      ${CHARS_LINE}

  setup(-dev) [snapshot-name]
    - Run the setup phase for your current app
      ${CHARS_LINE}
      rc-cli setup
      ${CHARS_LINE}
    - Run the setup phase for a saved snapshot
      ${CHARS_LINE}
      rc-cli setup my-snapshot
      ${CHARS_LINE}
    - Run the setup phase for your current app without rebuilding the docker image
      ${CHARS_LINE}
      rc-cli setup-dev
      ${CHARS_LINE}
      - This will not take in snapshot arguments
      - This uses:
        - The current state of your local filesystem at:
          - setup.sh
          - src/
        - Everything else is pulled from the previous docker build
          - You can rebuild the docker image using \`rc-cli setup\` or \`rc-cli evaluate\`


  test [snapshot-name]
    - Test the scoring process on your app
      - NOTE: This resets data, runs setup, runs evaluate, and applies the scoring algorithm
      ${CHARS_LINE}
      rc-cli test
      ${CHARS_LINE}
    - Test the scoring process on a saved snapshot
      - NOTE: This resets data, runs setup, runs evaluate, and applies the scoring algorithm
      ${CHARS_LINE}
      rc-cli test my-snapshot
      ${CHARS_LINE}

  uninstall
    - Uninstall your cli
      ${CHARS_LINE}
      rc-cli uninstall
      ${CHARS_LINE}

  update
    - Update your cli
      ${CHARS_LINE}
      rc-cli update
      ${CHARS_LINE}

  version
    - Show the currently installed cli version
      ${CHARS_LINE}
      rc-cli version
      ${CHARS_LINE}
EOF
      ;;

    version | --version | -v) # Display the current version of the CLI
      printf "${RC_CLI_LONG_NAME} ${RC_CLI_VERSION}\n"
      ;;

    *)
      err "$1: command not found"
      exit 1
      ;;
  esac
}

main "$@"
