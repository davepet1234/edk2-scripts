#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petrovic
# GitHub: https://github.com/davepet1234/edk2-scripts
#
################################################################################

# Script to setup environment for EDK2 utility scripts

# check if script sourced
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    cat <<EOF

 Script to setup environment for EDK2 utility scripts
 
 Usage: source ./initscripts.sh

EOF
    echo -e " \033[97;41mNote that script must be \"sourced\" not merely executed!\033[0m" >&2
    echo
    exit 1
fi

# set script location
export EDK2_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd;)"
# only configure path if not already present
if [[ "${PATH}" != *"${EDK2_SCRIPTS}"* ]]; then
    export PATH=${PATH}:${EDK2_SCRIPTS}
fi
echo -e "\033[96m[INFORMATION] EDK2_SCRIPTS: ${EDK2_SCRIPTS}\033[0m"

