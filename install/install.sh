#!/bin/bash
set -e

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

[ "$(id -u)" -eq 0 ] && {
    echo "User is root. Please run this script as regular user."
    exit 1
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
install_cleanup() {
    rm -rf /tmp/incas.zip
    rm -rf /tmp/INCAS-main
}

#####################################################
# Main program
#####################################################

#
# INCAS src
#
install_cleanup
mkdir -p "${INCAS_DIR}"

# Download repo and extract src and install directory into tmp directory
curl -L "${REPO_ZIP}" --output /tmp/incas.zip
[[ -f "/tmp/incas.zip" ]] || {
    echo "File does not exist: /tmp/incas.zip"
    exit 2
}
unzip /tmp/incas.zip 'INCAS-main/src/*' -d /tmp
unzip /tmp/incas.zip 'INCAS-main/install/*' -d /tmp

# Run install scripts
chmod -R u+x /tmp/INCAS-main/install/*.sh
/tmp/INCAS-main/install/install_nginx.sh
/tmp/INCAS-main/install/install_script_server.sh

# cp INCAS source files
cp -R /tmp/INCAS-main/src/* "${INCAS_DIR}"
# adapt the executable flags
chmod -R u+x "${INCAS_DIR}"/*.sh

# finally, install logrotation cron jobs
/tmp/INCAS-main/install/install_logrotate.sh

# finish
install_cleanup
