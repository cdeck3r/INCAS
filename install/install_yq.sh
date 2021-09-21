#!/bin/bash
set -e -u

#
# Install yq - a lightweight and portable command-line YAML processor.
# https://github.com/mikefarah/yq
#
# yq is required for reading and writing INCAS config.yml
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
VERSION="v4.13.2"
BINARY="yq_linux_arm"
YQ_URL="https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}"

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

# install system-wide as root
# download and set exec permissions
sudo -s -- <<EOF
wget "${YQ_URL}" -O /usr/bin/yq && chmod +x /usr/bin/yq
EOF

# test installation
command -v "yq" >/dev/null 2>&1 || {
    echo >&2 "I require yq but it's not installed. Abort."
    exit 1
}

TEST_YAML="/tmp/file.yaml"
touch "${TEST_YAML}"
RET=$(yq e '.a.b[0].c' "${TEST_YAML}")
[[ "$RET" = "null" ]] || {
    "ERROR: yq e '.a.b[0].c'"
    exit 2
}
yq e -i '.a.b[0].c = "cool"' "${TEST_YAML}" || {
    "ERROR: yq e -i '.a.b[0].c = cool'"
    exit 2
}
RET=$(yq e '.a.b[0].c' "${TEST_YAML}")
[[ "$RET" = "cool" ]] || {
    "ERROR: yq e '.a.b[0].c'"
    exit 2
}

rm -rf "${TEST_YAML}"
echo "${SCRIPT_NAME}: Installation complete. All tests successful."
exit 0
