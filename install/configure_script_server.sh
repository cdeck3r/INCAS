#!/bin/bash
set -e -u

#
# Post-install action: Configure script-server
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

# common stuff
# shellcheck source=/INCAS/install/common.sh
source "${SCRIPT_DIR}/common.sh"
: "${INCAS_DIR}"
: "${LOG_DIR}"

# variables
LOGGING_CONF="${INCAS_DIR}/script-server/conf/logging.json"

#####################################################
# Include Helper functions
#####################################################

command -v "yq" >/dev/null 2>&1 || {
    echo >&2 "I require yq but it's not installed.  Abort."
    exit 1
}

add_update_conf() {
    local key=$1
    local val=$2

    # ensure val is always a string
    keyval=".${key} = strenv(val)"
    val="${val}" yq e -i "${keyval}" "${LOGGING_CONF}"
}

#####################################################
# Main program
#####################################################

bailout_if_root
check_user || {
    echo "User mismatch. Script must run as user: ${USER}"
    exit 1
}

# modify loggin.conf
[[ -f "${LOGGING_CONF}" ]] || {
    echo "ERROR: file does not exist: ${LOGGING_CONF}"
    exit 2
}
add_update_conf ".handlers.file.filename" "${LOG_DIR}/script-server.log"

exit 0
