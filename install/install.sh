#!/bin/bash
set -e -u

#
# Install INCAS on the Raspi in ${HOME}/incas
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# 1 - if precond not satisfied
# 2 - if install routing breaks

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0

# variables
REPO_ZIP="https://github.com/cdeck3r/INCAS/archive/main.zip"

USER="$(id --user --name)"
USER_HOME="/home/${USER}"
INCAS_DIR="${USER_HOME}/incas"

#####################################################
# Include Helper functions
#####################################################

# check user is not root
[ "$(id -u)" -eq 0 ] && {
    echo "User is root. Please run this script as regular user."
    exit 1
}

# check we are on Raspi
{
    MACHINE=$(uname -m)
    if [[ "$MACHINE" != arm* ]]; then
        echo "ERROR: We are not on an arm plattform: ${MACHINE}"
        exit 1
    fi
}

# check for installed program
# Source: https://stackoverflow.com/a/677212
command -v "curl" >/dev/null 2>&1 || {
    echo >&2 "I require curl but it's not installed.  Abort."
    exit 1
}
command -v "unzip" >/dev/null 2>&1 || {
    echo >&2 "I require unzip but it's not installed.  Abort."
    exit 1
}
command -v "wget" >/dev/null 2>&1 || {
    echo >&2 "I require wget but it's not installed.  Abort."
    exit 1
}
command -v "sed" >/dev/null 2>&1 || {
    echo >&2 "I require sed but it's not installed.  Abort."
    exit 1
}

# remove install files
# files are hardcoded due to filename convention
install_cleanup() {
    rm -rf /tmp/incas.zip
    rm -rf /tmp/INCAS-main
}

# Set the system's hostname
# The new name is provided as parameter
set_hostname() {
    # src: https://github.com/nmcclain/raspberian-firstboot/blob/master/examples/simple_hostname/firstboot.sh
    local new_name=$1
    local curr_hostname
    curr_hostname=$(hostname)
    # Only root can set system's hostname
    sudo -s -- <<EOF
if [ "${curr_hostname}" != "${new_name}" ]; then
    echo "${new_name}" >/etc/hostname
    sed -i "s/${curr_hostname}/${new_name}/g" /etc/hosts
    hostname "${new_name}"
fi
EOF
}

restart_script_server() {
    # required to run systemctl --user
    XDG_RUNTIME_DIR=/run/user/$(id -u)
    export XDG_RUNTIME_DIR

    SERVICE_UNIT_FILE="script_server.service"
    [[ -f "${SCRIPT_DIR}/${SERVICE_UNIT_FILE}" ]] && {
        systemctl --user --no-pager --no-legend start "${SERVICE_UNIT_FILE}" || { echo "Error ignored: $?"; }
    }
}

#####################################################
# Main program
#####################################################

#
# Initialize raspi
#
set_hostname "incas"

#
# INCAS src
#
install_cleanup
mkdir -p "${INCAS_DIR}"

# Download repo and extract src and install directory into tmp directory
# filenames are hardcoded by convention
curl -L "${REPO_ZIP}" --output /tmp/incas.zip
[[ -f "/tmp/incas.zip" ]] || {
    echo "File does not exist: /tmp/incas.zip"
    exit 2
}
unzip /tmp/incas.zip 'INCAS-main/src/*' -d /tmp
unzip /tmp/incas.zip 'INCAS-main/install/*' -d /tmp

# Prepare; rm existing directories before copy new ones
# Note: INCAS_DIR/config.yml remains as well as the log directory
find "/tmp/INCAS-main/src" -mindepth 1 -type d -print0 |
    xargs -0 -I {} basename {} |
    xargs -I {} rm -rf "${INCAS_DIR}/{}"

# Run install scripts
chmod -R u+x /tmp/INCAS-main/install/*.sh
/tmp/INCAS-main/install/install_avahi.sh
/tmp/INCAS-main/install/install_nginx.sh
/tmp/INCAS-main/install/install_script_server.sh
/tmp/INCAS-main/install/install_gallery_shell.sh
/tmp/INCAS-main/install/install_config.sh

# cp INCAS source files
cp -R /tmp/INCAS-main/src/* "${INCAS_DIR}"
# adapt the executable flags
chmod -R u+x "${INCAS_DIR}"/*.sh
# we have modified script_server config -> restart the service
restart_script_server

# finally, install logrotation cron jobs
/tmp/INCAS-main/install/install_logrotate.sh

# finish
install_cleanup

exit 0
