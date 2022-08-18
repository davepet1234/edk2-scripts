#!/bin/bash

################################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petroivc
#
################################################################################

# Script to initialise EDK2 environment prior to build

################################################################################
# Automatic/Default parameters

EDK2_UTIL_SCRIPTS_DIR=""

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script to initialise EDK2 environment prior to build
 
 Usage: source ./edkinit.sh

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

pushd ${EDK2_UTIL_SCRIPTS_DIR} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "\033[97;41m[ERROR] Location of EDK2 Utility Scripts not configured\033[0m" >&2
else    
    # initialise EDK2 Utility scripts
    source ./initscripts.sh
    popd > /dev/null 2>&1
    # initialise EDK2 build enviroment
    source ./edksetup.sh
fi
