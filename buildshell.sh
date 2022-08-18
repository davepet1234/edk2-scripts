#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petrovic
#
################################################################################

# Script to build the EDK2 Shell Package

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

TARGET=""
CLEAN=0
FORCE=0

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script to build the EDK2 Shell Package
 
 Usage: ${PROGRAM_NAME} [OPTIONS]

 OPTIONS:

  -d, --debug            DEBUG build
  -r, --release          RELEASE build
  -c, --clean            Clean build
  -f, --force            No prompts
  -h, --help             Print this help and exit

EOF
    exit 1
}

################################################################################
# Options parser

if [ $# -eq 0 ]; then
    print_help
fi

while [[ $# -gt 0 ]]
    do
    key="$1"
    case $key in
    -d|--debug)
        TARGET="DEBUG"
        shift # past argument
        ;;
    -r|--release)
        TARGET="RELEASE"
        shift # past argument
        ;;
    -c|--clean)
        CLEAN=1
        shift # past argument
        ;;
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

if [ -z "${TARGET}" ]; then
    # always ask for build type
    #TARGET=$(get_var "${CONF_PATH}/${EDK2_CONFIG_FILENAME}" TARGET)
    print_err "Please specify build type to clean"
    exit 1
fi

if [ ${CLEAN} -eq 1 ]; then
    print_warn "Cleaning Build!"
    user_confirm "Clean ${TARGET} Build" ${FORCE}
    if [ $? -ne 0 ]; then
        print_warn "Aborted by user"
        exit 2
    fi
    CLEAN_OPT="clean"
    ACTION="Clean"
else
    print_info "Performing a ${TARGET} build"
    ACTION="Build"
fi

build ${CLEAN_OPT} -p ShellPkg/ShellPkg.dsc -b ${TARGET}
retval=$?

if [ $retval -ne 0 ]; then
    print_err "${TARGET} ${ACTION} Failed"
    exit ${retval}
fi

print_info "${TARGET} ${ACTION} Successful"

exit ${retval}
