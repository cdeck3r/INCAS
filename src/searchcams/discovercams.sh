#!/bin/bash
set -e -u

#
# Discover IP Cameras using avahi
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

#####################################################
# Include Helper functions
#####################################################

log_echo_file() {
    local level=$1
    local msg=$2

    log_echo "${level}" "${msg}" >>"${LOG_FILE}"
}

# stores IP addresses in TMPFILE
discover_web_site_services() {
    avahi-browse -atpr | grep "Web Site" | cut -d';' -f8 | xargs | sort | uniq >"${TMPFILE}"
}

#####################################################
# Main program
#####################################################

[[ -f "${SCRIPT_DIR}/searchcams.sh" ]] || {
    log_echo_file "ERROR" "searchcams.sh script not found. Abort"
    echo "ERROR: searchcams.sh script not found. Abort"
    exit 1
}
[[ -x "${SCRIPT_DIR}/searchcams.sh" ]] || {
    log_echo_file "ERROR" "searchcams.sh script not executable. Abort"
    echo "ERROR: searchcams.sh script not executable. Abort"
    exit 1
}

# resolve all found hosts and log them
log_echo_file "INFO" "Run avahi and 'searchcams.sh' to probe for IP camera"
avahi-browse -atpr | grep "Web Site" | cut -d';' -f8 | sort | uniq | xargs -I {} "${SCRIPT_DIR}/searchcams.sh" {} "255.255.255.255"

exit 0
