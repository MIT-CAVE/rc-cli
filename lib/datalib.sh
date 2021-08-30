#!/bin/bash
readonly BSDTAR_BIN="bsdtar"
readonly TAR_BIN="tar"
readonly UNZIP_BIN="unzip"
readonly MIN_TAR_VERSION="1.22"
readonly MIN_BSDTAR_VERSION="0" # FIXME: Minimum version for which 'xz' compression is supported

# Gets the available file archiver installed on
# the system in a specific order of preference.
# bsdtar (Mac) > tar (Unix) > (un)zip
get_file_archiver() {
  if [[ -n $(which ${BSDTAR_BIN}) ]]; then
    printf "bsdtar"
  elif [[ -n $(which ${TAR_BIN}) ]]; then
    printf "tar"
  elif [[ -n $(which ${UNZIP_BIN}) ]]; then
    printf "unzip"
  fi
}

# Gets the URL of the data file to download.
get_data_url() {
  local file_arch=$1
  case ${file_arch} in
    ${BSDTAR_BIN} | ${TAR_BIN})
      printf ${DATA_URL_XZ}
      ;;
    ${UNZIP_BIN})
      printf ${DATA_URL_ZIP}
      ;;
    *)
      err "Could not find a URL compatible with the provided file archiver"
      ;;
  esac
}

# Gets the version of the given file archiver name.
get_file_arch_version() {
  local file_arch=$1
  case ${file_arch} in
    ${BSDTAR_BIN})
      printf "$(bsdtar --version | sed 's/\([a-z]\+\s\)\(.*\)\-.*/\2/g')"
      ;;
    ${TAR_BIN})
      printf "$(tar --version | grep -m1 -o ").*" | sed "s/) //")"
      ;;
    ${UNZIP_BIN})
      # TODO
      ;;
    *)
      err "Error"
      ;;
  esac
}

check_version() {
  local prog_name="$1"
  local exit_code="$2"
  local err_str="$3"
  local min_ver="$4"
  local current_ver="$5"
  if [[ ! "$(printf '%s\n' "${min_ver}" "${current_ver}" | sort -V | head -n1)" == "${min_ver}" ]]; then
    err "Your current ${prog_name} version (${current_ver}) is too old. ${err_str}"
    [[ ${exit_code} -eq 1 ]] && exit 1
  fi
}

check_file_archiver() {
  local file_arch
  local file_arch_ver
  local min_ver
  local install_msg
  file_arch=$(get_file_archiver)
  if [[ -z ${file_arch} ]]; then
    err "There is no compatible file archiver installed on your system.\nPlease install tar (preferably) or zip."
    exit 1
  fi
  # Validate file archiver version
  file_arch_ver=$(get_file_arch_version ${file_arch})
  case ${file_arch} in
    ${BSDTAR_BIN} | ${TAR_BIN})
      [[ ${file_arch} == "${TAR_BIN}" ]] \
        && min_ver=${MIN_TAR_VERSION} \
        || min_ver=${MIN_BSDTAR_VERSION}
      ;;
    ${UNZIP_BIN})
      # TODO:
      # Check the compatibility with the unzip version
      # and the compression level used for the data.
      # err "The data file you are installing with is not recognized. \nPlease install the ${RC_CLI_SHORT_NAME} with a 'xz' or 'ZIP' file."
      ;;
    *) # This should not happen unless there's a bug in get_file_archiver
      err "The file archiver is not recognized."
      exit 1
      ;;
  esac
  install_msg="\nPlease install ${file_arch} version ${min_ver} or greater.\n"
  check_version ${file_arch} 1 "${install_msg}" ${min_ver} ${file_arch_ver}
}

# Shoutout to:
# https://unix.stackexchange.com/a/450405
# https://stackoverflow.com/a/39615292
datalib::get_content_length() {
  local url=$1
  local redirect_sizes
  local size
  redirect_sizes="$(curl -sLI ${url} | awk -v IGNORECASE=1 '/^Content-Length/ { print $2 }')"
  size=$(echo ${redirect_sizes##*$'\n'} | sed 's/\r$//')
  printf ${size}
}

# Download the data file(s) from the given URL
download_data() {
  local data_url=$1
  local f_name
  f_name="$(basename ${data_url})"
  # TODO: save to a rc-cli-$(uuidgen) directory
  local f_path="${TMP_DIR}/${f_name}"

  local tmp_dl_path="${TMP_DIR}/${f_name}"
  printf "Downloading data from ${data_url}...\n" >&2
  curl -L -o "${tmp_dl_path}" --progress-bar ${data_url}
  printf ${tmp_dl_path}
}

# Checks if the integrity of a downloaded file is compromised.
# TODO
check_file_integrity() {
  local f_path=$1
  if [[ -n "" ]]; then
    err "The file '${f_path}' is corrupted"
    exit 1
  fi
}

# Decompress a given file and move its contents to a destination directory.
decompress_and_load() {
  local f_path=$1
  local dest_path=$2

  if [[ ! ${dest_path} -ef ${RC_CLI_PATH} ]]; then
    rm -rf ${dest_path} # Remove old data
    mkdir -p ${dest_path}
  fi
  # Since the compressed file contains a 'data' directory
  local base_path
  base_path=$(dirname ${dest_path})
  printf "\nDecompressing data... "
  case "${f_path##*.}" in
    xz)
      tar -xf ${f_path} -C ${base_path}
      ;;
    zip)
      unzip -qq ${f_path} -d ${base_path}
      ;;
  esac
  printf "done\n\n"
  rm ${f_path}
}

# Saves the DATA_URL and INSTALL_PARAM to the CONFIG file.
save_config() {
  local data_url=$1
  printf "Setting data URL locally for future CLI Updates... "
  printf "DATA_URL=\"${data_url}\"\n" > "${RC_CLI_PATH}/CONFIG"
  [[ -n ${INSTALL_PARAM} ]] \
    && printf "INSTALL_PARAM=\"${INSTALL_PARAM}\"\n" >> "${RC_CLI_PATH}/CONFIG"
  printf "done\n"
}

# Load the CONFIG file. If it doesn't exist, it is created.
datalib::load_or_create_config() {
  local file_arch
  file_arch=$(get_file_archiver)
  check_file_archiver ${file_arch}
  local data_url
  data_url=$(get_data_url ${file_arch})
  if [[ ! -f "${RC_CLI_PATH}/CONFIG" ]]; then
    printf "\nWARNING! Could not find a CONFIG file.\n"
    printf "A CONFIG file will be created now... "
    printf "DATA_URL=\"${data_url}\"\n" > "${RC_CLI_PATH}/CONFIG"
    printf "done\n"
  fi
  # shellcheck source=./CONFIG
  . "${RC_CLI_PATH}/CONFIG"
}

datalib::update_data() {
  local data_url=$1
  local dest_path=$2

  local file_arch
  file_arch=$(get_file_archiver)
  check_file_archiver ${file_arch}

  local f_path
  f_path=$(download_data ${data_url})
  check_file_integrity ${f_path}
  decompress_and_load ${f_path} ${dest_path}

  save_config ${data_url}
}
