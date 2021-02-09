#!/bin/sh
#
# Install the RC CLI on Linux

# Constants
readonly INSTALL_DIR="${HOME}"
readonly GITHUB_ORG_NAME="MIT-CAVE"
readonly GITHUB_REPO_NAME="amzn-docker-2021"

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
  echo "$0: $1" >&2
}

main() {
  # Check if a previous installation exists
  if [ -d "${INSTALL_DIR}" ]; then
    err "found an existing installation of RC CLI"
    exit 1
  else
    mkdir -p "${INSTALL_DIR}"
    git clone "https://github.com/${GITHUB_ORG_NAME}/${GITHUB_REPO_NAME}" \
      --depth=1 \
      ${INSTALL_DIR}
    ln -sf ${INSTALL_DIR}/${GITHUB_REPO_NAME}/rc-cli.sh ${HOME}/.local/bin/rc-cli
  fi
  #
  # export RC_CLI_PATH="${HOME}/.rc_cli"
  # [ -s "${RC_CLI_PATH}/rc-cli.sh" ] && command . "${RC_CLI_PATH}/rc-cli.sh"

  # printf "rc-cli has been installed successfully."
}

main "$@"
