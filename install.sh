#!/bin/bash
#
# Install the RC CLI on Linux

# Constants
readonly CHARS_LINE="============================"
readonly INSTALL_DIR="${HOME}"
readonly INSTALL_NAME=".rc-cli"
readonly CLI_NAME="rc-cli"
readonly BIN_DIR="/usr/local/bin"
readonly GITHUB_ORG_NAME="MIT-CAVE"
readonly GITHUB_REPO_NAME="rc-cli"
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
  if [ -d "${INSTALL_DIR}/${INSTALL_NAME}" ]; then
    LOCAL_CLI_VERSION="$(cat ${INSTALL_DIR}/${INSTALL_NAME}/rc-cli.sh | grep 'readonly RC_CLI_VERSION' | sed -e 's/.*="\(.*\)".*/\1/')"
    CURRENT_CLI_VERSION="v0.1.0" #TODO Get current version from remote
    printf "An existing installation of RC CLI ($LOCAL_CLI_VERSION) was found \nLocation: ${INSTALL_DIR}/${INSTALL_NAME}\n"
    printf "The most up to date version is RC CLI ($CURRENT_CLI_VERSION)\n"

    if [ $LOCAL_CLI_VERSION = $CURRENT_CLI_VERSION ] ; then
      read -r -p "Would you like to reinstall RC CLI ($CURRENT_CLI_VERSION)? [y/N] " input
    else
      read -r -p "Would you like to update to RC CLI ($CURRENT_CLI_VERSION)? [y/N] " input
    fi
    case ${input} in
      [yY][eE][sS] | [yY])
        printf "Removing old installation... "
        rm -rf "${INSTALL_DIR}/${INSTALL_NAME}"
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
  printf "Creating application folder at '${INSTALL_DIR}/${INSTALL_NAME}'..."
  mkdir -p "${INSTALL_DIR}/${INSTALL_NAME}"
  printf "done\n"
  printf "${CHARS_LINE}\n"
  printf "Cloning from 'https://github.com/${GITHUB_ORG_NAME}/${GITHUB_REPO_NAME}':\n"
  git clone "git@github.com:${GITHUB_ORG_NAME}/${GITHUB_REPO_NAME}" \
    --depth=1 \
    "${INSTALL_DIR}/${INSTALL_NAME}"
  if [ ! -d "${INSTALL_DIR}/${INSTALL_NAME}" ]; then
    err "Git Clone Failed. Installation Canceled"
    exit 1
  fi
}

add_to_path() { # Add the cli to a globally accessable path
  printf "${CHARS_LINE}\n"
  printf "Making '${CLI_NAME}' globally accessable: \nCreating link from '${INSTALL_DIR}/${INSTALL_NAME}/${CLI_NAME}.sh' as '${BIN_DIR}/${CLI_NAME}':\n"
  if [ ! $(ln -sf "${INSTALL_DIR}/${INSTALL_NAME}/${CLI_NAME}.sh" "${BIN_DIR}/${CLI_NAME}") ]; then
    printf "Warning: Super User priviledges required to complete link! Using 'sudo'.\n"
    sudo ln -sf "${INSTALL_DIR}/${INSTALL_NAME}/${CLI_NAME}.sh" "${BIN_DIR}/${CLI_NAME}"
  fi
  printf "done\n"
}

success_message() { # Send a success message to the user on successful installation
  printf "${CHARS_LINE}\n"
  printf "${GITHUB_REPO_NAME} has been successfully installed \n"
  printf "You can verify the installation with 'rc-cli --version'\n"
  printf "To get started use 'rc-cli --help'\n"
}

main() {
  check_os
  check_docker
  check_git
  check_previous_installation
  install_new
  add_to_path
  success_message
}

main "$@"
