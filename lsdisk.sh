#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petrovic
# GitHub: https://github.com/davepet1234/edk2-scripts
#
################################################################################

# Script to list files on EDK2 VM disk image

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

################################################################################
# main

check_script_env
check_edk2_workspace
check_vm_dir


dpkg -s tree > /dev/null 2>&1
if [ $? -ne 0 ]; then
    print_err "Missing 'tree' package"
    exit 1
fi

DISK_IMAGE_ABSPATH="${WORKSPACE}/${VM_FOLDER}/${DISK_IMAGE_FILENAME}"
if [ ! -f "${DISK_IMAGE_ABSPATH}" ]; then
    print_err "No disk image found"
    exit 1
fi

print_info "Disk image: ${DISK_IMAGE_ABSPATH}"
get_disk_info ${DISK_IMAGE_ABSPATH}
if [ $? -ne 0 ]; then
    print_err "Disk image error"
    exit 1
fi
OFFSET=$(( ${START_SECTOR}*${SECTOR_SIZE} ))

retval=1
sudo mkdir ${MOUNT_POINT}
sudo mount -o loop,offset=${OFFSET} ${DISK_IMAGE_ABSPATH} ${MOUNT_POINT}
if [ $? -eq 0 ]; then
    df ${MOUNT_POINT} -h
    echo
    tree -aD ${MOUNT_POINT}
    sudo umount ${MOUNT_POINT}
    retval=0
else
    print_err "Failed to mount disk"
fi

sudo rmdir ${MOUNT_POINT}

exit ${retval}
