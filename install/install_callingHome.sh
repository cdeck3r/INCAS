#!/bin/bash
set -e -u

#
# Install callingHome script
#
# 1. verify `/boot/incas.ini` exists
# 1. `cp callingHome.sh <INCAS_DIR>`
# 1. remove from crontab and add `callingHome.sh` to crontrab
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

# variables
INCAS_INI="/boot/incas.ini"
CALLHOME_SH="${SCRIPT_DIR}/callingHome.sh"
CALLHOME_SH_FILENAME="$(basename "${CALLHOME_SH}")"

#####################################################
# Include Helper functions
#####################################################

# ..

#####################################################
# Main program
#####################################################

bailout_if_root
check_user || {
    echo "User mismatch. Script must run as user: ${USER}"
    exit 1
}
[[ -f "${INCAS_INI}" ]] || {
    echo "INI file does not exist: ${INCAS_INI}"
    exit 1
}
[[ -f "${CALLHOME_SH}" ]] || {
    echo "Cannot install. File does not exist: ${CALLHOME_SH}"
    exit 1
}

cp "${CALLHOME_SH}" "${INCAS_DIR}"
chmod u+x "${INCAS_DIR}/${CALLHOME_SH_FILENAME}"

# remove existing job from crontab
crontab -l | grep -v "${CALLHOME_SH_FILENAME}" | crontab - || { echo "Ignore error: $?"; }

# install new one - run every hour
(
    crontab -l
    echo "0 * * * * ${INCAS_DIR}/${CALLHOME_SH_FILENAME} >/dev/null 2>&1"
) | sort | uniq | crontab - || {
    echo "Error adding cronjob. Code: $?"
    exit 2
}

# in any case restart cron
sudo -s -- <<EOF
systemctl restart cron.service
EOF

exit 0
