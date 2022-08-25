#!/bin/bash

###############################################################################
#
# EDK2 Utility Scriptss
#
# Author: David Petroivc
#
################################################################################

# Script to update files on EDK2 VM disk image

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

TARGET=""
FILE_TO_COPY=""
FORCE=0
RUNVM=0

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script to update files on EDK2 VM disk image
 
 Usage: ${PROGRAM_NAME} [app name] [OPTIONS]

  [app name] - application name

 OPTIONS:

  -d, --debug            Force copy of DEBUG build
  -r, --release          Force copy of RELEASE build
  -x, --file             Copy specified file instead of app
  -v, --runvm            Run VM after update
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
    -x|--file)
        if [ ! -f "$2" ]; then
            print_err "No such file : $2"
            exit 1
        fi
        FILE_TO_COPY="$(get_filepath "$2")"        
        shift # past argument
        shift # past value
        ;;
    -v|--runvm)
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
check_vm_dir

ps -C ${QEMM} >/dev/null
if [ $? -eq 0 ]; then
    print_err "VM running"
    exit 1
fi

if [ ! -f "${DISK_IMAGE_RELPATH}" ]; then
    print_err "No disk image found: ${DISK_IMAGE_RELPATH}"
    exit ${retval}
fi
print_info "Disk image: $(get_filepath "${DISK_IMAGE_RELPATH}")"

if [ -z "${FILE_TO_COPY}" ]; then

    # copy application
    
    if [ -z "${APP_NAME}" ]; then
        print_err "Please specify application name"
        exit 1
    fi
    NOW_SECS=$(date +%s)

   TOOL_CHAIN_TAG=$(get_var "${CONF_PATH}/${EDK2_CONFIG_FILENAME}" TOOL_CHAIN_TAG)
    if [ -z "${TOOL_CHAIN_TAG}" ]; then
        print_err "Failed to retrive toolchain"
        exit 1
    fi
    BUILD_ROOT_RELPATH=$(get_build_root_relpath ${EDK2_LIBC})
    DBG_BIN="${BUILD_ROOT_RELPATH}/DEBUG_${TOOL_CHAIN_TAG}/X64/${APP_NAME}.efi"
    REL_BIN="${BUILD_ROOT_RELPATH}/RELEASE_${TOOL_CHAIN_TAG}/X64/${APP_NAME}.efi"
    
    # check if app has been built
    if [ ! -f "${DBG_BIN}" ] && [ ! -f "${REL_BIN}" ]; then
        print_err "No builds found"
        exit 1
    fi
    # if debug specified check if present
    if [ "${TARGET}" = "DEBUG" ] && [ ! -f "${DBG_BIN}" ]; then
        print_err "No DEBUG build found"
        exit 1
    fi
    # if release specified check if present
    if [ "${TARGET}" = "RELEASE" ] && [ ! -f "${REL_BIN}" ]; then
        print_err "No RELEASE build found"
        exit 1
    fi
    # display debug and release build info
    # choose newest build if none specified
    if [ -f "${DBG_BIN}" ]; then
        DBG_BIN=$(get_filepath ${DBG_BIN})
        DBG_BIN_DATE=$(date -r ${DBG_BIN} +"%Y-%m-%d %H:%M:%S")
        DBG_BIN_SECS=$(date -r ${DBG_BIN} +"%s")
        if [[ -z ${TARGET} && ${DBG_BIN} -nt ${REL_BIN} ]]; then
            TARGET="DEBUG"
        fi
        echo "DEBUG"
        echo " File: ${DBG_BIN}"
        echo " Date: ${DBG_BIN_DATE} => $(get_elapsed_time ${DBG_BIN_SECS} ${NOW_SECS})"
    fi
    if [ -f "${REL_BIN}" ]; then
        REL_BIN=$(get_filepath ${REL_BIN})
        REL_BIN_DATE=$(date -r ${REL_BIN} +"%Y-%m-%d %H:%M:%S")
        REL_BIN_SECS=$(date -r ${REL_BIN} +"%s")
        if [[ -z ${TARGET} && ${REL_BIN} -nt ${DBG_BIN} ]]; then
            TARGET="RELEASE"
        fi
        echo "RELEASE"
        echo " File: ${REL_BIN}"
        echo " Date: ${REL_BIN_DATE} => $(get_elapsed_time ${REL_BIN_SECS} ${NOW_SECS})"    
    fi

    user_confirm "Update VM with ${TARGET} build" ${FORCE}
    if [ $? -ne 0 ]; then
        print_warn "Aborted by user"
        exit 2
    fi

    if [ "${TARGET}" == "DEBUG" ]; then
        FILE_TO_COPY="${DBG_BIN}"
    else
        FILE_TO_COPY="${REL_BIN}"
    fi
else

    # copy user specific file
    
    user_confirm "Copy file: ${FILE_TO_COPY}" ${FORCE}
    if [ $? -ne 0 ]; then
        print_warn "Aborted by user"
        exit 2
    fi
fi

get_disk_info ${DISK_IMAGE_RELPATH}
if [ $? -ne 0 ]; then
    print_err "Disk image error"
    exit 1
fi
OFFSET=$(( ${START_SECTOR}*${SECTOR_SIZE} ))

retval=1
sudo mkdir ${MOUNT_POINT}
sudo mount -o loop,offset=${OFFSET} ${DISK_IMAGE_RELPATH} ${MOUNT_POINT}
if [ $? -eq 0 ]; then
    if [ ! -f "${FILE_TO_COPY}" ]; then
        print_warn "File not found: ${FILE_TO_COPY}"
    else
        print_info "Copying: ${FILE_TO_COPY}"
        sudo cp --preserve=timestamps ${FILE_TO_COPY} ${MOUNT_POINT}/
    fi
    tree -aD ${MOUNT_POINT}
    sudo umount ${MOUNT_POINT}
    retval=0
else
    print_err "Failed to mount disk"
fi

sudo rmdir ${MOUNT_POINT}

# if successfully copied file then optionally run VM
if [ ${retval} -eq 0 ] && [ ${RUNVM} -eq 1 ]; then
    print_info "Running VM"
    runvm.sh 
    if [ $? -ne 0 ]; then
        print_err "Failed to run VM"
        exit 1
    fi
fi

exit ${retval}
