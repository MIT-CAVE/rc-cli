#!/bin/bash
readonly MIN_TAR_VERSION="1.22"
readonly MIN_BSDTAR_VERSION="0" # FIXME: Minimum version for which 'xz' compression is supported

get_compressed_data_info() { # Get information on compressed data to download
  DATA_URL="${1:-''}"
  compressed_file_name="$(basename $DATA_URL)"
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

# Get the current version of the 'tar' archiving utility
get_tar_version() {
  if [[ -n $(which bsdtar) ]]; then
    printf "$(bsdtar --version | sed 's/\([a-z]\+\s\)\(.*\)\-.*/\2/g')"
  elif [[ -n $(which tar) ]]; then
    printf "$(tar --version | grep -m1 -o ").*" | sed "s/) //")"
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

# Get information on compressed data to download.
get_dest_path() {
  local data_url="${1:-''}"

  local f_name
  f_name="$(basename ${data_url})"
  local f_path="${RC_CLI_PATH}/${f_name}"
  [[ "${f_path##*.}" == "xz" ]] && printf ${f_name%.*.*} || printf ${f_name%.*}
}

copy_compressed_data_down() { # Copy the needed data files locally
  # Takes three optional parameters (order matters)
  # EG:
  # copy_compressed_data_down URL LOCAL_PATH NEW_DIR_NAME
  new_dir_name="${3:-$compressed_folder_name}"
  printf "Copying data down from $1... "
  curl -s -o "${compressed_file_path}" "$1" > /dev/null
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

update_data() { # Copy the needed data files locally
  copy_compressed_data_down "$DATA_URL" "${RC_CLI_PATH}" "$DATA_DIR"
  printf "Setting data URL locally for future CLI Updates..."
  printf "DATA_URL=\"${DATA_URL}\"\n" > "${RC_CLI_PATH}/CONFIG"
  [[ -n ${INSTALL_PARAM} ]] \
    && printf "INSTALL_PARAM=\"${INSTALL_PARAM}\"\n" >> "${RC_CLI_PATH}/CONFIG"
  printf "done\n"
}

data::update_data() {
  get_compressed_data_info "$@"
  check_compression
  update_data
}
