# shellcheck disable=SC2148

#
# INCAS
# Common variable and function definitions
#
# Author: cdeck3r
#

# shellcheck disable=SC2034
USER="$(id --user --name)"
USER_HOME="/home/${USER}"
INCAS_DIR="${USER_HOME}/incas"
LOG_DIR="${INCAS_DIR}/log"
LOGROTATE_CONF="${INCAS_DIR}/incas_logrotate.conf"

# verfies the script runs as ${USER}
bailout_if_root() {
    [ "$(id -u)" -eq 0 ] && {
        echo "User is root. Please run this script as regular user."
        exit 1
    }
}

check_user() {
    local CURR_USER

    bailout_if_root

    CURR_USER=$(id --user --name)
    if [ "${CURR_USER}" != "${USER}" ]; then
        return 1
    fi

    return 0
}
