#!/bin/bash
# shellcheck disable=SC1090

set -e -u

#
# Run a given script k times.
# This script is a callee of watch
#
# Parameters:
# $1    : number of times
# $2... : command to run and its params
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# 0: at the script's end
# 1: if Pre-cond are not fulfilled
# 2: script error
# 255: report end of k times execution to watch

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0
SCRIPT_NAME_WO_EXT=$(basename "${SCRIPT_NAME%.*}")

# Vars
KTIMES="${1:-}"
KTIMES_CMD_PARAMS="${@:2}"
KTIMES_STATE="" #/tmp/ktimes_${KTIMES_CMD_NAME_WO_EXT}.state"

#####################################################
# Include Helper functions
#####################################################
 
[ -z "${KTIMES}" ] && { echo "No param given. Abort."; exit 1; }

get_ktimes_cmd_wo_ext() {
    local ktimes_cmd ktimes_params ktimes_cmd_name_wo_ext

    read -r ktimes_cmd ktimes_params < <(echo "${KTIMES_CMD_PARAMS}")
    ktimes_cmd_name_wo_ext=$(basename "${ktimes_cmd%.*}")
    
    echo "${ktimes_cmd_name_wo_ext}"
}

test_state_file_exists() {
    [ -z "${KTIMES_STATE}" ] && { return 1; }
    [ -f "${KTIMES_STATE}" ] && { return 0; }
    return 1
}

# compiles the state file name
set_state_file_var() {
    local cmd=$1
    local state_file
    
    state_file="/tmp/${SCRIPT_NAME_WO_EXT}_${cmd}.state"
    KTIMES_STATE="${state_file}"
}


# sets the KTIMES_STATE variable and creates the file
create_state_file() {
    local cmd=$1
    local state_file
    
    set_state_file_var "${cmd}"
    test_state_file_exists && { echo "Exception - state file exists: ${KTIMES_STATE}"; exit 2; }
    touch "${KTIMES_STATE}"
}

init_iteration() {
    local iter
    
    ((iter=0))
    echo "${iter}" > "${KTIMES_STATE}"
    
    echo "${iter}"
}

update_iteration() {
    local iter
    
    iter=$(read_iteration)
    ((iter=iter+1))
    echo "${iter}" > "${KTIMES_STATE}"
}

read_iteration() {
    local iter
    
    read -r iter < <(head -1 "${KTIMES_STATE}")
    [[ -z "${iter}" ]] && { iter=$(init_iteration); }
    
    echo "${iter}"
}

ktimes_done() {
    echo "k times iterations done: ${KTIMES}"
    rm -rf "${KTIMES_STATE}"
    exit 255
}

#####################################################
# Main program
#####################################################

[[ "${KTIMES}" -ge 1 ]] || { echo "Invalid KTIMES param: ${KTIMES}"; exit 1; }
[[ -z "${KTIMES_CMD_PARAMS}" ]] && { echo "No command to run given."; exit 1; }

# parses KTIMES_CMD_PARAMS and set KTIMES_STATE variable
KTIMES_CMD_NAME_WO_EXT=$(get_ktimes_cmd_wo_ext)
set_state_file_var "${KTIMES_CMD_NAME_WO_EXT}"

if test_state_file_exists; then
    (($(read_iteration) >= KTIMES)) && { ktimes_done; }
else 
    # parse command and its params
    KTIMES_CMD_NAME_WO_EXT=$(get_ktimes_cmd_wo_ext)
    create_state_file "${KTIMES_CMD_NAME_WO_EXT}"
fi

# state file must exist
test_state_file_exists || { echo "State file must exists: ${KTIMES_STATE}"; exit 2; }

# run command with its params
echo "----RUN--------"
echo "${KTIMES_CMD_PARAMS}"
${KTIMES_CMD_PARAMS}
echo "---------------"


update_iteration
(($(read_iteration) >= KTIMES)) && { ktimes_done; }

exit 0
