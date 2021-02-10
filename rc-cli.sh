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
  printf "$0: $1\n" >&2
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

# Get the current date and time expressed according to ISO 8601
get_timestamp() {
  timestamp=$(date +"%Y-%m-%dT%H:%M:%S%:z")
}

# Check that the CLI is run from a valid app
# directory and returns the base name directory
check_app() {
  if valid_app_dir; then
    app_name=$(basename "$(pwd)")
  else
    err "not a valid app directory"
    exit 1
  fi
  # if ! docker image inspect ${app_name}:rc-cli >/dev/null 2>&1; then
  #   err "${app_name}: app not found"
  #   exit 1
  # fi
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
  get_timestamp
  printf "${CHARS_LINE}\n"
  printf "Build Image [$2]:\n\n"
  printf "Building the '$2' image... "
  docker rmi "$2:rc-cli" >& /dev/null
  docker build --file ${context}/Dockerfile --tag $2:rc-cli ${context} >& \
    "logs/$1/$2-build-${timestamp}.log"
  printf "done\n\n"
}

# Args
# $1: [setup,evaluate]
# $2: app_name
run_app_image() {
  docker_run_opts=${@:3}
  [[ ! -f "solutions/$2.tar.gz" ]] \
    && src_mnt="$(pwd)/data" \
    || src_mnt="$(pwd)/solutions/$2/data"
  dest_mnt="/home/app/data"
  get_timestamp
  printf "${CHARS_LINE}\n"
  printf "Running App [$2] (${1}):\n\n"
  docker run --rm --entrypoint "$1.sh" ${docker_run_opts} \
    --volume "${src_mnt}/$1_inputs:${dest_mnt}/$1_inputs:ro" \
    --volume "${src_mnt}/$1_outputs:${dest_mnt}/$1_outputs" \
    "$2:rc-cli" 2>&1 | tee "logs/$1/$2-${timestamp}.log"
  printf "\n${CHARS_LINE}\n"
}

save_image() {
  printf "${CHARS_LINE}\n"
  printf "Save Image [$1]:\n\n"
  printf "Saving the '$1' image to 'solutions'... "
  solution_path="solutions/$1"
  mkdir -p ${solution_path}
  cp -R data/ "${solution_path}/data"
  docker save "$1:rc-cli" | gzip > "${solution_path}/$1.tar.gz"
  printf "done\n\n"
}

run_test_image() {
  image_file="$2.tar.gz"
  src_mnt="$(pwd)/solutions/$2/data"
  # Retrieve a clean copy of data from the rc-cli sources
  rm -rf "${src_mnt}"
  cp -R "${RC_CLI_PATH}/data" "${src_mnt}"
  get_timestamp
  printf "${CHARS_LINE}\n"
  printf "Preparing Test Image [$2] to Run With [${DOCKER_BUILD_RC_TESTER}]:\n\n"
  docker run --privileged --rm --env IMAGE_FILE=${image_file} \
    --volume "$(pwd)/solutions/$2/${image_file}:/mnt/${image_file}:ro" \
    --volume "${src_mnt}/setup_inputs:/data/setup_inputs:ro" \
    --volume "${src_mnt}/setup_outputs:/data/setup_outputs" \
    --volume "${src_mnt}/evaluate_inputs:/data/evaluate_inputs:ro" \
    --volume "${src_mnt}/evaluate_outputs:/data/evaluate_outputs" \
    "${DOCKER_BUILD_RC_TESTER}:rc-cli" 2>&1 | tee "./logs/$1/$2-run-${timestamp}.log"
}

make_logs() { # Ensure the necessary log file structure for the calling command
  mkdir -p logs/$1
}

# Single main function
main() {
  if [[ $# -lt 1 ]]; then
    err "missing command operand"
    exit 1
  elif [[ $# -gt 2 ]]; then
    err "too many arguments"
    exit 1
  fi

  # Select the command
  case $1 in
    new) # Create a new app based on a template
      # TODO: Retrieve the template option (-t, --template)
      template="rc-python"
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
      err "the templates option is not available yet"
      printf "The 'rc-python' template is set by default\n"
      cp -R "${template_path}" "$2"
      chmod +x $(echo "$2/*.sh")
      printf "Done.\n"
      ;;

    save) # Build the app image and save it to the 'solutions' directory
      make_logs "$@"
      check_app
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
      check_app
      if [[ -n $2 ]]; then
        check_solution $2
      fi
      [[ -z ${solution_name} ]] && image_name=${app_name} || image_name=${solution_name}
      build_image $1 ${image_name}
      [[ $1 == "evaluate" ]] \
        && docker_run_opts="--volume $(pwd)/data/setup_outputs:/home/app/data/setup_outputs:ro"
      run_app_image $1 ${image_name} ${docker_run_opts}
      ;;

    test) # Run the tests with the '${DOCKER_BUILD_RC_TESTER}'
      make_logs "$@"
      check_app
      [[ -n $2 ]] && image_name=$2 || image_name=${app_name}
      check_solution ${image_name} # the app image must have been built first
      # Saving time if the '${DOCKER_BUILD_RC_TESTER}' image exists.
      if ! docker image inspect ${DOCKER_BUILD_RC_TESTER}:rc-cli >/dev/null 2>&1; then
        build_image $1 ${DOCKER_BUILD_RC_TESTER} ${RC_CLI_PATH}
      fi
      run_test_image $1 ${image_name}
      printf "\n${CHARS_LINE}\n"
      ;;

    all) # Build, run and save the app image & validate it with the '${DOCKER_BUILD_RC_TESTER}'
      make_logs "$@"
      check_app
      get_solution_name $2
      [[ -z ${solution_name} ]] && tmp_name=${app_name} || tmp_name=${solution_name}
      printf "${CHARS_LINE}\n"
      printf "Build and Save Image for [${tmp_name}]:\n\n"
      get_image_name ${tmp_name}
      build_image $1 ${image_name}
      save_image ${image_name}
      # Saving time if the '${DOCKER_BUILD_RC_TESTER}' image exists.
      if ! docker image inspect ${DOCKER_BUILD_RC_TESTER}:rc-cli >/dev/null 2>&1; then
        build_image $1 ${DOCKER_BUILD_RC_TESTER} ${RC_CLI_PATH}
      fi
      run_test_image $1 ${image_name}
      printf "${CHARS_LINE}\n"
      ;;

    debug) # Enable an interactive shell at runtime to debug the app container.
      check_app
      [[ -n $2 ]] && image_name=$2 || image_name=${app_name}
      check_solution ${image_name} # the app image must have been built first
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
      src_mnt="$(pwd)/solutions/${image_name}/data"
      dest_mnt="/home/app/data/"
      docker run --rm --entrypoint="" \
        --volume "${src_mnt}/setup_inputs:${dest_mnt}/setup_inputs:ro" \
        --volume "${src_mnt}/setup_outputs:${dest_mnt}/setup_outputs" \
        --volume "${src_mnt}/evaluate_inputs:${dest_mnt}/evaluate_inputs:ro" \
        --volume "${src_mnt}/evaluate_outputs:${dest_mnt}/evaluate_outputs" \
        -it "${image_name}:rc-cli" ${app_sh}
      ;;

    purge) # Remove all the logs, images and solutions created by 'rc-cli'.
      # TODO: Do it by specifying app_name
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
          rm -rf solutions/*.tar.gz
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
      printf "WARNING! This will reset the data directory to a blank state\n"
      read -r -p "Are you sure you want to continue? [y/N] " input
      case ${input} in
        [yY][eE][sS] | [yY])
          printf "Resetting the data... "
          rm -rf data/
          cp -R ${RC_CLI_PATH}/data data
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
      printf "Maintenance tasks will run now\n"
      build_image $1 ${DOCKER_BUILD_RC_TESTER} ${RC_CLI_PATH}
      printf "Finished!\n"
      ;;

    help | --help) # Display the help
      cat 1>&2 <<EOF
${RC_CLI_LONG_NAME}

Usage:  rc-cli COMMAND [SOLUTION]

Commands:
  all                       Build, run and save a solution image and validate it with the '${DOCKER_BUILD_RC_TESTER}'
  debug                     Enable an interactive shell at runtime to debug a solution within a Docker container
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
