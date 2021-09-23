#!/bin/bash
set -e -u

#
# Take snapshot from IP cameras
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# 1 if pre-cond not fulfilled
# 2 if script breaks

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0
SCRIPT_NAME_WO_EXT=$(basename "${SCRIPT_NAME%.*}")

# common stuff
# shellcheck source=/INCAS/src/include/funcs.sh
source "${SCRIPT_DIR}/../include/funcs.sh"

# variables
CONF="${SCRIPT_DIR}/../config.yml"
IMG_DIR="${1:-}"
WWW_IMAGES="$(yq e .www-images "${CONF}")"
LOG_DIR="$(yq e .log_dir "${CONF}")"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME_WO_EXT}.log"

USER="$(yq e .cameras.incas_user "${CONF}")"
PASS="$(yq e .cameras.incas_pass "${CONF}")"

#####################################################
# Include Helper functions
#####################################################

log_echo_file() {
    local level=$1
    local msg=$2

    log_echo "${level}" "${msg}" >>"${LOG_FILE}"
}

# Set image directory name to store snapshot images
# It ensures the directory exists.
# Logic:
# - if dir is omitted, create a generated one as subdir of WWW_IMAGES
# - If given directory exists, take it
# - if it does not exist, create it as subdir of WWW_IMAGES directory
set_img_dir() {
    local img_dir=${1-}

    if [[ -z "${img_dir}" ]]; then
        img_dir=$(date '+%Y%m%d_%H%M%S')
        IMG_DIR="${WWW_IMAGES}/snapshot/${img_dir}"
    elif [[ -d "${img_dir}" ]]; then
        IMG_DIR="${img_dir}"
    else
        IMG_DIR="${WWW_IMAGES}/snapshot/${img_dir}"
    fi

    mkdir -p "${IMG_DIR}"
    [[ -d "${IMG_DIR}" ]] || {
        log_echo_file "ERROR" "Directory not created: ${IMG_DIR}"
        return 1
    }
    log_echo_file "INFO" "Image directory is ${IMG_DIR}"

    return 0
}

#####################################################
# Main program
#####################################################

[[ -d "${LOG_DIR}" ]] || {
    log_echo_file "ERROR" "Directory expected to exist: ${LOG_DIR}"
    log_echo "ERROR" "Abort! Directory expected to exist: ${LOG_DIR}"
    exit 1
}

set_img_dir "${IMG_DIR}" || {
    log_echo "ERROR" "Abort! Image directory directory does not exist: ${IMG_DIR}"
    exit 2
}

[[ -z "${PASS}" ]] && {
    log_echo_file "ERROR" "No password provided. Abort."
    exit 2
}

# loop though all cameras
# - define new IMG_NAME from camera num and date
# - take snapshot and store in IMG_DIR as IMG_NAME
CAMERA_IPS="$(yq e '.cameras.[] | select(. | has("ip")) | .ip' "${CONF}")"
CAMERA_NUMS="$(yq e '.cameras.[] | select(. | has("ip")) | path | .[-1]' "${CONF}")"
mapfile -t camera_ips < <(echo "${CAMERA_IPS}")
mapfile -t camera_nums < <(echo "${CAMERA_NUMS}")
log_echo_file "INFO" "Taking snapshots and store in directory: ${IMG_DIR}"
for ((i = 0; i < "${#camera_ips[@]}"; i++)); do
    ip="${camera_ips[$i]}"
    n="$(printf "%02d" "${camera_nums[$i]}")"
    # filename format: cam<n>_yyyymmdd_hhmmss
    IMG_NAME="Cam${n}_$(date '+%Y%m%d_%H%M%S')"
    # issue HTTP request to take snapshot
    log_echo_file "INFO" "Take a snapshot from Cam${n}: ${ip}"
    curl -s --user "${USER}:${PASS}" --digest "http://${ip}/cgi-bin/snapshot.cgi" -o "${IMG_DIR}/${IMG_NAME}.jpg"
    CURL_RET=$?
    # error reporting
    if [[ "${CURL_RET}" -ne 0 ]] || [[ ! -f "${IMG_DIR}/${IMG_NAME}.jpg" ]]; then
        log_echo_file "ERROR" "Error when taking snapshot from camera IP address and save it to file: ${ip},  ${IMG_DIR}/${IMG_NAME}.jpg"
    fi
done
