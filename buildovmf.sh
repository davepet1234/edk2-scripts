#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petrovic
# GitHub: https://github.com/davepet1234/edk2-scripts
#
################################################################################

# Script to build the EDK2 OVMF Package for use with a VM

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script to build the EDK2 OVMF Package for use with a VM
 
 OPTIONS:

  -f, --force            No prompts
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
    -f|--force)
        FORCE=1
        shift # past argument
        ;;
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
check_edk2_workspace

user_confirm "Build OVMF" ${FORCE}
if [ $? -ne 0 ]; then
    print_warn "Aborted by user"
    exit 2
fi

# always build using gcc compiler as clang fails!
cd ${WORKSPACE}
build -p OvmfPkg/OvmfPkgX64.dsc -b NOOPT -t GCC
retval=$?

if [ $retval -eq 0 ]; then
    print_info "Build Successful"
    find . -iname OVMF*.fd -exec ls -la {} \;
else
    print_err "Build Failed"
fi

exit ${retval}
