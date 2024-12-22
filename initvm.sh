#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petrovic
# GitHub: https://github.com/davepet1234/edk2-scripts
#
################################################################################

# Script to initialise EDK2 VM and create disk image

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

STARTUP_SCRIPT="${PROGRAM_DIR}/startup.nsh"
DEFAULT_DISK_SIZE=50
MIN_DISK_SIZE=35
NEW_DISK=0

# align partition on 1MiB boundary
###DEFAULT_START_SECTOR=2048
###GPT_HDR_NUM_SECTORS=34
DEFAULT_SECTOR_SIZE=512
ONE_MEGABYTE=1048576

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script to initialise VM and create disk image for EDK2
 
 Usage: ${PROGRAM_NAME} [OPTIONS]

 OPTIONS:
 
  -s, --size <n>         Size of disk image in MB (default: ${DEFAULT_DISK_SIZE}MB)
  -n, --newdisk          Overwrite existing disk image
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
    -s|--size)
        DISK_SIZE=$2
        if [ "${DISK_SIZE}" -lt "${MIN_DISK_SIZE}" ]; then
            print_err "Disk size specified is too small"
            exit 1
        fi
        shift # past argument
        shift # past value
        ;;    
    -n|--newdisk)
        NEW_DISK=1
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

#################################################################################
# main

check_script_env
check_edk2_workspace

VM_FOLDER_ABSPATH="${WORKSPACE}/${VM_FOLDER}"
DISK_IMAGE_ABSPATH="${VM_FOLDER_ABSPATH}/${DISK_IMAGE_FILENAME}"
if [ -f "${DISK_IMAGE_ABSPATH}" ]; then
    print_warn "VM already exists"
    user_confirm "Overwrite existing VM files" ${FORCE}
    if [ $? -ne 0 ]; then
        print_warn "Aborted by user"
        exit 1
    fi
else
    user_confirm "Create VM" ${FORCE}
    if [ $? -ne 0 ]; then
        print_warn "Aborted by user"
        exit 2
    fi
fi

# create VM folder
if [ ! -d "${VM_FOLDER_ABSPATH}" ]; then
    mkdir "${VM_FOLDER_ABSPATH}"
    if [ $? -ne 0 ]; then
        print_err "Failed to create directory: ${VM_FOLDER_ABSPATH}"
        exit 1
    fi
fi

# build OVMF and copy to VM folder
OVMF_CODE_FD="${WORKSPACE}/Build/OvmfX64/NOOPT_GCC5/FV/OVMF_CODE.fd"
OVMF_VARS_FD="${WORKSPACE}/Build/OvmfX64/NOOPT_GCC5/FV/OVMF_VARS.fd"
if [ -f "${OVMF_CODE_FD}" ] && [ -f "${OVMF_VARS_FD}" ]; then
    print_info "Using existing OVMF build"
else
    user_confirm "Build OVMF" ${FORCE}
    if [ $? -ne 0 ]; then
        print_warn "Aborted by user"
        exit 2
    fi
    buildovmf.sh -f
    if [ $? -ne 0 ]; then
        print_err "Failed to build the OVMF Package files"
        exit 1
    fi
    if [ ! -f "${OVMF_CODE_FD}" ] || [ ! -f "${OVMF_VARS_FD}" ]; then
        print_err "Failed to find required OVMF files"
        exit 1
    fi
fi
echo ${OVMF_CODE_FD}
echo ${OVMF_VARS_FD}
cp ${OVMF_CODE_FD} ${VM_FOLDER_ABSPATH}
cp ${OVMF_VARS_FD} ${VM_FOLDER_ABSPATH}

# create disk
if [ ! -f ${DISK_IMAGE_ABSPATH} ] || [ ${NEW_DISK} -eq 1 ]; then

    if [ -f "${DISK_IMAGE_ABSPATH}" ]; then
        print_warn "Disk image already exists"
        user_confirm "Overwrite existing disk image" ${FORCE}
        if [ $? -ne 0 ]; then
            print_warn "Aborted by user"
            exit 1
        fi
    fi

    # build EFI Shell and copy to VM folder
    TOOL_CHAIN_TAG=$(get_var "${CONF_PATH}/${EDK2_CONFIG_FILENAME}" TOOL_CHAIN_TAG)
    if [ -z "${TOOL_CHAIN_TAG}" ]; then
        print_err "Failed to retrive toolchain"
        exit 1
    fi
    EFI_SHELL=${WORKSPACE}/Build/Shell/RELEASE_${TOOL_CHAIN_TAG}/X64/Shell_EA4BB293-2D7F-4456-A681-1F22F42CD0BC.efi
    if [ -f "${EFI_SHELL}" ]; then
        print_info "Using existing EFI Shell build"
        echo ${EFI_SHELL}
    else
        user_confirm "Build EFI Shell" ${FORCE}
        if [ $? -ne 0 ]; then
            print_warn "Aborted by user"
            exit 2
        fi
        buildshell.sh -r -f
        if [ $? -ne 0 ]; then
            print_err "Failed to build the EFI Shell"
            exit 1
        fi
        if [ -! f "${EFI_SHELL}" ]; then
            print_err "EFI Shell file not found: ${EFI_SHELL}"
            exit 1
        fi
    fi

    # create disk image
    if [ -z "${DISK_SIZE}" ]; then
        DISK_SIZE=${DEFAULT_DISK_SIZE}
    fi
    TOTAL_SECTORS=$(( (${DISK_SIZE}*ONE_MEGABYTE)/${DEFAULT_SECTOR_SIZE} ))
    dd if=/dev/zero of=${DISK_IMAGE_ABSPATH} bs=${DEFAULT_SECTOR_SIZE} count=${TOTAL_SECTORS}
    if [ $? -ne 0 ]; then
        print_err "Failed to create disk image"
        exit 1
    fi

    ###END_SECTOR=$((  ${TOTAL_SECTORS}-${GPT_HDR_NUM_SECTORS} ))
    (
    echo o                        # Create a new empty GPT
    echo y                        # Confirm
    echo n                        # Add a new partition
    echo                          # Partition number (default: 1)
    ##echo 1
    echo                          # First sector (default: 2048)
    ###echo ${DEFAULT_START_SECTOR}
    echo                          # Last sector (default)
    ###echo ${END_SECTOR}
    echo ef00                     # Parition type (EFI system partition)
    echo w                        # Write changes
    echo y                        # Confirm
    ) | sudo gdisk ${DISK_IMAGE_ABSPATH}

    get_disk_info ${DISK_IMAGE_ABSPATH}

    OFFSET=$(( ${START_SECTOR}*${SECTOR_SIZE} ))
    SIZE_LIMIT=$(( (${END_SECTOR}-${START_SECTOR}+1)*${SECTOR_SIZE} ))
    ###OFFSET=$(( ${DEFAULT_START_SECTOR}*${DEFAULT_SECTOR_SIZE} ))
    ###SIZE_LIMIT=$(( (${END_SECTOR}-${DEFAULT_START_SECTOR}+1)*${DEFAULT_SECTOR_SIZE} ))
    ###echo ${OFFSET} ${SIZE_LIMIT}
    LOOP_DEV=$(sudo losetup --find --show --offset ${OFFSET} --sizelimit ${SIZE_LIMIT} ${DISK_IMAGE_ABSPATH})
    if [ $? -ne 0 ]; then
        print_err "Failed to setup loop device"
        exit 1
    fi
    echo ${LOOP_DEV}

    # format disk
    sudo mkdosfs -F 32 ${LOOP_DEV}
    if [ $? -ne 0 ]; then
        print_err "Failed to format disk image"
        exit 1
    fi

    # copy files to disk
    sudo mkdir ${MOUNT_POINT}
    sudo mount ${LOOP_DEV} ${MOUNT_POINT}
    if [ $? -eq 0 ]; then
        sudo mkdir -p ${MOUNT_POINT}/EFI/Boot
        sudo cp ${EFI_SHELL} ${MOUNT_POINT}/EFI/boot/bootx64.efi
        if [ $? -ne 0 ]; then
            print_warn "Missing boot file: ${EFI_SHELL}"
        fi
        sudo cp ${STARTUP_SCRIPT} ${MOUNT_POINT}/EFI/boot/
        if [ $? -ne 0 ]; then
            print_warn "Missing startup script: ${STARTUP_SCRIPT}"
        fi
        sudo umount ${MOUNT_POINT}
    else
        print_err "ERROR: Failed to mount disk"
    fi

    sudo rmdir ${MOUNT_POINT}
    sudo losetup -d ${LOOP_DEV}

    if [ -f "${DISK_IMAGE_ABSPATH}" ]; then
        print_info "Successfully created disk image"
        print_info "Disk image: $(get_filepath "${DISK_IMAGE_ABSPATH}")"
    else
        print_err "Failed to create disk image"
        exit 1
    fi

fi # end disk creation

exit 0
