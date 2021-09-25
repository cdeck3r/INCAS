#!/bin/bash
# shellcheck disable=SC1090

#
# Performs various checks and determines the system status.
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
CALIBRATE_DIR="${SCRIPT_DIR}/../../calibrate"
CALIBRATE="${CALIBRATE_DIR}/calibrate.sh"
CONF="${SCRIPT_DIR}/../../config.yml"

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
diag "Script checks"
diag "${HR}"

okx [ -f "${TAKE_SNAPSHOT}" ]
okx [ -x "${TAKE_SNAPSHOT}" ]
okx [ -f "${CALIBRATE}" ]
okx [ -x "${CALIBRATE}" ]


diag " "

diag "${HR}"
diag "Check snapshot jobs"
diag "${HR}"

QCHECK_CMD="atq -q s"
QCHECK_CMD_RES=$(${QCHECK_CMD} | wc -l)
is $? 0 "Check at queue for snapshot jobs"

is "${QCHECK_CMD_RES}" 0 "Running or schedulued jobs: ${QCHECK_CMD_RES}"

STATE_FILE="/tmp/ktimes_snapshot.state"
if [[ ${QCHECK_CMD_RES} -eq 0 ]]; then
    [ -f "${STATE_FILE}" ]
    isnt $? 0 "File must not exist, if queue is empty: ${STATE_FILE}"
fi

diag " "

diag "${HR}"
diag "Logfiles"
diag "${HR}"

LOG_DIR=$(yq e '.log_dir' "${CONF}")
while IFS= read -r -d '' file
do
    [ -f "${file}" ]
    is $? 0 "Logfile: ${file}"
done < <(find "${LOG_DIR}" -type f -name "*.log" -print0)


diag " "

diag "${HR}"
diag "Image Storage"
diag "${HR}"

WWW_IMG_DIR=$(yq e '.www-images' "${CONF}")
okx [ -d "${WWW_IMG_DIR}" ]

SCAN_IMG_CMD="find ${WWW_IMG_DIR} -type f -name *.jpg"
SCAN_IMG_CMD_RES=$(${SCAN_IMG_CMD} | wc -l)
is $? 0 "Scan directory for images: ${WWW_IMG_DIR}"
isnt "${SCAN_IMG_CMD_RES}" 0 "Found images: ${SCAN_IMG_CMD_RES}"

diag " "

# check file sizes
# files less than 100 bytes indicate there was an error during snapshot
while IFS= read -r -d '' file
do
    filesize=$(stat -c%s "$file")
    [ ${filesize} -gt 100 ]
    is $? 0 "Image: ${file}"
done < <( find "${WWW_IMG_DIR}" -type f -name "*.jpg" -print0 )

diag " "

STORAGE_CMD_RES=$(du -sh "${WWW_IMG_DIR}")
is $? 0 "Check storage: ${STORAGE_CMD_RES}"


# Summary
diag "${HR}"
if ((_failed_tests == 0)); then
    diag "${GREEN}[SUCCESS]${NC} - Check done"
else
    diag "${RED}[FAIL]${NC} - Problems found. Check output."
fi
diag "${HR}"
