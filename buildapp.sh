#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petrovic
#
################################################################################

# Script to build EDK2 shell application

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

APP_NAME=""
TARGET=""
CLEAN=0
FORCE=0
UPDATEVM=0
RUNVM=0
ACTION_TEXT="Build"

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script to build EDK2 shell application
 
 Usage: ${PROGRAM_NAME} [app name] [OPTIONS]

  [app name] - application name

 OPTIONS:

  -d, --debug            Force DEBUG build
  -r, --release          Force RELEASE build
  -c, --clean            Clean build
  -u, --updatevm         Update VM after build
  -v, --runvm            Run VM after build, (implies '--updatevm' option)
  -f, --force            No prompts
  -h, --help             Print this help and exit

EOF
    exit 1
}

################################################################################
# Options parser

if [ -n "$1" ] && [ ! "${1::1}" == "-" ]; then 
    valid_filename $1
    if [ $? -ne 0 ]; then
        print_err "Invalid app name: $1"
        exit 1
    fi
    APP_NAME=$1
    shift # past application name
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
    -u|--updatevm)
        UPDATEVM=1
        shift # past argument
        ;;
    -v|--runvm)
        UPDATEVM=1
        RUNVM=1
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

if [ -z "${APP_NAME}" ]; then
    print_err "Please specify application name"
    exit 1
fi

APP_ROOT_FOLDER_RELPATH=$(get_app_root_relpath ${EDK2_LIBC})
DSC_FILE_RELPATH=$(get_dsc_file_relpath ${EDK2_LIBC})

if [ ! -d "${APP_ROOT_FOLDER_RELPATH}/${APP_NAME}" ]; then
    print_err "Application directory does not exist: ${APP_ROOT_FOLDER_RELPATH}/${APP_NAME}"
    exit 1
fi
INF_FILE="${APP_ROOT_FOLDER_RELPATH}/${APP_NAME}/${APP_NAME}.inf"
if [ ! -f "${INF_FILE}" ]; then
    print_err "Missing INF file: ${INF_FILE}"
    exit 1
fi

if [ -z "${TARGET}" ]; then
    TARGET=$(get_var "${CONF_PATH}/${EDK2_CONFIG_FILENAME}" TARGET)
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

build ${CLEAN_OPT} -p ${DSC_FILE_RELPATH} -b ${TARGET} -m ${INF_FILE}
retval=$?

if [ $retval -ne 0 ]; then
    print_err "${TARGET} ${ACTION} Failed"
    exit ${retval}
fi

print_info "${TARGET} ${ACTION} Successful"

# update and run VM if we didn't just do a clean
if [ ${CLEAN} -eq 1 ]; then
    exit ${retval}
fi
if [ ${UPDATEVM} -eq 1 ]; then
    if [ ${FORCE} -eq 1 ]; then
        ADD_SW="-f"
    fi
    updatevm.sh ${APP_NAME} ${ADD_SW}
    if [ $? -ne 0 ]; then
        print_err "Failed to update VM"
        exit 1
    fi
fi
if [ ${RUNVM} -eq 1 ]; then
    runvm.sh
    if [ $? -ne 0 ]; then
        print_err "Failed to run VM"
        exit 1
    fi
fi

exit ${retval}
