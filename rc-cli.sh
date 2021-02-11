#!/bin/bash
#
# A CLI for the Routing Challenge.

# Constants
readonly CHARS_LINE="============================"
readonly RC_CLI_PATH="${HOME}/.rc-cli/"
readonly DOCKER_BUILD_RC_TESTER="rc-test"
readonly RC_CLI_LONG_NAME="Routing Challenge CLI"
readonly RC_CLI_SHORT_NAME="RC CLI"
readonly RC_CLI_VERSION="v0.1.0"
readonly TMP_DIR="/tmp"
readonly DEFAULT_TEMPLATE="rc-python"

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

# Determine if the current directory contains a valid RC app
valid_app_dir() {
  [[
    -f Dockerfile \
 && -f evaluate.sh \
 && -f setup.sh \
 && -d solutions \
 && -d data/evaluate_inputs \
 && -d data/evaluate_outputs \
 && -d data/setup_inputs \
 && -d data/setup_outputs
 ]]
}

# Check if the Docker daemon is running.
check_docker() {
  if ! docker ps >& /dev/null; then
    err "cannot connect to the Docker daemon. Is the Docker daemon running?"
    exit 1
  fi
}

# Get the current date and time expressed according to ISO 8601
timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%:z"
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

# Run basic checks on requirements for some commands
basic_checks() {
  check_app
  check_docker
}

# Strips off any leading directory components
get_solution_name() {
  # Allows easy autocompletion in bash using created folder names
  # EG: my-image/ -> my-image, path/to/my/solution/ -> solution
  solution_name="$(basename ${1:-''})"
}

check_solution() {
  get_solution_name $1
  if [[ ! -f "solutions/${solution_name}/${solution_name}.tar.gz" ]]; then
    err "${solution_name}: solution not found"
    exit 1
  fi
}

# Prompts for an image_name if the solution exists
get_image_name() {
  input=$1
  image_name=$1
  while [[ -f "solutions/${input}.tar.gz" && -n ${input} ]]; do
    # Prompt confirmation to overwrite or rename image
    printf "Save Warning: Solution with name '${image_name}' exists\n"
    read -r -p "Enter a new name or overwrite [${image_name}]: " input
    [[ -n ${input} ]] && image_name=${input}
    printf "\n"
  done
}

build_image() {
  context="${3:-.}" # the third argument is the Docker context
  printf "${CHARS_LINE}\n"
  printf "Build Image [$2]:\n\n"
  printf "Building the '$2' image... "
  docker rmi "$2:rc-cli" >& /dev/null
  docker build --file ${context}/Dockerfile --tag $2:rc-cli ${context} >& \
    "logs/$1/$2-build-$(timestamp).log"
  printf "done\n\n"
}

# Load a previously saved Docker solution image
load_solution() {
  docker rmi "$1:rc-cli" >& /dev/null
  docker load --quiet --input "solutions/$1/$1.tar.gz" >& /dev/null
}

# Get the relative path of the data directory based
# on the existence or not of a SOLUTION argument
get_data_context() {
  [[ -z $1 ]] && printf "data" || printf "solutions/$1/data"
}

# Same than get_data_context but return the absolute path.
get_data_context_abs() {
  printf "$(pwd)/$(get_data_context $1)"
}

# Args
# $1: [setup,evaluate]
# $2: app_name
# $3: src_mnt
run_app_image() {
  docker_run_opts=${@:4}
  dest_mnt="/home/app/data"
  printf "${CHARS_LINE}\n"
  printf "Running ${image_type} [$2] (${1}):\n\n"
  docker run --rm --entrypoint "$1.sh" ${docker_run_opts} \
    --volume $3/$1_inputs:${dest_mnt}/$1_inputs:ro \
    --volume $3/$1_outputs:${dest_mnt}/$1_outputs \
  "$2:rc-cli" 2>&1 | tee "logs/$1/$2-$(timestamp).log"
  printf "\n${CHARS_LINE}\n"
}

save_image() {
  printf "${CHARS_LINE}\n"
  printf "Save Image [$1]:\n\n"
  printf "Saving the '$1' image to 'solutions'... "
  solution_path="solutions/$1"
  mkdir -p ${solution_path}
  cp -R "${RC_CLI_PATH}/data" "${solution_path}/data"
  docker save "$1:rc-cli" | gzip > "${solution_path}/$1.tar.gz"
  printf "done\n\n"
}

run_test_image() {
  image_file="$2.tar.gz"
  data_path=$(get_data_context $3)
  [[ -z $3 ]] \
    && src_mnt_image="${TMP_DIR}/$2.tar.gz" \
    || src_mnt_image="$(pwd)/solutions/$2/${image_file}" \
  # Retrieve a clean copy of data from the rc-cli sources
  rm -rf "${data_path}"
  cp -R "${RC_CLI_PATH}/data" "${data_path}"
  printf "WARNING! The data at '${data_path}' has been reset to the initial state\n\n"
  printf "${CHARS_LINE}\n"
  printf "Preparing Test Image [$2] to Run With [${DOCKER_BUILD_RC_TESTER}]:\n\n"
  src_mnt="$(pwd)/${data_path}"
  docker run --privileged --rm --env IMAGE_FILE=${image_file} \
    --volume "${src_mnt_image}:/mnt/${image_file}:ro" \
    --volume "${src_mnt}/setup_inputs:/data/setup_inputs:ro" \
    --volume "${src_mnt}/setup_outputs:/data/setup_outputs" \
    --volume "${src_mnt}/evaluate_inputs:/data/evaluate_inputs:ro" \
    --volume "${src_mnt}/evaluate_outputs:/data/evaluate_outputs" \
    "${DOCKER_BUILD_RC_TESTER}:rc-cli" 2>&1 | tee "./logs/$1/$2-run-$(timestamp).log"
}

make_logs() { # Ensure the necessary log file structure for the calling command
  mkdir -p logs/$1
}

# Single main function
main() {
  if [[ $# -lt 1 ]]; then
    err "missing command operand"
    exit 1
  elif [[ $# -gt 2 && $1 != "new" ]]; then
    err "too many arguments"
    exit 1
  fi

  # Select the command
  case $1 in
    new) # Create a new app based on a template
      template=${3:-$DEFAULT_TEMPLATE}
      template_path="${RC_CLI_PATH}/templates/${template}"
      if [[ $# -lt 2 ]]; then
        err "missing app operand"
        exit 1
      elif [[ -d "$2" ]]; then
        err "cannot create app '$2': Already exists in the current directory"
        exit 1
      elif [[ ! -d "${template_path}" ]]; then
        err "${template}: template not found"
        exit 1
      fi
      cp -R "${template_path}" "$2"
      cp "${RC_CLI_PATH}/templates/README.md" "$2"
      chmod +x $(echo "$2/*.sh")
      [[ -z $3 ]] && optional="by default "
      printf "the '${template}' template has been created ${optional}at '$(pwd)/$2'\n"
      ;;

    save) # Build the app image and save it to the 'solutions' directory
      make_logs "$@"
      basic_checks
      get_solution_name $2
      [[ -z ${solution_name} ]] && tmp_name=${app_name} || tmp_name=${solution_name}
      printf "${CHARS_LINE}\n"
      printf "Save Precheck for App [${tmp_name}]:\n\n"
      get_image_name ${tmp_name}
      printf "Save Precheck Complete\n\n"
      build_image $1 ${image_name}
      save_image ${image_name}
      printf "${CHARS_LINE}\n"
      ;;

    setup | evaluate) # Build and run the '[setup,evaluate].sh' script
      make_logs "$@"
      basic_checks
      if [[ -z $2 ]]; then
        image_name=${app_name}
        build_image $1 ${app_name}
        image_type="App"
      else
        check_solution $2
        image_name=${solution_name}
        load_solution ${image_name}
        image_type="Solution"
      fi
      src_mnt=$(get_data_context_abs $2)
      [[ $1 == "evaluate" ]] \
        && docker_run_opts="--volume ${src_mnt}/setup_outputs:/home/app/data/setup_outputs:ro"
      run_app_image $1 ${image_name} ${src_mnt} ${docker_run_opts}
      ;;

    test) # Run the tests with the '${DOCKER_BUILD_RC_TESTER}'
      make_logs "$@"
      basic_checks
      if [[ -z $2 ]]; then
        image_name=${app_name}
        build_image $1 ${app_name}
        docker save "${app_name}:rc-cli" | gzip > "${TMP_DIR}/${app_name}.tar.gz"
      else
        check_solution $2
        image_name=${solution_name}
        load_solution ${image_name}
      fi
      # Saving time if the '${DOCKER_BUILD_RC_TESTER}' image exists.
      if ! docker image inspect ${DOCKER_BUILD_RC_TESTER}:rc-cli >/dev/null 2>&1; then
        build_image $1 ${DOCKER_BUILD_RC_TESTER} ${RC_CLI_PATH}
      fi
      run_test_image $1 ${image_name} $2 # FIXME: This is ugly - figure out data_path here
      printf "\n${CHARS_LINE}\n"
      ;;

    debug) # Enable an interactive shell at runtime to debug the app container.
      make_logs "$@"
      basic_checks
      if [[ -z $2 ]]; then
        image_name=${app_name}
        build_image $1 ${app_name}
      else
        check_solution $2
        image_name=${solution_name}
        load_solution ${image_name}
      fi
      # Find all available shells in container and choose bash if available
      valid_sh=$(docker run --rm --entrypoint="" "${image_name}:rc-cli" cat /etc/shells)
      [[ -n $(echo ${valid_sh} | grep "/bin/bash") ]] \
        && app_sh="/bin/bash" || app_sh="/bin/sh"
      printf "Debug mode:\n"
      printf "  - the default shell is ${app_sh}\n"
      printf "  - find all valid login shells: cat /etc/shells\n"
      printf "  - switch to a preferred shell if available, e.g. /bin/zsh\n"
      printf "  - $(tput bold)no '*.sh' script has been run yet$(tput sgr0)\n"
      printf "  - use the 'exit' command to exit the current shell\n"
      printf "\nEnabling an interactive shell with the solution container...\n"
      src_mnt=$(get_data_context_abs $2)
      dest_mnt="/home/app/data/"
      docker run --rm --entrypoint="" \
        --volume "${src_mnt}/setup_inputs:${dest_mnt}/setup_inputs:ro" \
        --volume "${src_mnt}/setup_outputs:${dest_mnt}/setup_outputs" \
        --volume "${src_mnt}/evaluate_inputs:${dest_mnt}/evaluate_inputs:ro" \
        --volume "${src_mnt}/evaluate_outputs:${dest_mnt}/evaluate_outputs" \
        -it "${image_name}:rc-cli" ${app_sh}
      ;;

    purge) # Remove all the logs, images and solutions created by 'rc-cli'.
      if [[ $# -gt 1 ]]; then
        err "too many arguments"
        exit 1
      fi
      # Prompt confirmation to delete user
      printf "WARNING! This will remove all logs, Docker images and solutions created by ${RC_CLI_SHORT_NAME}\n"
      read -r -p "Are you sure you want to continue? [y/N] " input
      case ${input} in
        [yY][eE][sS] | [yY])
          printf "Removing logs... "
          rm -rf "logs/"
          printf "done\n"
          printf "Removing images... \n"
          rc_images=$(docker images --all --filter reference="*:rc-cli" --quiet)
          if [[ ${rc_images} ]]; then
            docker rmi --force ${rc_images} >& /dev/null >&2
          fi
          printf "done\n"

          printf "Removing solutions... "
          rm -rf solutions/*/ # Remove only directories
          printf "done\n"
          printf "Finished!\n"
          ;;
        [nN][oO] | [nN] | "")
          err "purge was canceled by the user"
          ;;
        *)
          err "invalid input: The purge was canceled"
          exit 1
          ;;
      esac
      ;;

    reset) # Flush the output data in the directories
      data_path=$(get_data_context $2)
      printf "WARNING! This will reset the data directory at '${data_path}' to a blank state\n"
      read -r -p "Are you sure you want to continue? [y/N] " input
      case ${input} in
        [yY][eE][sS] | [yY])
          printf "Resetting the data... "
          rm -rf "${data_path}"
          cp -R "${RC_CLI_PATH}/data" "${data_path}"
          printf "done\n"
          printf "Finished!\n"
          ;;
        [nN][oO] | [nN] | "")
          err "$1 was canceled by the user"
          ;;
        *)
          err "invalid input: The $1 was canceled"
          exit 1
          ;;
      esac
      ;;

    update) # Run maintenance commands after breaking changes on the framework.
      make_logs "$@"
      printf "${CHARS_LINE}\n"
      printf "Checking Installation\n"
      $RC_CLI_PATH/install.sh
      printf "\n${CHARS_LINE}\n"
      printf "Running other update maintenance tasks\n"
      check_docker
      build_image $1 ${DOCKER_BUILD_RC_TESTER} ${RC_CLI_PATH}
      printf "Finished!\n"
      ;;

    help | --help) # Display the help
      TEMPLATES="$(ls -d $RC_CLI_PATH/templates/*/ | awk -F'/' ' {print $(NF-1)} ' | tr '\n' ',' | sed 's/.$//' | sed 's/,/\n      - /g')"
      cat 1>&2 <<EOF
${RC_CLI_LONG_NAME}

General Usage:  rc-cli COMMAND [SOLUTION]

Commands:
  debug                     Enable an interactive shell at runtime to debug the current app or solution in a Docker container
  evaluate                  Build and run the 'evaluate.sh' script
  help                      Print help information
  new                       Create a new RC app within the current directory
  purge                     Remove all the logs, images and solutions created by ${RC_CLI_SHORT_NAME}
  reset                     Reset the data directory to the initial state
  save                      Build the solution image and save it to the 'solutions' directory
  setup                     Build and run the 'setup.sh' script
  test                      Run the tests for a solution image with the '${DOCKER_BUILD_RC_TESTER}'
  update                    Run maintenance commands after any breaking changes on the ${RC_CLI_SHORT_NAME}
  version                   Display the current version

Usage Examples:
  debug [solution-name]
    - Debug your current app
      ${CHARS_LINE}
      rc-cli debug
      ${CHARS_LINE}
    - Debug a saved solution
      ${CHARS_LINE}
      rc-cli debug my-solution
      ${CHARS_LINE}

  evaluate [solution-name]
    - Evaluate your current app
      ${CHARS_LINE}
      rc-cli evaluate
      ${CHARS_LINE}
    - Evaluate a saved solution
      ${CHARS_LINE}
      rc-cli evaluate my-solution
      ${CHARS_LINE}

  help
    - Get all cli commands
      ${CHARS_LINE}
      rc-cli help
      ${CHARS_LINE}

  new [app-name] [template-name]
    - Currently, the following templates are available:
      - ${TEMPLATES}
    - Create a new app with the default template ${DEFAULT_TEMPLATE}
      ${CHARS_LINE}
      rc-cli new my-app
      ${CHARS_LINE}
    - Create a new app with a specified template
      ${CHARS_LINE}
      rc-cli new my-app ${DEFAULT_TEMPLATE}
      ${CHARS_LINE}

  purge
    - Purge data, logs and containers created by the ${RC_CLI_SHORT_NAME}
      - rc-cli purge

  reset [solution-name]
    - Reset my-app/data to the values that will be used for competition scoring
      ${CHARS_LINE}
      rc-cli reset
      ${CHARS_LINE}
    - Reset my-app/solutions/my-solution/data to the values that will be used for competition scoring
      ${CHARS_LINE}
      rc-cli reset my-solution
      ${CHARS_LINE}

  save [solution-name]
    - Save the current app as a solution with the same name as your app
      ${CHARS_LINE}
      rc-cli save
      ${CHARS_LINE}
    - Save the current app as a solution named my-solution
      ${CHARS_LINE}
      rc-cli save my-solution
      ${CHARS_LINE}

  setup [solution-name]
    - Run the setup phase for your current app
      ${CHARS_LINE}
      rc-cli setup
      ${CHARS_LINE}
    - Run the setup phase for a saved solution
      ${CHARS_LINE}
      rc-cli setup my-solution
      ${CHARS_LINE}

  test [solution-name]
    - Test the scoring process on your app
      - NOTE: This resets data, runs setup, runs evaluate, and applies the scoring algorithm
      ${CHARS_LINE}
      rc-cli test
      ${CHARS_LINE}
    - Test the scoring process on a saved solution
      - NOTE: This resets data, runs setup, runs evaluate, and applies the scoring algorithm
      ${CHARS_LINE}
      rc-cli test my-solution
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