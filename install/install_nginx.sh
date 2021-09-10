#!/bin/bash
set -e -u

#
# Install and configure nginx for INCAS
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

# variables
NGINX_CONF="${SCRIPT_DIR}/incas_nginx.conf"
NGINX_ROOT="${INCAS_DIR}/www-images"

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

# install / update system software
# nginx
sudo -s -- <<EOF
apt-get update
apt-get install -y nginx
EOF

# create root, configure and restart nginx
#
# create root
mkdir -p "${NGINX_ROOT}"
chmod 755 "${NGINX_ROOT}"
# ... configure and restart nginx
sudo -s -- <<EOF
sed "s#<<NGINX_ROOT>>#${NGINX_ROOT}#" "${NGINX_CONF}" > /etc/nginx/sites-available/default
chmod 644 /etc/nginx/sites-available/default
chown root:root /etc/nginx/sites-available/default
systemctl restart nginx
EOF

exit 0
