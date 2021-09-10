#!/bin/bash
set -e -u

#
# Install the script-server UI as user service
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
: "${INCAS_DIR}"
: "${LOG_DIR}"

# variables
SERVICE_UNIT_DIR="${USER_HOME}/.config/systemd/user"
SCRIPT_SERVER_USER_DIR="${INCAS_DIR}/script-server"
SERVICE_UNIT_FILE="script_server.service"

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

#
# install script-server UI; run as ${USER}
# 1. Download and cp script-server in "${SCRIPT_SERVER_USER_DIR}"
# 2. enable the service start at boot
# 3. install service
#
rm -rf "${SCRIPT_SERVER_USER_DIR}" # cleanup
# download and copy
wget \
    'https://github.com/bugy/script-server/releases/download/1.16.0/script-server.zip' \
    -O /tmp/script-server.zip -q
# usually in /home/pi
mkdir -p "${SCRIPT_SERVER_USER_DIR}"
unzip -q /tmp/script-server.zip -d "${SCRIPT_SERVER_USER_DIR}"
# cleanup
rm -rf /tmp/script-server.zip
# enable the service start at each Raspi boot-up for the user ${USER}
sudo -s -- <<EOF
loginctl enable-linger "${USER}" || { echo "loginctl enable-linger - error ignored: $?"; }
EOF

# required to run systemctl --user
XDG_RUNTIME_DIR=/run/user/$(id -u)
export XDG_RUNTIME_DIR

# install SERVICE_UNIT_FILE
mkdir -p "${SERVICE_UNIT_DIR}"
# test
FOUND_SERVICE=$(systemctl --user --no-pager --no-legend list-unit-files | grep -c "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; })
echo "Found instances of ${SERVICE_UNIT_FILE} running: ${FOUND_SERVICE}"
# stop / remove
systemctl --user --no-pager --no-legend stop "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; }
systemctl --user --no-pager --no-legend disable "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; }
# (re)place the new service and correct file permissions
cp "${SCRIPT_DIR}/${SERVICE_UNIT_FILE}" "${SERVICE_UNIT_DIR}"
chmod 644 "${SERVICE_UNIT_DIR}/${SERVICE_UNIT_FILE}"
# start and enable new service
systemctl --user daemon-reload || { echo "Error ignored: $?"; }
systemctl --user --no-pager --no-legend start "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; }
systemctl --user --no-pager --no-legend enable "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; }
# we expect the service active
STATE=$(systemctl --user --no-pager --no-legend is-active "${SERVICE_UNIT_FILE}")

if [ "${STATE}" != "active" ]; then
    echo "Service not active: ${SERVICE_UNIT_FILE}"
    exit 2
fi

# create log directory
mkdir -p "${LOG_DIR}"
mkdir -p "${LOG_DIR}/processes_log"

exit 0
