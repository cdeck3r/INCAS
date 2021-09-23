#!/bin/bash
set -e -u

#
# Write camera IP addresses into config.yml
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
LOG_DIR=$(yq e '.log_dir' "${CONF}")
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME_WO_EXT}.log"
IP_LOG="${LOG_DIR}/ipcameras.log"

#####################################################
# Include Helper functions
#####################################################

log_echo_file() {
    local level=$1
    local msg=$2

    log_echo "${level}" "${msg}" >>"${LOG_FILE}"
}

add_update_conf() {
    local key=$1
    local val=$2

    log_echo_file "DEBUG" "Update config: .${key} = ${val}"

    # ensure val is always a string
    keyval=".${key} = strenv(val)"
    val="${val}" yq e -i "${keyval}" "${CONF}"
}

#####################################################
# Main program
#####################################################

[[ -f "${IP_LOG}" ]] || {
    log_echo_file "ERROR" "IP address file does not exist: ${IP_LOG}"
    exit 1
}

log_echo_file "INFO" "Read logfile: ${IP_LOG}"
mapfile -t camera_ips < <(sort "${IP_LOG}" | uniq)
num_ip="${#camera_ips[@]}"
log_echo_file "INFO" "Found number of IP addresses: ${num_ip}"

for ((i = 0; i < num_ip; i++)); do
    ip=$(echo "${camera_ips[$i]}" | cut -d':' -f2 | xargs)
    log_echo_file "INFO" "Add IP to config file: ${ip}"
    add_update_conf "cameras.$((i + 1)).ip" "${ip}"
done

exit 0
