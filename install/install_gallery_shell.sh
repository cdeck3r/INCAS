#!/bin/bash
set -e -u

#
# Install gallery_shell - Bash Script to generate static responsive image web galleries. 
# https://github.com/Cyclenerd/gallery_shell
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
GALLERY_SH_DIR="${INCAS_DIR}/gallery_shell"

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
apt-get install -y imagemagick jhead
EOF

# download and set exec permissions
wget \
    'https://raw.githubusercontent.com/Cyclenerd/gallery_shell/master/gallery.sh' \
    -O "${GALLERY_SH_DIR}/gallery.sh"
chmod u+x "${GALLERY_SH_DIR}/gallery.sh"

exit 0
