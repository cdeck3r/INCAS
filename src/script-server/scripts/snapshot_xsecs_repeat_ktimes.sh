#!/bin/bash
# shellcheck disable=SC1090

#
# All configured cameras take a snapshot. 
# - every x seconds
# - repeat this action k times
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
XSECS=${1:-}
KTIMES=${2:-}
IMG_DIRNAME=${3:-}
KTIMES_SH="${SCRIPT_DIR}/ktimes.sh"
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
    true
    echo $?
)
precheck "${SKIP_CHECK}"

diag "${HR}"
diag "Prepare"
diag "${HR}"

# check given params
# XSECS; KTIMES; IMG_DIRNAME

# nyi: Param check by script-server

# if state file ${KTIMES_STATE} does not exist, remove all jobs
# check jobs in at's s queue; 
# - expect none
# - else: BAIL_OUT "Queued or running jobs found. Abort."

[ ! -f "${KTIMES_STATE}" ] && { atrm $(atq -q s | cut -f1) 2>/dev/null; }

JOB_QUEUE=$(atq -q s | wc -l)
[[ "${JOB_QUEUE}" -eq 0 ]] || { BAIL_OUT "Queued jobs found. Abort."; }
RUNNING_JOB_NUMS=$(atq -q = | cut -f1)
mapfile -t RUNNING_JOB_NUMS_ARRAY < <(echo "${RUNNING_JOB_NUMS}")
for jobnum in "${RUNNING_JOB_NUMS_ARRAY[@]}"; do
    [ -z "${jobnum}" ] && { continue; }
    at -c "${jobnum}" | tail -2 | xargs | grep "${TAKE_SNAPSHOT}" && {
        if [ ! -f "${KTIMES_STATE}" ]; then
            # running job with no state file
            # job hangs probably, so delete it
            diag "Orphaned job found. Delete job: ${jobnum}"
            okx atrm "${jobnum}"
        else
            # running job with state file: don't touch
            BAIL_OUT "Running job found. Job number: ${jobnum}. Abort.";
        fi
    }
done

# required scripts
okx [ -f "${TAKE_SNAPSHOT}" ]
okx [ -x "${TAKE_SNAPSHOT}" ]
okx [ -f "${KTIMES_SH}" ]
okx [ -x "${KTIMES_SH}" ]
# at this point there should be no state file and no job in snapshot queue
okx [ ! -f "${KTIMES_STATE}" ]
JOB_QUEUE=$(atq -q s | wc -l)
is "${JOB_QUEUE}" 0 "No jobs in at's snapshot queue"

diag " "

diag "${HR}"
diag "Schedule periodic snapshots"
diag "${HR}"

# at -q s now
#  - watch -e -t -n ${XSECS} ${KTIMES_SH} ${KTIMES} ${TAKE_SNAPSHOT} ${IMG_DIRNAME}
# test job in at's s queue

ATCMD="bash -c 'TERM=linux watch -e -t -n ${XSECS} ${KTIMES_SH} ${KTIMES} ${TAKE_SNAPSHOT} ${IMG_DIRNAME}'"
diag "Schedule and start job command: "
diag "${ATCMD}"
# Enqueue to at 
# "-q s" refers to queue s
# "-M" never send e-mail to user (remove for debugging)
# "now" start right now
at -M -q s now <<END
${ATCMD}
END
is $? 0 "Job scheduled"
# test job is running
RUNNING_JOB_NUMS=$(atq -q = | cut -f1)
mapfile -t RUNNING_JOB_NUMS_ARRAY < <(echo "${RUNNING_JOB_NUMS}")
for jobnum in "${RUNNING_JOB_NUMS_ARRAY[@]}"; do
    at -c "${jobnum}" | tail -2 | xargs | grep "${TAKE_SNAPSHOT}" && {
        pass "Periodic snapshot running as job no: ${jobnum}"
    }
done

# Summary
diag " "
diag "${HR}"
if ((_failed_tests == 0)); then
    diag "${GREEN}[SUCCESS]${NC} - Periodic snapshots: every ${XSECS} seconds and repeat ${KTIMES} times."
else
    diag "${RED}[FAIL]${NC} - Problems found. Check output."
fi
diag "${HR}"
