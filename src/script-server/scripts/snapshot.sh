#!/bin/bash
# shellcheck disable=SC1090

#
# All configured cameras take a snapshot. 
# Afterwards, you may download the images from the webserver's root directory.
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# 0: at the script's end
# 255: if BAIL_OUT

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# Vars
TAKEIMG_DIR="${SCRIPT_DIR}/../../takeimg"
TAKE_SNAPSHOT="${TAKEIMG_DIR}/snapshot.sh"

[ -f "${SCRIPT_DIR}/common_vars.conf" ] || {
    echo "Could find required config file: common_vars.conf"
    echo "Abort."
    exit 1
}
[ -f "${SCRIPT_DIR}/tap-functions.sh" ] || {
    echo "Could find required file: tap-functions.sh"
    echo "Abort."
    exit 1
}

source "${SCRIPT_DIR}/common_vars.conf"
source "${SCRIPT_DIR}/tap-functions.sh"

#####################################################
# Include Helper functions
#####################################################

[ -f "${SCRIPT_DIR}/funcs.sh" ] || {
    echo "Could find required file: funcs.sh"
    echo "Abort."
    exit 1
}
source "${SCRIPT_DIR}/funcs.sh"

#####################################################
# Main program
#####################################################

# first things first
HR=$(hr) # horizontal line
plan_no_plan

SKIP_CHECK=$(
    false
    echo $?
)
precheck "${SKIP_CHECK}"

diag "${HR}"
diag "Prepare"
diag "${HR}"

okx [ -f "${TAKE_SNAPSHOT}" ]
okx [ -x "${TAKE_SNAPSHOT}" ]

diag " "

diag "${HR}"
diag "Take snapshot"
diag "${HR}"

${TAKE_SNAPSHOT}
is $? 0 "Snapshot taken"

# Summary
diag "${HR}"
if ((_failed_tests == 0)); then
    diag "${GREEN}[SUCCESS]${NC} - Now download the images."
else
    diag "${RED}[FAIL]${NC} - Problems found. Check output."
fi
diag "${HR}"
