#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petrovic
# GitHub: https://github.com/davepet1234/edk2-scripts
#
################################################################################

# Script to show current EDK2 build environment

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script to show current EDK2 build environment
 
 Usage: ${PROGRAM_NAME} [OPTIONS]

 OPTIONS:

  -h, --help             Print this help and exit

EOF
    exit 1
}

################################################################################
# Options parser

while [[ $# -gt 0 ]]
    do
    key="$1"
    case $key in
    -h|--help)
        print_help
        exit 1
        ;;
    *)  # unknown option
        print_err "Invalid option: $key"
        exit 1
        ;;
    esac
done

################################################################################
# main

check_script_env

echo "EDK2_SCRIPTS:     $(display_var ${EDK2_SCRIPTS})"
if [ ! -z ${EDK2_LIBC} ] && [ ${EDK2_LIBC} -eq 1 ]; then
    echo "EDK2_LIBC:        $(display_var ${EDK2_LIBC}) (SUPPORTED)"
else
    echo "EDK2_LIBC:        $(display_var ${EDK2_LIBC}) (NO SUPPORT)"
fi
echo "---"

if [ -z "${WORKSPACE}" ]; then
    print_err "EDK2 workspace not set, please source \"${EDKINIT_FILENAME}\"" from workspace directory
    exit 1
fi

echo "WORKSPACE:        $(display_var ${WORKSPACE})"
echo "PACKAGES_PATH:    $(display_var ${PACKAGES_PATH})"
echo "EDK_TOOLS_PATH:   $(display_var ${EDK_TOOLS_PATH})"
echo "CONF_PATH:        $(display_var ${CONF_PATH})"

if [ ! -d "${WORKSPACE}" ]; then
    print_err "Workspace directory does not exist"
    exit 1
fi

if [ ! -z "${CONF_PATH}" ]; then
    FILE="${CONF_PATH}/${EDK2_CONFIG_FILENAME}"
    echo "│"
    echo "├── ACTIVE_PLATFORM = $(get_var ${FILE} ACTIVE_PLATFORM)"
    echo "├── TARGET          = $(get_var ${FILE} TARGET)"
    echo "├── TARGET_ARCH     = $(get_var ${FILE} TARGET_ARCH)"
    echo "└── TOOL_CHAIN_TAG  = $(get_var ${FILE} TOOL_CHAIN_TAG)"
    echo
fi

if [[ ! "$PWD" =~ "${WORKSPACE}" ]]; then
    print_warn "NOT in configured workspace"
fi

exit 0
