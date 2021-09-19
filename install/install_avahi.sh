#!/bin/bash
set -e -u

#
# Publish ssh service via avahi
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
SSH_SERVICE_FILE="/etc/avahi/services/ssh.service"

#####################################################
# Include Helper functions
#####################################################

# Ensure avahi-daemon is installed
# By default, the raspian image contains the avahi-daemon
install_avahi() {
    avahi_active=$(systemctl --no-pager is-active avahi-daemon.service)
    if [[ "${avahi_active}" != "active" ]]; then
        sudo -s -- <<EOF
apt-get update
apt-get install -y avahi-daemon
EOF
    fi
}

#####################################################
# Main program
#####################################################

bailout_if_root
check_user || {
    echo "User mismatch. Script must run as user: ${USER}"
    exit 1
}

# install / update system software
install_avahi
sudo -s -- <<EOF
apt-get update
apt-get install -y arp-scan avahi-utils
EOF

# publish SSH service via avahi
tmp_service_file="/tmp/ssh.service"

cat <<EOF >"${tmp_service_file}"
<service-group>

  <name replace-wildcards="yes">%h</name>

  <service>
    <type>_ssh._tcp</type>
    <port>22</port>
  </service>

</service-group>
EOF

# copy, change permissions, restart
# (Only root can do it)
sudo -s -- <<EOF
cp "${tmp_service_file}" "${SSH_SERVICE_FILE}"
chmod 644 "${SSH_SERVICE_FILE}"
systemctl restart avahi-daemon.service
EOF

# cleanup
rm -rf "${tmp_service_file}"

exit 0
