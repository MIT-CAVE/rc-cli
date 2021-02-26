#!/bin/bash
#
# Install the RC CLI on Unix Systems

# Constants
readonly CHARS_LINE="============================"
readonly RC_CLI_PATH="${HOME}/.rc-cli"
readonly RC_CLI_LONG_NAME="Routing Challenge CLI"
readonly RC_CLI_SHORT_NAME="RC CLI"
readonly RC_CLI_COMMAND="rc-cli"
readonly RC_CLI_VERSION="0.1.0"
readonly BIN_DIR="/usr/local/bin"
readonly SSH_CLONE_URL="git@github.com:MIT-CAVE/rc-cli.git"
readonly HTTPS_CLONE_URL="https://github.com/MIT-CAVE/rc-cli.git"
readonly MIN_DOCKER_VERSION="18.09.00"

err() { # Display an error message
  printf "$0: $1\n" >&2
}

check_os() { # Validate that the current OS
  case "$(uname -s)" in
      Linux*)     machine="Linux";;
      Darwin*)    machine="Mac";;
      *)          machine="UNKNOWN"
  esac
  if [ $machine = "UNKNOWN" ]; then
    printf "Error: Unknown operating system.\n"
    printf "Please run this command on one of the following:\n"
    printf "- MacOS\n- Linux\n- Windows (Using Ubuntu 20.04 on Windows Subsystem for Linux 2 - WSL2)"
    exit 1
  fi
}

check_docker() { # Validate docker is installed
  install_docker="\nPlease install version ${MIN_DOCKER_VERSION} or greater. \nFor more information see: 'https://docs.docker.com/get-docker/'"
  if [ "$(docker --version)" = "" ]; then
    err "Docker is not installed. ${install_docker}"
    exit 1
  fi
  CURRENT_DOCKER_VERSION=$(docker --version | sed -e 's/Docker version \(.*\), build.*/\1/')
  if [ ! "$(printf '%s\n' "$MIN_DOCKER_VERSION" "$CURRENT_DOCKER_VERSION" | sort -V | head -n1)" = "$MIN_DOCKER_VERSION" ]
  then
    err "Your current Docker version ($CURRENT_DOCKER_VERSION) is too old. ${install_docker}"
    exit 1
  fi
}

check_git() { # Validate git is installed
  if [ "$(git --version)" = "" ]; then
    err "'git' is not installed. Please install git. \nFor more information see: 'https://git-scm.com'"
    exit 1
  fi
}

check_previous_installation() { # Check to make sure previous installations are removed before continuing
  if [ -d "${RC_CLI_PATH}" ]; then
    LOCAL_CLI_VERSION=$(<${RC_CLI_PATH}/VERSION)
    printf "An existing installation of ${RC_CLI_SHORT_NAME} ($LOCAL_CLI_VERSION) was found \nLocation: ${RC_CLI_PATH}\n"
    printf "You are installing ${RC_CLI_SHORT_NAME} ($RC_CLI_VERSION)\n"
    if [ "$LOCAL_CLI_VERSION" = "$RC_CLI_VERSION" ] ; then
      read -r -p "Would you like to reinstall ${RC_CLI_SHORT_NAME} ($RC_CLI_VERSION)? [y/N] " input
    else
      read -r -p "Would you like to update to ${RC_CLI_SHORT_NAME} ($RC_CLI_VERSION)? [y/N] " input
    fi
    case ${input} in
      [yY][eE][sS] | [yY])
        printf "Removing old installation... "
        rm -rf "${RC_CLI_PATH}"
        printf "done\n"
        ;;
      [nN][oO] | [nN] | "")
        err "Installation canceled"
        exit 1
        ;;
      *)
        err "Invalid input: Installation canceled."
        exit 1
        ;;
    esac
  fi
}

install_new() { # Copy the needed files locally
  printf "Creating application folder at '${RC_CLI_PATH}'..."
  mkdir -p "${RC_CLI_PATH}"
  printf "done\n"
  printf "${CHARS_LINE}\n"
  if [[ $2 = "--dev" ]]; then
    CLONE_URL="$SSH_CLONE_URL"
    INSTALL_PARAM="--dev"
  else
    clone_opts="--depth=1"
    CLONE_URL="$HTTPS_CLONE_URL"
    INSTALL_PARAM=""
  fi
  source "${RC_CLI_PATH}/DATA_URLS"
  git clone "${CLONE_URL}" \
    ${clone_opts} \
    "${RC_CLI_PATH}"
  if [ ! -d "${RC_CLI_PATH}" ]; then
    err "Git Clone Failed. Installation Canceled"
    exit 1
  else
    printf "INSTALL_PARAM=\"${INSTALL_PARAM}\"" > "${RC_CLI_PATH}/INSTALL_PARAMS"
  fi
}

copy_zip_data_down() { # Copy the needed data files locally
  # Takes two optional parameters (order matters)
  # EG:
  # copy_zip_data_down URL LOCAL_PATH NEW_DIR_NAME
  zip_file_name="$(basename $1)"
  zip_folder_name=${zip_file_name%.*}
  zip_file_path="${2}/${zip_file_name}"
  new_dir_name="${3:-$zip_folder_name}"
  printf "Copying data down from $1... "
  curl -s -o "${zip_file_path}" "$1" > /dev/null
  unzip -qq "${zip_file_path}" -d "$2"
  rm "${zip_file_path}"
  if [[ ! "${2}/${zip_folder_name}" = "${2}/${new_dir_name}" ]]; then
    mv "${2}/${zip_folder_name}" "${2}/${new_dir_name}"
  fi
  if [ ! -d "${2}/${new_dir_name}" ]; then
    err "Unable to access zipped data from ${1}. Installation Canceled"
    exit 1
  fi
  printf "done\n"

}

get_data() { # Copy the needed data files locally
  # EG:
  # get_data DATA_URL
  DATA_URL="${1:-''}"

  copy_zip_data_down "$DATA_URL" "${RC_CLI_PATH}" "data"

  printf "Setting data URL locally for future CLI Updates... "
  touch "${RC_CLI_PATH}/DATA_URLS"
  printf "DATA_URL=\"${DATA_URL}\"" > "${RC_CLI_PATH}/DATA_URLS"
  printf "done\n"
}

check_args() {
  if [[ $# -lt 1 ]]; then
    err "Not enough arguments to install the CLI with data. Please specify a a DATA_URL \nEG:\ncurl -o- https://raw.githubusercontent.com/MIT-CAVE/rc-cli/main/install.sh | bash -s https://cave-competition-app-data.s3.amazonaws.com/amzn_2021/public/data.zip"
    exit 1
  elif [[ $# -gt 1 && $2 != "--dev" ]]; then
    err "Too many arguments for CLI installation. Please only specify a DATA_URL\nEG:\ncurl -o- https://raw.githubusercontent.com/MIT-CAVE/rc-cli/main/install.sh | bash -s https://cave-competition-app-data.s3.amazonaws.com/amzn_2021/public/data.zip"
    exit 1
  fi
}

add_to_path() { # Add the cli to a globally accessable path
  printf "${CHARS_LINE}\n"
  printf "Making '${RC_CLI_COMMAND}' globally accessable: \nCreating link from '${RC_CLI_PATH}/${RC_CLI_COMMAND}.sh' as '${BIN_DIR}/${RC_CLI_COMMAND}':\n"
  if [ ! $(ln -sf "${RC_CLI_PATH}/${RC_CLI_COMMAND}.sh" "${BIN_DIR}/${RC_CLI_COMMAND}") ]; then
    printf "WARNING!: Super User priviledges required to complete link! Using 'sudo'.\n"
    sudo ln -sf "${RC_CLI_PATH}/${RC_CLI_COMMAND}.sh" "${BIN_DIR}/${RC_CLI_COMMAND}"
  fi
  printf "done\n"
}

success_message() { # Send a success message to the user on successful installation
  printf "${CHARS_LINE}\n"
  printf "${RC_CLI_SHORT_NAME} (${RC_CLI_COMMAND}) has been successfully installed \n"
  printf "You can verify the installation with 'rc-cli version'\n"
  printf "To get started use 'rc-cli help'\n"
}

main() {
  check_args "$@"
  check_os
  check_docker
  check_git
  check_previous_installation
  install_new "$@"
  get_data "$@"
  add_to_path
  success_message
}

main "$@"
