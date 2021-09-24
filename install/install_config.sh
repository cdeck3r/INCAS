#!/bin/bash
set -e -u

#
# Configure INCAS
# Write a config file with default values.
# It initially generates a password for the incas user taking snapshots.
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
# one may pass a password on the command line
INCAS_PASS=${1-}
INCAS_USER="incas"
CONF="${INCAS_DIR}/config.yml"
NGINX_CONF="/etc/nginx/sites-available/default"

#####################################################
# Include Helper functions
#####################################################

command -v "yq" >/dev/null 2>&1 || {
    echo >&2 "I require yq but it's not installed.  Abort."
    exit 1
}

# source: https://www.howtogeek.com/howto/30184/10-ways-to-generate-a-random-password-from-the-command-line/
randpw() {
    local len="${1:-16}"
    tr </dev/urandom -dc '1234567890qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c"${len}"
}

get_nginx_root() {
    local nginx_root

    nginx_root="$(grep -E '^\s*root' "${NGINX_CONF}" | xargs | cut -d' ' -f2 | cut -d';' -f1 | xargs)"
    echo "${nginx_root}"
}

key_in_conf() {
    local key=$1
    local haskey res

    haskey=".[] | has(\"${key}\")"
    mapfile -t yq_res < <(yq e "${haskey}" "${CONF}")
    
    # we return successfull, if we find one true result
    for res in "${yq_res[@]}"; do
        #echo "Res: ${res}"
        [[ "${res}" == "true" ]] && { return 0; }
    done
    return 1
}

add_update_conf() {
    local key=$1
    local val=$2

    # ensure val is always a string
    keyval=".${key} = strenv(val)"
    val="${val}" yq e -i "${keyval}" "${CONF}"
}

#####################################################
# Main program
#####################################################

bailout_if_root
check_user || {
    echo "User mismatch. Script must run as user: ${USER}"
    exit 1
}

[[ -f "${NGINX_CONF}" ]] || {
    echo "nginx conf does not exist: ${NGINX_CONF}"
    exit 1
}

touch "${CONF}"

# define
# - www-images
# - log_dir
# - incas_user
NGINX_ROOT=$(get_nginx_root)

add_update_conf "www-images" "${NGINX_ROOT}"
add_update_conf "log_dir" "${LOG_DIR}"
add_update_conf "cameras.incas_user" "${INCAS_USER}"

# if INCAS_PASS provided:
# - add/update
# else
# - if incas_pass not in CONF:
#   - generate password
#   - add/update
#   else
#   - do nothing ... remain password as it is

if [[ ! -z "${INCAS_PASS}" ]]; then
    add_update_conf "cameras.incas_pass" "${INCAS_PASS}"
elif ! key_in_conf "incas_pass"; then
    # generate pass
    INCAS_PASS="$(randpw "")"
    add_update_conf "cameras.incas_pass" "${INCAS_PASS}"
fi

exit 0
