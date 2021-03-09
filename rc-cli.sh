#!/bin/bash
#
# A CLI for the Routing Challenge.

# TODO(luisvasq): Set -u globally and fix all unbound variables

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
readonly TMP_DIR="/tmp"

readonly RC_CONFIGURE_APP_NAME="configure_app"
readonly NO_LOGS="no_logs"

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
  echo $1 | sed s/-/_/
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

get_app_name() {
  printf "$(basename "$(pwd)")"
}

# Check that the CLI is run from a valid app directory.
check_app() {
  if ! valid_app_dir; then
    err "Error: You are not in a valid app directory. Make sure to cd into an app directory that you bootstrapped with the rc-cli."
    exit 1
  fi
}

# Foolproof basic setup to minimize user-side errors
foolproof_setup() {
  local scripts
  scripts="$(ls *.sh) $(find src/ -type f -name "*.sh")"
  for sh_file in ${scripts}; do
    # Force chmod to 755
    chmod +x ${sh_file}
    # Force line endings to LF
    awk 'BEGIN{RS="^$";ORS="";getline;gsub("\r","");print>ARGV[1]}' ${sh_file}
  done
}

# Run basic checks on requirements for some commands.
basic_checks() {
  check_app
  check_docker
  foolproof_setup
}

get_templates() {
  printf "$(ls -d ${RC_CLI_PATH}/templates/*/ | awk -F'/' ' {print $(NF-1)} ')"
}

get_new_template_string() {
  printf "$(get_templates)" | sed 's/\([^\n]*\)/- \1/'
}

get_help_template_string() {
  printf "$(get_templates)" | sed 's/\([^\n]*\)/      - \1/'
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
}

# Prompts for a 'snapshot' name if the given snapshot exists
image_name_prompt() {
  local src_cmd=$1
  local snapshot=$2

  local input=${snapshot}
  while [[ -f "snapshots/${input}/${input}.tar.gz" && -n ${input} ]]; do
    # Prompt confirmation to overwrite or rename image
    printf "WARNING! ${src_cmd}: Snapshot with name '${snapshot}' exists\n" >&2
    read -r -p "Enter a new name or overwrite [${snapshot}]: " input
    [[ -n ${input} ]] && snapshot=${input}
    printf "\n" >&2
  done
  printf ${snapshot}
}

select_template() {
  local template=$1

  local rc_templates
  rc_templates="$(get_templates)"
  while ! printf "${rc_templates}" | grep -w -q "${template}"; do
    # Prompt confirmation to select proper template
    if [[ -z ${template} ]]; then
      printf "WARNING! new: A template was not provided:\n" >&2
    else
      printf "WARNING! new: The supplied template (${template}) does not exist.\n" >&2
    fi
    printf "The following are valid templates:\n$(get_new_template_string)\n" >&2
    template="${RC_CLI_DEFAULT_TEMPLATE}"
    read -r -p "Enter your selection [${template}]: " input
    [[ -n ${input} ]] && template=${input}
    printf "\n" >&2
  done
  printf ${template}
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
configure_image() {
  local src_cmd=$1
  local image_name=$2
  local context="${3:-.}"
  local build_opts=${@:4} # FIXME

  local f_name
  local out_file
  f_name="$(kebab_to_snake ${src_cmd})"
  if [[ ! $f_name = $NO_LOGS ]]; then
    make_logs $f_name
  fi
  printf "${CHARS_LINE}\n"
  printf "Configure Image [${image_name}]:\n\n"
  printf "Configuring the '${image_name}' image... "
  docker rmi ${image_name}:${RC_IMAGE_TAG} &> /dev/null
  [[ -d "logs/${f_name}" ]] \
    && out_file="logs/${f_name}/${image_name}_configure_$(timestamp).log" \
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

build_if_missing() { # Build the image if it is missing under the model configure terminology
  if ! is_image_built ${1}; then
    printf "${CHARS_LINE}\n"
    printf "No prebuilt image exists yet. Configuring Image with 'model-configure'\n\n"
    configure_image ${RC_CONFIGURE_APP_NAME} ${1}
  fi
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
  printf "WARNING! ${src_cmd}: This will reset the data directory at '${data_path}' to the initial data state\n"
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
  local entrypoint
  local cmd
  f_name="$(kebab_to_snake ${src_cmd})"
  local script="${f_name}.sh"
  if [[ ${image_type} == "Snapshot" ]]; then
    entrypoint="--entrypoint ${script}"
    cmd=""
  else
    entrypoint=""
    cmd="${script}"
    run_opts="${run_opts} --volume $(pwd)/src:/home/app/src --volume $(pwd)/${script}:/home/app/${script}"
  fi

  printf "${CHARS_LINE}\n"
  printf "Running ${image_type} [${image_name}] (${src_cmd}):\n\n"
  start_time=$(date +%s)
  { error=$(docker run --rm ${entrypoint} ${run_opts} \
    --volume ${src_mnt}/${f_name}_inputs:${APP_DEST_MNT}/${f_name}_inputs:ro \
    --volume ${src_mnt}/${f_name}_outputs:${APP_DEST_MNT}/${f_name}_outputs \
    ${image_name}:${RC_IMAGE_TAG} ${cmd} 2>&1 >&3 3>&-); } 3>&1; echo ${error} \
    | tee "logs/${f_name}/${image_name}_$(timestamp).log"
  secs=$(($(date +%s) - start_time))
  print_stdout_stats "${secs}" "${error}" \
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
  local image_file="${image_name}.tar.gz"
  local scoring_image="${RC_SCORING_IMAGE}.tar.gz"
  src_mnt="$(pwd)/${data_path}"

  # Check if the 'snapshot' argument was not specified, i.e.
  # "get_data_context $2" in 'production-test' returned 'data'.
  [[ ${data_path} == 'data' ]] \
    && src_mnt_image="${TMP_DIR}/${image_file}" \
    || src_mnt_image="$(pwd)/snapshots/${image_name}/${image_file}"
  printf "${src_cmd}: The data at '${data_path}' has been reset to the initial state\n\n"
  printf "${CHARS_LINE}\n"
  printf "Preparing Image [${image_name}] to Run With [${RC_TEST_IMAGE}]:\n\n"

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
  local app_name=$2
  local src_mnt=$3

  printf "${CHARS_LINE}\n"
  printf "Running the Scoring Image [${RC_SCORING_IMAGE}]:\n\n"
  docker run --rm \
    --volume "${src_mnt}/model_apply_inputs:${APP_DEST_MNT}/model_apply_inputs:ro" \
    --volume "${src_mnt}/model_apply_outputs:${APP_DEST_MNT}/model_apply_outputs:ro" \
    --volume "${src_mnt}/model_score_inputs:${APP_DEST_MNT}/model_score_inputs:ro" \
    --volume "${src_mnt}/model_score_timings:${APP_DEST_MNT}/model_score_timings:ro" \
    --volume "${src_mnt}/model_score_outputs:${APP_DEST_MNT}/model_score_outputs" \
    ${RC_SCORING_IMAGE}:${RC_IMAGE_TAG} 2>&1 \
    | tee "logs/$(kebab_to_snake ${src_cmd})/${app_name}_$(timestamp).log"
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
    new-app | new | app | na)
      # Create a new app based on a template
      if [[ $# -lt 2 ]]; then
        err "Missing arguments. Try using:\nrc-cli help"
        exit 1
      elif [[ -d "$2" ]]; then
        err "Cannot create app '$2': This folder already exists in the current directory"
        exit 1
      fi

      template=$(select_template ${3:-"None Provided"})
      template_path="${RC_CLI_PATH}/templates/${template}"
      cp -R "${template_path}" "$2"
      cp "${RC_CLI_PATH}/templates/README.md" "$2"
      cp "${RC_CLI_PATH}/templates/custom_dev_stack.md" "$2"
      cp -R "${RC_CLI_PATH}/data" "$2"
      chmod +x $(echo "$2/*.sh")
      [[ -z $3 ]] && optional="by default "
      printf "the '${template}' template has been created ${optional}at '$(pwd)/$2'\n"
      ;;

    save-snapshot | save | snapshot | ss)
      # Build the app image and save it to the 'snapshots' directory
      cmd="save-snapshot"
      make_logs ${cmd}
      basic_checks
      snapshot="$(basename ${2:-''})"
      [[ -z ${snapshot} ]] && tmp_name=$(get_app_name) || tmp_name=${snapshot}
      printf "${CHARS_LINE}\n"
      printf "Save Precheck for App [${tmp_name}]:\n\n"
      image_name=$(image_name_prompt ${cmd} ${tmp_name})
      printf "Save Precheck Complete\n\n"
      configure_image ${RC_CONFIGURE_APP_NAME} ${image_name}
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
        local app_name
        app_name=$(get_app_name)
        build_if_missing "${app_name}"
        image_name="${app_name}"
        image_type="App"
        src_mnt="$(pwd)/data"
      else
        check_snapshot $2
        image_name=$(get_snapshot $2)
        load_snapshot ${image_name}
        image_type="Snapshot"
        src_mnt=$(get_data_context_abs $2)
      fi
      [[ ${cmd} == "model-apply" ]] \
        && run_opts="--volume ${src_mnt}/model_build_outputs:${APP_DEST_MNT}/model_build_outputs:ro"
      run_app_image ${cmd} ${image_type} ${image_name} ${src_mnt} ${run_opts}
      ;;

    configure-app | configure | ca)
      # Rebuild a Docker image for the current app
      if [[ $# -gt 1 ]]; then
        err "Too many arguments"
        exit 1
      fi
      cmd="configure-app"
      basic_checks
      configure_image ${RC_CONFIGURE_APP_NAME} "$(get_app_name)"
      printf "${CHARS_LINE}\n"
      ;;

    production-test | production | test | pt)
      # Run the tests with the '${RC_TEST_IMAGE}'
      basic_checks
      [[ -n $2 ]] && check_snapshot $2 # Sanity check

      cmd="production-test"
      data_path=$(get_data_context $2)
      reset_data_prompt ${cmd} ${data_path}
      printf '\n' # Improve formatting

      make_logs ${cmd}

      if [[ -z $2 ]]; then
        image_name=$(get_app_name)
        configure_image ${RC_CONFIGURE_APP_NAME} ${image_name}
        docker save ${image_name}:${RC_IMAGE_TAG} | gzip > "${TMP_DIR}/${image_name}.tar.gz"
      else
        image_name=$(get_snapshot $2)
        load_snapshot ${image_name}
      fi

      # Saving time if some images exist.
      if ! is_image_built ${RC_TEST_IMAGE}; then
        configure_image ${NO_LOGS} ${RC_TEST_IMAGE} ${RC_CLI_PATH}
      fi
      if ! is_image_built ${RC_SCORING_IMAGE}; then
        configure_image ${NO_LOGS} ${RC_SCORING_IMAGE} ${RC_CLI_PATH}/scoring
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
      # Validate that build and apply have happend by checking for timings.
      src_mnt=$(get_data_context_abs $2)
      model_build_time="${src_mnt}/model_score_timings/model_build_time.json"
      model_apply_time="${src_mnt}/model_score_timings/model_apply_time.json"
      if [[ ! -f "${model_build_time}" ]]; then
        err "'${model_build_time}': file not found"
        exit 1
      elif [[ ! -f "${model_apply_time}" ]]; then
        err "'${model_apply_time}': file not found"
        exit 1
      fi
      cmd="model-score"
      make_logs ${cmd}

      if ! is_image_built ${RC_SCORING_IMAGE}; then
        configure_image ${NO_LOGS} ${RC_SCORING_IMAGE} ${RC_CLI_PATH}/scoring
      fi
      run_scoring_image ${cmd} $(get_app_name) ${src_mnt}
      ;;

    model-debug | debug | md)
      # Enable an interactive shell at runtime to debug the app container.
      cmd="model-debug"
      make_logs ${cmd}
      basic_checks
      if [[ -z $2 ]]; then
        local app_name
        app_name=$(get_app_name)
        build_if_missing "${app_name}"
        image_name="${app_name}"
        run_opts="--volume $(pwd)/src:/home/app/src"
        for f in $(pwd)/*.sh; do
          run_opts="$run_opts --volume $(pwd)/$(basename ${f}):/home/app/$(basename ${f})"
        done
      else
        check_snapshot $2
        image_name=$(get_snapshot $2)
        load_snapshot ${image_name}
        run_opts=""
      fi
      # Find all available shells in container and choose bash if available
      valid_sh=$(docker run --rm --entrypoint="" ${image_name}:${RC_IMAGE_TAG} cat /etc/shells)
      [[ -n $(echo ${valid_sh} | grep "/bin/bash") ]] \
        && app_sh="/bin/bash" || app_sh="/bin/sh"
      printf "${CHARS_LINE}\n"
      printf "Debug mode:\n"
      printf "  - You are in the equivalent of your current app directory inside of a Docker container\n"
      printf "  - You can test your code directly in this environment\n"
      printf "    - EG: try running:\n"
      printf "      ${CHARS_LINE}\n"
      printf "      ./model_build.sh'\n"
      printf "      ${CHARS_LINE}\n"
      printf "  - Use the 'exit' command to exit the current shell\n"
      printf "\nEnabling an interactive shell in the Docker image...\n"
      src_mnt=$(get_data_context_abs $2)
      docker run --rm --entrypoint="" --user root ${run_opts}\
        --volume "${src_mnt}/model_build_inputs:${APP_DEST_MNT}/model_build_inputs:ro" \
        --volume "${src_mnt}/model_build_outputs:${APP_DEST_MNT}/model_build_outputs" \
        --volume "${src_mnt}/model_apply_inputs:${APP_DEST_MNT}/model_apply_inputs:ro" \
        --volume "${src_mnt}/model_apply_outputs:${APP_DEST_MNT}/model_apply_outputs" \
        --interactive --tty ${image_name}:${RC_IMAGE_TAG} ${app_sh}
      printf "${CHARS_LINE}\n"
      ;;

    purge) # Remove all the logs, images and snapshots created by 'rc-cli'.
      if [[ $# -gt 1 ]]; then
        err "too many arguments"
        exit 1
      fi
      # Prompt confirmation to delete user
      printf "${CHARS_LINE}\n"
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
      printf "${CHARS_LINE}\n"
      ;;

    reset-data | reset | rd) # Flush the output data in the directories
      data_path=$(get_data_context $2)
      reset_data_prompt $1 ${data_path}
      ;;

    configure-utils | cu) # Run maintenance commands to configure the utility images during development
      printf "${CHARS_LINE}\n"
      printf "Configuring Utility Images\n"
      check_docker
      configure_image ${NO_LOGS} ${RC_TEST_IMAGE} ${RC_CLI_PATH}
      configure_image ${NO_LOGS} ${RC_SCORING_IMAGE} ${RC_CLI_PATH}/scoring
      docker save ${RC_SCORING_IMAGE}:${RC_IMAGE_TAG} | gzip > "${RC_CLI_PATH}/scoring/${RC_SCORING_IMAGE}.tar.gz"

      printf "${CHARS_LINE}\n"
      ;;

    update) # Run maintenance commands after breaking changes on the framework.
      # Accepts an additional parameter to pass to the install function (useful for --dev installs)
      printf "${CHARS_LINE}\n"
      printf "Checking Installation\n"
      source "${RC_CLI_PATH}/CONFIG"
      bash <(curl -s "https://raw.githubusercontent.com/MIT-CAVE/rc-cli/main/install.sh") \
        "${DATA_URL}" "${INSTALL_PARAM}"
      printf "\n${CHARS_LINE}\n"
      printf "Running other update maintenance tasks\n"
      check_docker
      configure_image ${NO_LOGS} ${RC_TEST_IMAGE} ${RC_CLI_PATH}
      configure_image ${NO_LOGS} ${RC_SCORING_IMAGE} ${RC_CLI_PATH}/scoring
      docker save ${RC_SCORING_IMAGE}:${RC_IMAGE_TAG} | gzip > "${RC_CLI_PATH}/scoring/${RC_SCORING_IMAGE}.tar.gz"

      printf "${CHARS_LINE}\n"
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
              \n- All associated Docker images.\n"
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
      cat 1>&2 <<EOF
${RC_CLI_LONG_NAME}

General Usage:  rc-cli COMMAND [options]

Core Commands:
  configure-app (ca)        Configure your app's Docker image using your local Dockerfile.
                            - This overwrites previous image giving you an updated image.
                            - Every time you update your project root (shell scripts or
                              Dockerfile), you should run model-configure again.
  model-apply (ma)          Execute the model_apply.sh script inside of your app's Docker image.
  model-build (mb)          Execute the model_build.sh script inside of your app's Docker image.
  model-debug (md)          Launch an interactive terminal into your app's Docker image.
  model-score (ms)          Apply the scoring algorithm against your app's current data.
  new-app (na)              Create a new application directory within your current directory.
  production-test (pt)      Run your app phases end to end exactly as it will be run during your
                            official scoring phase.
  reset-data (rd)           Reset the current app data directory to the initial state.
  save-snapshot (ss)        Configure your app's Docker image and save it as a snapshot in
                            the snapshots folder.

Utility Commands:
  help                      Print help information for the ${RC_CLI_SHORT_NAME}.
  purge                     Remove all:
                            - Logs created by ${RC_CLI_SHORT_NAME} in the current app.
                            - Snapshots created by ${RC_CLI_SHORT_NAME} in the current app.
                            - All (global) ${RC_CLI_SHORT_NAME} Docker images.
  uninstall                 Uninstall the ${RC_CLI_SHORT_NAME} and all ${RC_CLI_SHORT_NAME}
                            created docker images.
  update                    Update to the most recent ${RC_CLI_SHORT_NAME}.
  version                   Display the current ${RC_CLI_SHORT_NAME} version.

Usage Examples:

  configure-app
    - Configure your app's current Docker image
      ${CHARS_LINE}
      rc-cli configure-app
      ${CHARS_LINE}

  model-build [snapshot-name]
    - Run the model-build phase for your current app
      ${CHARS_LINE}
      rc-cli model-build
      ${CHARS_LINE}
    - Run the model-build phase for a snapshot
      ${CHARS_LINE}
      rc-cli model-build my-snapshot
      ${CHARS_LINE}

  model-apply [snapshot-name]
    - Run the model-apply phase for your current app (after having run model-build)
      ${CHARS_LINE}
      rc-cli model-apply
      ${CHARS_LINE}
    - Run the model-apply phase for a snapshot (after having run model-build)
      ${CHARS_LINE}
      rc-cli model-apply my-snapshot
      ${CHARS_LINE}

  model-debug [snapshot-name]
    - Debug your current app
      ${CHARS_LINE}
      rc-cli model-debug
      ${CHARS_LINE}
    - Debug a snapshot
      ${CHARS_LINE}
      rc-cli model-debug my-snapshot
      ${CHARS_LINE}

  model-score [snapshot-name]
    - Generate the score for your current app (after having run model-build and model-apply)
      ${CHARS_LINE}
      rc-cli model-score
      ${CHARS_LINE}
    - Generate the score for a snapshot (after having run model-build and model-apply)
      ${CHARS_LINE}
      rc-cli model-score my-snapshot
      ${CHARS_LINE}

  new-app [app-name] [template-name]
    - The following templates are available:
$(get_help_template_string)
    - Create a new app with the default template ${RC_CLI_DEFAULT_TEMPLATE}
      ${CHARS_LINE}
      rc-cli new-app my-app
      ${CHARS_LINE}
    - Create a new app with a specified template
      ${CHARS_LINE}
      rc-cli new-app my-app ${RC_CLI_DEFAULT_TEMPLATE}
      ${CHARS_LINE}

  production-test [snapshot-name]
    - Test the scoring process on your app
      - NOTE: This resets data, runs model-build, runs model-apply, and applies the scoring algorithm
      ${CHARS_LINE}
      rc-cli production-test
      ${CHARS_LINE}
    - Test the scoring process on a saved snapshot
      - NOTE: This resets data, runs model-build, runs model-apply, and applies the scoring algorithm
      ${CHARS_LINE}
      rc-cli production-test my-snapshot
      ${CHARS_LINE}

  reset-data [snapshot-name]
    - Reset my-app/data to the values that will be used for competition scoring
      ${CHARS_LINE}
      rc-cli reset-data
      ${CHARS_LINE}
    - Reset my-app/snapshots/my-snapshot/data to the values that will be used for competition scoring
      ${CHARS_LINE}
      rc-cli reset-data my-snapshot
      ${CHARS_LINE}

  save-snapshot [snapshot-name]
    - Save the current app as a snapshot with the same name as your app
      ${CHARS_LINE}
      rc-cli save
      ${CHARS_LINE}
    - Save the current app as a snapshot named my-snapshot
      ${CHARS_LINE}
      rc-cli save my-snapshot
      ${CHARS_LINE}

  help
    - Get all cli commands
      ${CHARS_LINE}
      rc-cli help
      ${CHARS_LINE}

  purge
    - Purge data, logs and containers created by the ${RC_CLI_SHORT_NAME}
      ${CHARS_LINE}
      rc-cli purge
      ${CHARS_LINE}

  uninstall
    - Uninstall this cli
      ${CHARS_LINE}
      rc-cli uninstall
      ${CHARS_LINE}

  update
    - Update this cli
      ${CHARS_LINE}
      rc-cli update
      ${CHARS_LINE}

  version
    - Show the version of this cli
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
