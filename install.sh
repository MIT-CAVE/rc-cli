#!/bin/bash
#
# Install the RC CLI on Unix Systems

# Constants
readonly CHARS_LINE="============================"
readonly RC_CLI_PATH="${HOME}/.rc-cli"
readonly RC_CLI_SHORT_NAME="RC CLI"
readonly RC_CLI_COMMAND="rc-cli"
readonly RC_CLI_VERSION="0.2.0"
readonly BIN_DIR="/usr/local/bin"
readonly DATA_DIR="data"
readonly SSH_CLONE_URL="git@github.com:MIT-CAVE/rc-cli.git"
readonly HTTPS_CLONE_URL="https://github.com/MIT-CAVE/rc-cli.git"
readonly MIN_DOCKER_VERSION="18.09.00"
readonly MIN_TAR_VERSION="1.22"
readonly MIN_BSDTAR_VERSION="0" # FIXME: Minimum version for which 'xz' compression is supported

err() { # Display an error message
  printf "$0: $1\n" >&2
}

# Get the current version of the 'tar' archiving utility
get_tar_version() {
  if [[ -n $(which bsdtar) ]]; then
    printf "$(bsdtar --version | sed 's/\([a-z]\+\s\)\(.*\)\-.*/\2/g')"
  elif [[ -n $(which tar) ]]; then
    printf "$(tar --version | grep -m1 -o ").*" | sed "s/) //")"
  fi
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

get_compressed_data_info() { # Get information on compressed data to download
  DATA_URL="${1:-''}"
  compressed_file_name=$(printf "$(basename $DATA_URL)" | sed 's/?.*//')
  compressed_file_path="${RC_CLI_PATH}/${compressed_file_name}"
  compressed_file_type="${compressed_file_path##*.}"
  if [[ "$compressed_file_type" = "xz" ]]; then
    compressed_file_name_no_ext==${compressed_file_name%.*.*}
    compressed_folder_name=${compressed_file_name%.*.*}
  else
    compressed_file_name_no_ext==${compressed_file_name%.*}
    compressed_folder_name=${compressed_file_name%.*}
  fi

}

validate_install() {
  local PROGRAM_NAME="$1"
  local EXIT_BOOL="$2"
  local ERROR_STRING="$3"
  if [ "$($PROGRAM_NAME --version)" = "" ]; then
    err "${PROGRAM_NAME} is not installed. ${ERROR_STRING}"
    if [ "${EXIT_BOOL}" = "1" ]; then
      exit 1
    fi
  fi
}

validate_version() {
  local PROGRAM_NAME="$1"
  local EXIT_BOOL="$2"
  local ERROR_STRING="$3"
  local MIN_VERSION="$4"
  local CURRENT_VERSION="$5"
  if [ ! "$(printf '%s\n' "$MIN_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" = "$MIN_VERSION" ]; then
    err "Your current $PROGRAM_NAME version ($CURRENT_VERSION) is too old. ${ERROR_STRING}"
    if [ "${EXIT_BOOL}" = "1" ]; then
      exit 1
    fi
  fi

}

check_compression() { # Validate tar compression command is installed
  if [[ "${compressed_file_type}" == "xz" ]]; then
    [[ -n $(which bsdtar) ]] \
      && min_tar_ver=${MIN_TAR_VERSION} \
      || min_tar_ver=${MIN_BSDTAR_VERSION}
    install_tar="\nPlease install version ${min_tar_ver} or greater. \nIf your machine does not support tar, you may consider installing {$RC_CLI_SHORT_NAME} using a zip folder. \nThis requires the unzip function to be installed locally.\n"
    validate_install "tar" "1" "${install_tar}"
    CURRENT_TAR_VERSION=$(get_tar_version)
    validate_version "tar" "1" "${install_tar}" "${min_tar_ver}" "${CURRENT_TAR_VERSION}"
  # Can not validate unzip as version pipes out to stderr
  elif [[ "${compressed_file_type}" == "zip" ]]; then
    : # Do nothing
  #   install_unzip="\nPlease install unzip."
  #   validate_install "unzip" "1" "$install_unzip"
  else
    err "The data file you are installing with is not recognized. \nPlease install the $RC_CLI_SHORT_NAME with a tar.xz or zip file."
    exit 1
  fi
}

check_docker() { # Validate docker is installed
  install_docker="\nPlease install version ${MIN_DOCKER_VERSION} or greater. \nFor more information see: 'https://docs.docker.com/get-docker/'"
  validate_install "docker" "1" "$install_docker"
  CURRENT_DOCKER_VERSION=$(docker --version | sed -e 's/Docker version \(.*\), build.*/\1/')
  validate_version "docker" "1" "$install_docker" "$MIN_DOCKER_VERSION" "$CURRENT_DOCKER_VERSION"
}

check_git() { # Validate git is installed
  install_git="\nPlease install git. \nFor more information see: 'https://git-scm.com'"
  validate_install "git" "1" "$install_git"
}

check_previous_installation() { # Check to make sure previous installations are removed before continuing
  if [ -d "${RC_CLI_PATH}" ]; then
    LOCAL_CLI_VERSION=$(<${RC_CLI_PATH}/VERSION)
    printf "An existing installation of ${RC_CLI_SHORT_NAME} ($LOCAL_CLI_VERSION) was found \nLocation: ${RC_CLI_PATH}\n"
    printf "You are installing ${RC_CLI_SHORT_NAME} ($RC_CLI_VERSION)\n"
    if [ "$LOCAL_CLI_VERSION" = "$RC_CLI_VERSION" ] ; then
      read -r -p "Would you like to reinstall ${RC_CLI_SHORT_NAME} ($RC_CLI_VERSION)? [y/N] " input
    else
      data_warn="WARNING! As of version 0.2.0, ${RC_CLI_SHORT_NAME} does not download the dataset for you in the installation process. The data in your current version of ${RC_CLI_SHORT_NAME} will be backed up temporarily and restored once the update process completes. If you want to update your data sources manually please refer to:\n1. https://github.com/MIT-CAVE/rc-cli#download-your-dataset\n2. https://registry.opendata.aws/amazon-last-mile-challenges/\n\n"
      [ "${RC_CLI_PATH:2:1}" = 2 ] && printf "${data_warn}"
      read -r -p "Would you like to update to ${RC_CLI_SHORT_NAME} ($RC_CLI_VERSION)? [y/N] " input
    fi
    case ${input} in
      [yY][eE][sS] | [yY])
        printf "Moving your dataset to a temporary location... "
        data_path_tmp="${HOME}/${RC_CLI_COMMAND}-data-$(uuidgen)"
        mv ${RC_CLI_PATH}/${DATA_DIR} ${data_path_tmp}
        printf "done\n"
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
  mkdir -p "${RC_CLI_PATH}/${DATA_DIR}"
  printf "done\n"
  printf "${CHARS_LINE}\n"
  printf ${data_path_tmp}
  if [[ $1 = "--dev" ]]; then
    CLONE_URL="$SSH_CLONE_URL"
    INSTALL_PARAM="--dev"
  else
    clone_opts="--depth=1"
    CLONE_URL="$HTTPS_CLONE_URL"
    INSTALL_PARAM=""
  fi
  git clone "${CLONE_URL}" \
    ${clone_opts} \
    "${RC_CLI_PATH}" > /dev/null
  if [ ! -d "${RC_CLI_PATH}" ]; then
    err "Git Clone Failed. Installation Canceled"
    [ -n "${data_path_tmp}" ] && printf "Your data was backed up to '${data_path_tmp}'.\n"
    exit 1
  else
    if [ -n "${data_path_tmp}" ]; then
      printf "Restoring data from previous installation... "
      mv "${data_path_tmp}" "${RC_CLI_PATH}/${DATA_DIR}"
      printf "done\n"
    fi
    printf "INSTALL_PARAM=\"${INSTALL_PARAM}\"\n" > "${RC_CLI_PATH}/CONFIG"
  fi
}

copy_compressed_data_down() { # Copy the needed data files locally
  # Takes three optional parameters (order matters)
  # EG:
  # copy_compressed_data_down URL LOCAL_PATH NEW_DIR_NAME
  new_dir_name="${3:-$compressed_folder_name}"
  printf "Copying data down from $1...\n"
  curl -L -o "${compressed_file_path}" "$1" --progress-bar
  printf "done\n"
  printf "Decompressing downloaded data...\n"
  if [[ "${compressed_file_type}" = "xz" ]]; then
    tar -xf "${compressed_file_path}" -C "$2"
  elif [[ "${compressed_file_type}" = "zip" ]]; then
    unzip -qq "${compressed_file_path}" -d "$2"
  fi
  rm "${compressed_file_path}"
  if [[ ! "${2}/${compressed_folder_name}" = "${2}/${new_dir_name}" ]]; then
    mv "${2}/${zip_folder_name}" "${2}/${new_dir_name}"
  fi
  if [ ! -d "${2}/${new_dir_name}" ]; then
    err "Unable to access data from ${1}. Installation Canceled"
    exit 1
  fi
  printf "done\n"

}

get_data() { # Copy the needed data files locally
  copy_compressed_data_down "$DATA_URL" "${RC_CLI_PATH}" "$DATA_DIR"
  printf "Setting data URL locally for future CLI Updates... "
  printf "DATA_URL=\"${DATA_URL}\"\n" >> "${RC_CLI_PATH}/CONFIG"
  printf "done\n"
}

check_args() {
  local cmd_ex="bash <(curl -s https://raw.githubusercontent.com/MIT-CAVE/rc-cli/main/install.sh)"
  if [[ $# -gt 0 && $1 != "--dev" ]]; then
    err "Too many arguments for CLI installation. Please only specify a '--dev' option if you want to work on the development of ${RC_CLI_SHORT_NAME}\nEG:${cmd_ex}"
    exit 1
  fi
}

add_to_path() { # Add the cli to a globally accessable path
  printf "${CHARS_LINE}\n"
  printf "Making '${RC_CLI_COMMAND}' globally accessable: \nCreating link from '${RC_CLI_PATH}/${RC_CLI_COMMAND}.sh' as '${BIN_DIR}/${RC_CLI_COMMAND}':\n"
  if [ ! $(ln -sf "${RC_CLI_PATH}/${RC_CLI_COMMAND}.sh" "${BIN_DIR}/${RC_CLI_COMMAND}") ]; then
    printf "WARNING! Super User privileges required to complete link! Using 'sudo'.\n"
    sudo ln -sf "${RC_CLI_PATH}/${RC_CLI_COMMAND}.sh" "${BIN_DIR}/${RC_CLI_COMMAND}"
  fi
  printf "done\n"
}

success_message() { # Send a success message to the user on successful installation
  printf "${CHARS_LINE}\n"
  printf "${RC_CLI_SHORT_NAME} (${RC_CLI_COMMAND}) has been successfully installed \n"
  printf "You can verify the installation with '${RC_CLI_COMMAND} version'\n"
  printf "To get started use '${RC_CLI_COMMAND} help'\n"
}

main() {
  check_args "$@"
  check_os
  # get_compressed_data_info "$@"
  # check_compression
  check_docker
  check_git
  check_previous_installation
  install_new "$@"
  # get_data
  add_to_path
  success_message
}

main "$@"
