#!/bin/bash
#
# A CLI for the Routing Challenge.

# TODO(luisvasq): Set -u globally and fix all unbound variables

# Constants
readonly VALID_NAME_PATTERN="^[abcdefghijklmnopqrstuvwxyz0-9_-]+$"
readonly INVALID_NAME_PATTERN_1="^[-_]+.*$"
readonly INVALID_NAME_PATTERN_2="^.*[-_]+$"
readonly INVALID_NAME_PATTERN_3="(-_)+"
readonly INVALID_NAME_PATTERN_4="(_-)+"
readonly RC_CLI_DEFAULT_TEMPLATE="rc_python"
readonly RC_CONFIGURE_APP_NAME="configure_app"
readonly RC_SCORING_IMAGE="rc-scoring"
readonly RC_TEST_IMAGE="rc-test"
readonly NO_LOGS="no_logs"
readonly ROOT_LOGS="root_logs"
# Both constant and environment
declare -xr RC_CLI_PATH="${HOME}/.rc-cli"

# Import libraries
# shellcheck source=lib/config.sh
. ${RC_CLI_PATH}/lib/config.sh
# shellcheck source=lib/excep.sh
. ${RC_CLI_PATH}/lib/excep.sh
# shellcheck source=lib/docker.sh
. ${RC_CLI_PATH}/lib/docker.sh
# shellcheck source=lib/utils.sh
. ${RC_CLI_PATH}/lib/utils.sh

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
 && -d data/model_build_outputs \
 && -d data/model_score_inputs \
 && -d data/model_score_outputs \
 && -d data/model_score_timings
 ]]
}

is_rc_image_built() {
  docker::is_image_built $1:${RC_IMAGE_TAG}
}

get_app_name() {
  printf "$(basename "$(pwd)")"
}

valid_app_name() {
  local app_name=$1
  if [[ ${#app_name} -lt 2 || ${#app_name} -gt 255 ]]; then
    printf "The app name needs to be two to 255 characters"
  elif [[ ! ${app_name} =~ ${VALID_NAME_PATTERN} ]]; then
    printf "The app name can only contain lowercase letters, numbers, hyphens (-), and underscores (_)"
  elif [[ ${app_name} =~ ${INVALID_NAME_PATTERN_1} ]]; then
    printf "The app name cannot start with a hyphen (-) or an underscore (_)"
  elif [[ ${app_name} =~ ${INVALID_NAME_PATTERN_2} ]]; then
    printf "The app name cannot end with a hyphen (-) or an underscore (_)"
  elif [[ ${app_name} =~ ${INVALID_NAME_PATTERN_3} ]]; then
    printf "The app name cannot contain a hyphen (-) followed by an underscore (_)"
  elif [[ ${app_name} =~ ${INVALID_NAME_PATTERN_4} ]]; then
    printf "The app name cannot contain an underscore (_) followed by a hyphen (-)"
  fi
}

# Determine if the given app name complies with Docker repository names.
check_app_name() {
  local app_name_err
  app_name_err=$(valid_app_name $1)
  if [[ -n ${app_name_err} ]]; then
    excep::err "${app_name_err}"
    exit 1
  fi
}

# Check that the CLI is run from a valid app directory.
check_app_dir() {
  if ! valid_app_dir; then
    excep::err "Error: You are not in a valid app directory. Make sure to cd into an app directory that you created with the rc-cli."
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
  check_app_dir
  check_app_name "$(get_app_name)"
  docker::check_status
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
    excep::err "${f_name}: snapshot not found"
    exit 1
  fi
}

# Prompts for a 'snapshot' name if the given snapshot exists
image_name_prompt() {
  local src_cmd=$1
  local snapshot=$2

  local app_name_err
  local input=${snapshot}
  app_name_err=$(valid_app_name ${input})
  while [[ -n ${app_name_err} || -f "snapshots/${input}/${input}.tar.gz" ]]; do
    if [[ -z ${app_name_err} ]]; then
      # Prompt confirmation to overwrite or rename image
      printf "WARNING! ${src_cmd}: Snapshot with name '${snapshot}' exists\n" >&2
      read -r -p "Enter a new name or overwrite [${snapshot}]: " input
    else
      printf "WARNING! ${src_cmd}: ${app_name_err}\n" >&2
      read -r -p "Enter a new name: " input
    fi
    app_name_err=$(valid_app_name ${input})
    [[ -z ${app_name_err} && -n ${input} ]] && snapshot=${input}
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

save_scoring_image() {
  printf "Saving the '${RC_SCORING_IMAGE}' image... "
  docker save ${RC_SCORING_IMAGE}:${RC_IMAGE_TAG} | gzip > "${RC_CLI_PATH}/scoring/${RC_SCORING_IMAGE}.tar.gz"
  printf "done\n\n"
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
  f_name="$(utils::kebab_to_snake ${src_cmd})"
  if [[ ${f_name} == "${ROOT_LOGS}" ]]; then
    make_root_logs
    [[ -d "${RC_CLI_PATH}/logs/" ]] \
    && out_file="${RC_CLI_PATH}/logs/${image_name}_configure_$(utils::timestamp).log" \
    || out_file="/dev/null"
  elif [[ ${f_name} != "${NO_LOGS}" ]]; then
    make_logs ${f_name}
    [[ -d "logs/${f_name}" ]] \
    && out_file="logs/${f_name}/${image_name}_configure_$(utils::timestamp).log" \
    || out_file="/dev/null"
  else
    out_file="/dev/null"
  fi
  printf "${CHARS_LINE}\n"
  printf "Configure Image [${image_name}]:\n\n"
  printf "Configuring the '${image_name}' image... "
  docker rmi ${image_name}:${RC_IMAGE_TAG} &> /dev/null
  docker build --file ${context}/Dockerfile --tag ${image_name}:${RC_IMAGE_TAG} \
    ${build_opts} ${context} &> ${out_file}
  printf "done\n\n"
}

# Load the Docker image for a given snapshot name.
load_snapshot() {
  local snapshot=$1
  local old_image_tag
  docker rmi ${snapshot}:${RC_IMAGE_TAG} &> /dev/null
  load_stdout=$(docker load --quiet --input "snapshots/${snapshot}/${snapshot}.tar.gz" 2> /dev/null)
  old_image_tag="${load_stdout:14}"
  # Force the image tag to be that of the tar archive filename.
  if [[ "${old_image_tag}" != "${snapshot}:${RC_IMAGE_TAG}" ]]; then
    docker tag ${old_image_tag} ${snapshot}:${RC_IMAGE_TAG}
    docker rmi ${old_image_tag} &> /dev/null
  fi
}

# Get the relative path of the data directory based
# on the existence or not of a given 'snapshot' arg.
get_data_context() {
  local snapshot=$1
  [[ -z ${snapshot} ]] && printf "data" || printf "snapshots/${snapshot}/data"
}

# Same than 'get_data_context' but return the absolute path.
get_data_context_abs() {
  printf "$(pwd)/$(get_data_context $1)"
}

# Save a Docker image to the 'snapshots' directory.
save_image() {
  local image_name=$1

  printf "${CHARS_LINE}\n"
  printf "Save Image [${image_name}]:\n\n"
  printf "Saving the '${image_name}' image to 'snapshots'... "
  snapshot_path="snapshots/${image_name}"
  mkdir -p ${snapshot_path}
  cp -R "${RC_CLI_PATH}/data" "${snapshot_path}/data"
  docker save ${image_name}:${RC_IMAGE_TAG} \
    | gzip > "${snapshot_path}/${image_name}.tar.gz"
  printf "done\n\n"
}

build_if_missing() { # Build the image if it is missing under the model configure terminology
  if ! is_rc_image_built $1; then
    printf "${CHARS_LINE}\n"
    printf "No prebuilt image exists yet. Configuring Image with 'configure-app'\n\n"
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
      exit # Required to prevent subsequent script commands from running
      ;;
    *)
      excep::err "invalid input: The ${src_cmd} was canceled"
      exit 1
      ;;
  esac
}

get_status() {
  [[ -z $1 ]] \
    && printf "success" \
    || printf "failure" # : $(printf $1 | sed s/\"/\"/)" # TODO: handle newlines
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
  printf "Time Elapsed: $(utils::secs_to_iso_8601 ${secs})\n"
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
  f_name="$(utils::kebab_to_snake ${src_cmd})"
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
  local log_file
  log_file="logs/${f_name}/${image_name}_$(utils::timestamp).log"
  # TODO: save to a rc-cli-$(uuidgen) directory
  local stderr_file="${TMP_DIR}/rc_cli_${f_name}_error"

  docker run --rm ${entrypoint} ${run_opts} \
    --volume ${src_mnt}/${f_name}_inputs:${APP_DEST_MNT}/${f_name}_inputs:ro \
    --volume ${src_mnt}/${f_name}_outputs:${APP_DEST_MNT}/${f_name}_outputs \
    ${image_name}:${RC_IMAGE_TAG} ${cmd} 2>${stderr_file} | tee ${log_file}
  error=$(<${stderr_file})
  echo ${error} | tee -a ${log_file}
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
    | tee "logs/$(utils::kebab_to_snake ${src_cmd})/${image_name}_run_$(utils::timestamp).log"
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
    | tee "logs/$(utils::kebab_to_snake ${src_cmd})/${app_name}_$(utils::timestamp).log"
  printf "\n${CHARS_LINE}\n"
}

make_logs() { # Ensure the necessary log file structure for the calling command
  mkdir -p "logs/$(utils::kebab_to_snake $1)"
}

make_root_logs() { # Ensure the necessary log file structure for the calling command
  mkdir -p "${RC_CLI_PATH}/logs/"
}

# Single main function
main() {
  if [[ $# -lt 1 ]]; then
    excep::err "missing command operand"
    exit 1
  elif [[
    $# -gt 2 \
    && $1 != "new-app" \
    && $1 != "new" \
    && $1 != "app" \
    && $1 != 'na' \
  ]]; then
    excep::err "Too many arguments"
    exit 1
  fi

  # Select the command
  case $1 in
    new-app | new | app | na)
      # Create a new app based on a template
      if [[ $# -lt 2 ]]; then
        excep::err "Missing arguments. Try using:\nrc-cli help"
        exit 1
      elif [[ -d "$2" ]]; then
        excep::err "Cannot create app '$2': This folder already exists in the current directory"
        exit 1
      fi
      check_app_name $2

      template=$(select_template ${3:-"None Provided"})
      template_path="${RC_CLI_PATH}/templates/${template}"
      cp -R "${template_path}" "$2"
      cp "${RC_CLI_PATH}/templates/README.md" "$2"
      cp "${RC_CLI_PATH}/templates/custom_dev_stack.md" "$2"
      cp "${RC_CLI_PATH}/templates/data_structures.md" "$2"
      cp -R "${RC_CLI_PATH}/data" "$2"
      chmod +x $(echo "$2/*.sh")
      [[ -z $3 ]] && optional="by default "
      printf "the '${template}' template has been created ${optional}at '$(pwd)/$2'\n"
      ;;

    save-snapshot | save | snapshot | ss)
      # Build the app image and save it to the 'snapshots' directory
      cmd="save-snapshot"
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
        excep::err "Too many arguments"
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
      if ! is_rc_image_built ${RC_TEST_IMAGE}; then
        configure_image ${NO_LOGS} ${RC_TEST_IMAGE} ${RC_CLI_PATH}
      fi
      if ! is_rc_image_built ${RC_SCORING_IMAGE}; then
        configure_image ${NO_LOGS} ${RC_SCORING_IMAGE} ${RC_CLI_PATH}/scoring
      fi
      if [[ ! -f "${RC_CLI_PATH}/scoring/${RC_SCORING_IMAGE}.tar.gz" ]]; then
        save_scoring_image
      fi
      run_test_image ${cmd} ${image_name} ${data_path}
      printf "\n${CHARS_LINE}\n"
      ;;

    model-score | score | ms)
      # Calculate the score for the app or the specified snapshot.
      basic_checks
      [[ -z $2 ]] \
        && image_name=$(get_app_name) \
        ||  image_name=$(get_snapshot $2)
      # Validate that build and apply have happened by checking for timings.
      src_mnt=$(get_data_context_abs $2)
      model_build_time="${src_mnt}/model_score_timings/model_build_time.json"
      model_apply_time="${src_mnt}/model_score_timings/model_apply_time.json"
      if [[ ! -f "${model_build_time}" ]]; then
        excep::err "'${model_build_time}': file not found"
        exit 1
      elif [[ ! -f "${model_apply_time}" ]]; then
        excep::err "'${model_apply_time}': file not found"
        exit 1
      fi
      cmd="model-score"
      make_logs ${cmd}

      if ! is_rc_image_built ${RC_SCORING_IMAGE}; then
        configure_image ${NO_LOGS} ${RC_SCORING_IMAGE} ${RC_CLI_PATH}/scoring
      fi
      run_scoring_image ${cmd} ${image_name} ${src_mnt}
      ;;

    enter-app | model-debug | debug | md | ea)
      # Enable an interactive shell at runtime to debug the app container.
      cmd="enter-app"
      # make_logs ${cmd}
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
      printf "Entering your app:\n"
      printf "  - You are in the equivalent of your current app directory inside of your app's Docker container\n"
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

    purge)
      # Remove all the logs, images and snapshots created by 'rc-cli'.
      if [[ $# -gt 1 ]]; then
        excep::err "Too many arguments"
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
          excep::err "invalid input: The $1 was canceled"
          exit 1
          ;;
      esac
      printf "${CHARS_LINE}\n"
      ;;

    reset-data | reset | rd)
      # Flush the output data in the directories
      data_path=$(get_data_context $2)
      reset_data_prompt $1 ${data_path}
      ;;

    configure-utils | cu) # Run maintenance commands to configure the utility images during development
      printf "${CHARS_LINE}\n"
      printf "Configuring Utility Images\n"
      docker::check_status
      configure_image ${ROOT_LOGS} ${RC_TEST_IMAGE} ${RC_CLI_PATH}
      configure_image ${ROOT_LOGS} ${RC_SCORING_IMAGE} ${RC_CLI_PATH}/scoring
      save_scoring_image

      printf "${CHARS_LINE}\n"
      ;;

    update)
      # Update rc-cli & run maintenance commands after breaking changes on the framework.
      if [[ $# -gt 1 ]]; then
        excep::err "Too many arguments"
        exit 1
      fi
      printf "${CHARS_LINE}\n"
      printf "Checking for updates...\n"
      docker::check_status
      local_rc_cli_ver=$(<${RC_CLI_PATH}/VERSION)
      latest_rc_cli_ver=$(curl -s https://raw.githubusercontent.com/MIT-CAVE/rc-cli/main/VERSION)
      if [[ "${local_rc_cli_ver}" == "${latest_rc_cli_ver}" ]]; then
        printf "\nYou already have the latest version of ${RC_CLI_SHORT_NAME} (${latest_rc_cli_ver}).\n"
        read -r -p "Would you like to reinstall this version? [y/N] " input
      else
        printf "A new version of ${RC_CLI_SHORT_NAME} (${latest_rc_cli_ver}) is available.\n"
        read -r -p "Would you like to update now? [y/N] " input
      fi
      case ${input} in
        [yY][eE][sS] | [yY])
          printf "\nUpdating ${RC_CLI_SHORT_NAME} (${local_rc_cli_ver} -> ${latest_rc_cli_ver})... "
          git -C ${RC_CLI_PATH} reset --hard origin/main > /dev/null
          git -C ${RC_CLI_PATH} checkout main > /dev/null
          git -C ${RC_CLI_PATH} pull > /dev/null
          printf "done\n"

          printf "\n${CHARS_LINE}\n"
          printf "Running other update maintenance tasks\n"
          configure_image ${NO_LOGS} ${RC_TEST_IMAGE} ${RC_CLI_PATH}
          configure_image ${NO_LOGS} ${RC_SCORING_IMAGE} ${RC_CLI_PATH}/scoring
          save_scoring_image

          printf "${CHARS_LINE}\n"
          printf "\n${RC_CLI_SHORT_NAME} was updated successfully.\n"
          ;;
        [nN][oO] | [nN] | "")
          excep::err "Update canceled"
          exit 1
          ;;
        *)
          excep::err "Invalid input: Update canceled."
          exit 1
          ;;
      esac
      ;;

    uninstall)
      if [[ $# -gt 1 ]]; then
        excep::err "Too many arguments"
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
          rm -rf "${RC_CLI_PATH}"
          printf "Uninstall Complete!\n"
          ;;
        [nN][oO] | [nN] | "")
          printf "$1 was canceled by the user\n"
          ;;
        *)
          excep::err "invalid input: The $1 was canceled"
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
                              Dockerfile), you should run configure-app again.
  enter-app (ea)            Launch an interactive terminal into your app's Docker image.
  model-apply (ma)          Execute the model_apply.sh script inside of your app's Docker image.
  model-build (mb)          Execute the model_build.sh script inside of your app's Docker image.
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
  update-data               Update the data provided by Amazon to build and apply your model.
  version                   Display the current ${RC_CLI_SHORT_NAME} version.

Usage Examples:

  configure-app
    - Configure your app's current Docker image
      ${CHARS_LINE}
      rc-cli configure-app
      ${CHARS_LINE}

  enter-app [snapshot-name]
    - Enter your current app's docker image
      ${CHARS_LINE}
      rc-cli enter-app
      ${CHARS_LINE}
    - Enter a snapshot's docker image
      ${CHARS_LINE}
      rc-cli enter-app my-snapshot
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
    - Update your cli to the newest version
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
      excep::err "$1: command not found"
      exit 1
      ;;
  esac
}

main "$@"
