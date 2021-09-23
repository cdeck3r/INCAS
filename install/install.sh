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
MY_HOSTNAME="incas"
MY_TZ="Europe/Berlin" # see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"

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

# Set the system's timezone
# The new one is provided as parameter
set_timezone() {
    local new_tz=$1

    sudo -s -- <<EOF 
timedatectl set-timezone "${new_tz}"
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

cli_log() {
    local msg=$1
    
    echo "---------------------------"
    echo "${msg}"
    echo "---------------------------"
}

#####################################################
# Main program
#####################################################

#
# Initialize raspi
#
cli_log "Set hostname: ${MY_HOSTNAME}"
set_hostname "${MY_HOSTNAME}"

cli_log "Change timezone: ${MY_TZ}"
set_timezone "${MY_TZ}"

#
# INCAS src
#
cli_log "Prepare install"
install_cleanup
mkdir -p "${INCAS_DIR}"

cli_log "Download install files"
# Download repo and extract src and install directory into tmp directory
# filenames are hardcoded by convention
curl -L "${REPO_ZIP}" --output /tmp/incas.zip
[[ -f "/tmp/incas.zip" ]] || {
    echo "File does not exist: /tmp/incas.zip"
    exit 2
}
cli_log "Unzip install files"
unzip /tmp/incas.zip 'INCAS-main/src/*' -d /tmp
unzip /tmp/incas.zip 'INCAS-main/install/*' -d /tmp

cli_log "Remove existing directories"
# Prepare; rm existing directories before copy new ones
# Note: INCAS_DIR/config.yml remains as well as the log directory
find "/tmp/INCAS-main/src" -mindepth 1 -type d -print0 |
    xargs -0 -I {} basename {} |
    xargs -I {} rm -rf "${INCAS_DIR}/{}"

cli_log "Run install scripts"
chmod -R u+x /tmp/INCAS-main/install/*.sh
cli_log "Run install_avahi.sh"
/tmp/INCAS-main/install/install_avahi.sh
cli_log "Run install_nginx.sh"
/tmp/INCAS-main/install/install_nginx.sh
cli_log "Run install_script_server.sh"
/tmp/INCAS-main/install/install_script_server.sh
cli_log "Run install_gallery_shell.sh"
/tmp/INCAS-main/install/install_gallery_shell.sh
cli_log "Run install_yq.sh"
/tmp/INCAS-main/install/install_yq.sh
cli_log "Run install_config.sh"
/tmp/INCAS-main/install/install_config.sh

cli_log "Copy INCAS source files"
cp -R /tmp/INCAS-main/src/* "${INCAS_DIR}"
# adapt the executable flags
find "${INCAS_DIR}" -type f -name "*.sh" -print0 | xargs -0 -I {} chmod u+x {}

#
cli_log "Post-install actions"
#
# we have modified script_server -> configure and restart the service
/tmp/INCAS-main/install/configure_script_server.sh
restart_script_server

cli_log "Install logrotation cron jobs"
/tmp/INCAS-main/install/install_logrotate.sh

# finish
cli_log "Install cleanup"
install_cleanup

exit 0
