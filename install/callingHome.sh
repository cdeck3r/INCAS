#!/bin/bash
set -e -u

#
# callingHome script
# The raspi gets a dynamic IP address via DHCP.
# Calling But, how do we get informed about it?
#
# The raspi makes a Website request with its IP as query parameter.
# We check the webserver log for the request.
#
# 1. verify `/boot/incas.ini` exists and read URL
# 1. issue HTTP request with IP as parameter
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
source "${SCRIPT_DIR}/include/funcs.sh"

# variables
CONF="${SCRIPT_DIR}/config.yml"
LOG_DIR=$(yq e '.log_dir' "${CONF}")
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME_WO_EXT}.log"

# variables
INCAS_INI="/boot/incas.ini"

#####################################################
# Include Helper functions
#####################################################

log_echo_file() {
    local level=$1
    local msg=$2

    log_echo "${level}" "${msg}" >>"${LOG_FILE}"
}

# tracker may use this functions
# to retrieve the tracker value from the ini file
# given the tracker name
#
# Param: tracker variable name as string
# Return: tracker variable value as string
get_tracker() {
    local tracker_varname
    tracker_varname=$1

    # Return: tracker variable value
    echo "${!tracker_varname}"
}

publish_to_tracker() {
    local TRACKER

    TRACKER=$(get_tracker "TRACKER_NWEB")
    if [ -z "${TRACKER}" ]; then
        log_echo_file "ERROR" "Could not found my tracker from ini file: NWEB"
        return 1
    fi

    log_echo_file "INFO" "Tracker nweb for URL ${TRACKER}"

    wget --tries=2 "${TRACKER}/index.html?name=incas&ip=$(hostname -I)" || { log_echo_file "ERROR" "wget did not complete successfully. Return code: $?"; }

    return 0
}

#####################################################
# Main program
#####################################################

[[ -f "${INCAS_INI}" ]] || {
    echo "INI file does not exist: ${INCAS_INI}"
    exit 1
}
# shellcheck disable=SC1090
# shellcheck disable=SC1091
source "${INCAS_INI}"

publish_to_tracker

exit 0
