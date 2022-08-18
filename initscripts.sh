#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petrovic
#
################################################################################

# Script to setup environment for EDK2 utility scripts

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script to setup environment for EDK2 utility scripts
 
 Usage: source ${PROGRAM_NAME}

EOF
    echo -e " \033[97;41mNote that script must be \"sourced\" not merely executed!\033[0m" >&2
    echo
    exit 1
}

################################################################################
# main

# check if script sourced
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    print_help
    exit 1
fi

# set script location
PROGRAM_NAME="${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}"
PROGRAM_DIR="$(cd "$(dirname "${PROGRAM_NAME}")"; pwd;)"
export EDK2_SCRIPTS=${PROGRAM_DIR}
# only configure path if not already present
if [[ "${PATH}" != *"${PROGRAM_DIR}"* ]]; then
    export PATH=${PATH}:${PROGRAM_DIR}
fi
echo -e "\033[96m[INFORMATION] EDK2_SCRIPTS: ${EDK2_SCRIPTS}\033[0m"
