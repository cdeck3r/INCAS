#!/bin/bash
set -e -u

#
# Install INCAS logrotation
#
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
: "${LOG_DIR}"

# variables
LOGROTATE_CONF_INSTALL="${SCRIPT_DIR}/logrotate.conf"
LOGROTATE_LOG="${LOG_DIR}/logrotate.log"
LOGROTATE_STATE="${LOG_DIR}/logrotate.state"

#####################################################
# Include Helper functions
#####################################################

# ...

#####################################################
# Main program
#####################################################

bailout_if_root
check_user || {
    echo "User mismatch. Script must run as user: ${USER}"
    exit 1
}

# create log directory
mkdir -p "${LOG_DIR}"

LOGROTATE_CONF_DIR=$(dirname "${LOGROTATE_CONF}")
[[ -d "${LOGROTATE_CONF_DIR}" ]] || {
    echo "Will create required directory: ${LOGROTATE_CONF_DIR}"
    mkdir -p "${LOGROTATE_CONF_DIR}"
}
sed "s#<<LOG_DIR>>#${LOG_DIR}#" "${LOGROTATE_CONF_INSTALL}" >"${LOGROTATE_CONF}"

# remove existing log rotation from crontab
crontab -l | grep -v "incas_logrotate.conf" | crontab - || { echo "Ignore error: $?"; }

# install daily logrotate cronjob - run each night at 2am
if [ -f "${LOGROTATE_CONF}" ]; then
    (
        crontab -l
        echo "0 2 * * * /usr/sbin/logrotate -s ${LOGROTATE_STATE} -l ${LOGROTATE_LOG} ${LOGROTATE_CONF} >/dev/null 2>&1"
    ) | sort | uniq | crontab - || {
        echo "Error adding cronjob. Code: $?"
        exit 2
    }
else
    echo "File does not exist: ${LOGROTATE_CONF}"
    echo "Could not install logrotate cronjob"
    exit 2
fi

# in any case restart cron
sudo -s -- <<EOF
systemctl restart cron.service
EOF

exit 0
