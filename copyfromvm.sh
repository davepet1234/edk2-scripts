#!/bin/bash

###############################################################################
#
# EDK2 Utility Scriptss
#
# Author: David Petroivc
# GitHub: https://github.com/davepet1234/edk2-scripts
#
################################################################################

# Script to copy file from EDK2 VM disk image to host

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

FILE_TO_COPY=""
FORCE=0

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script to copy file from EDK2 VM disk image to host
 
 Usage: ${PROGRAM_NAME} [file] [OPTIONS]

  [file] - file on VM disk

 OPTIONS:

  -f, --force            No prompts
  -h, --help             Print this help and exit

EOF
    exit 1
}

################################################################################
# Options parser

if [ -n "$1" ] && [ ! "${1::1}" == "-" ]; then 
    FILE_TO_COPY=$1
    shift # past application name
fi

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
check_vm_dir

if [ -z "${FILE_TO_COPY}" ]; then
    print_err "Please specify file to copy"
    exit 1
fi

HOST_FNAME=$(basename "${FILE_TO_COPY}")
if [ -f "${HOST_FNAME}" ]; then
    user_confirm "Overwrite existing host file: ${HOST_FNAME}" ${FORCE}
    if [ $? -ne 0 ]; then
        print_warn "Aborted by user"
        exit 2
    fi
fi    

DISK_IMAGE_ABSPATH="${WORKSPACE}/${VM_FOLDER}/${DISK_IMAGE_FILENAME}"
#ps -C ${QEMM} >/dev/null
lsof ${DISK_IMAGE_ABSPATH}
if [ $? -eq 0 ]; then
    print_err "VM running"
    exit 1
fi

if [ ! -f "${DISK_IMAGE_ABSPATH}" ]; then
    print_err "No disk image found: ${DISK_IMAGE_ABSPATH}"
    exit ${retval}
fi
print_info "Disk image: ${DISK_IMAGE_ABSPATH}"

get_disk_info "${DISK_IMAGE_ABSPATH}"
if [ $? -ne 0 ]; then
    print_err "Disk image error"
    exit 1
fi
OFFSET=$(( ${START_SECTOR}*${SECTOR_SIZE} ))

retval=1
sudo mkdir ${MOUNT_POINT}
sudo mount -o loop,offset=${OFFSET} ${DISK_IMAGE_ABSPATH} ${MOUNT_POINT}
if [ $? -eq 0 ]; then
    if [ ! -f "${MOUNT_POINT}/${FILE_TO_COPY}" ]; then
        print_err "File not found: ${FILE_TO_COPY}"
    else
        print_info "Copying: ${FILE_TO_COPY}"
        sudo cp --preserve=timestamps ${MOUNT_POINT}/${FILE_TO_COPY} ./
        if [ $? -eq 0 ]; then 
            sudo chown ${USER}:${USER} ${HOST_FNAME}
            retval=0
        else
            print_err "Failed to copy file: ${FILE_TO_COPY}"
        fi
    fi
    sudo umount ${MOUNT_POINT}
else
    print_err "Failed to mount disk"
fi

sudo rmdir ${MOUNT_POINT}

exit ${retval}
