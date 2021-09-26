#!/bin/bash
# shellcheck disable=SC1090

#
# Kill all periodic snapshots jobs
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
SCRIPT_NAME_WO_EXT=$(basename "${SCRIPT_NAME%.*}")

# Vars
TAKEIMG_DIR="${SCRIPT_DIR}/../../takeimg"
TAKE_SNAPSHOT="${TAKEIMG_DIR}/snapshot.sh"
SNAPSHOT_WO_EXT=$(basename "${TAKE_SNAPSHOT%.*}")
KTIMES_STATE="/tmp/ktimes_${SNAPSHOT_WO_EXT}.state"

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
diag "Kill enqueued periodic snapshot jobs"
diag "${HR}"

JOB_QUEUE=$(atq -q s | wc -l)
if [[ "${JOB_QUEUE}" -eq 0 ]]; then
    pass "No queued jobs found."
else
    diag "Found leftover jobs: ${JOB_QUEUE}"
    atrm $(atq -q s | cut -f1) 2>/dev/null
    is $? 0 "Deleting jobs."    
    JOB_QUEUE=$(atq -q s | wc -l)
    is "${JOB_QUEUE}" 0 "No snapshot jobs in queue."
fi

diag " "

diag "${HR}"
diag "Kill running periodic snapshot jobs"
diag "${HR}"

# test job is running
RUNNING_JOB_NUMS=$(atq -q = | cut -f1)
mapfile -t RUNNING_JOB_NUMS_ARRAY < <(echo "${RUNNING_JOB_NUMS}")
if [[ -z "${RUNNING_JOB_NUMS_ARRAY[0]}" ]]; then 
    pass "No running jobs found."
else
    diag "Number of currently running jobs: ${#RUNNING_JOB_NUMS_ARRAY[@]}"
fi
for jobnum in "${RUNNING_JOB_NUMS_ARRAY[@]}"; do
    [ -z "${jobnum}" ] && { continue; }
    at -c "${jobnum}" | tail -2 | xargs | grep "${TAKE_SNAPSHOT}" && {
        okx atrm "${jobnum}"
        okx pkill -f "${TAKE_SNAPSHOT}"
    }
done


diag " "

diag "${HR}"
diag "Cleanup state files"
diag "${HR}"

rm -rf "${KTIMES_STATE}"
okx [ ! -f "${KTIMES_STATE}" ]


# Summary
diag "${HR}"
if ((_failed_tests == 0)); then
    diag "${GREEN}[SUCCESS]${NC} - All done."
else
    diag "${RED}[FAIL]${NC} - Problems found. Check output."
fi
diag "${HR}"
