#!/bin/bash
readonly CHARS_LINE="============================"
readonly RC_CLI_LONG_NAME="Routing Challenge CLI"
readonly RC_CLI_SHORT_NAME="RC CLI"
readonly RC_CLI_VERSION=$(<${RC_CLI_PATH}/VERSION)
readonly RC_IMAGE_TAG="rc-cli"
readonly TMP_DIR="/tmp"

readonly APP_DEST_MNT="/home/app/data"

readonly DATA_DIR="data"
