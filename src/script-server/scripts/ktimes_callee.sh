#!/bin/bash
# shellcheck disable=SC1090

set -e -u

#
# Test program called by ktimes.sh
#
# Author: cdeck3r
#

# Params: none

# Exit codes
# 0: at the script's end
# 1: if Pre-cond are not fulfilled
# 2: script error
# 255: report end of k times execution to watch

# this directory is the script directory
SCRIPT_DIR="$(
    cd "$(dirname "$0")" || exit
    pwd -P
)"
cd "$SCRIPT_DIR" || exit
# shellcheck disable=SC2034
SCRIPT_NAME=$0
SCRIPT_NAME_WO_EXT=$(basename "${SCRIPT_NAME%.*}")

# Vars
PARAM1="${1:-}"
PARAM2="${2:-}"
ALL_OTHER="${@:3}"

echo "This is: ${SCRIPT_NAME}"
echo " "
echo "Parameters are:"
echo "PARAM1: ${PARAM1}"
echo "PARAM2: ${PARAM2}"
echo "ALL_OTHER: ${ALL_OTHER}"

exit 0

