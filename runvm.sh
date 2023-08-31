#!/bin/bash

################################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petroivc
# GitHub: https://github.com/davepet1234/edk2-scripts
#
################################################################################

# Script to run EDK2 VM

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"
SERIAL=0
LOGGING=0
LOGFILE="serial.log"
ADD_SW=""

# Override hang on "Guest has not initialised ther display (yet)." when launching VM.
# See https://github.com/tianocore/edk2/commit/bf5678b5802685e07583e3c7ec56d883cbdd5da3
# Thanks to Damian for finding this solution.
QEMU_HANG_OVERRIDE="-fw_cfg name=opt/org.tianocore/X-Cpuhp-Bugcheck-Override,string=yes"

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script run EDK2 virtual machine
 
 Usage: ${PROGRAM_NAME} [OPTIONS]

 OPTIONS:

  -s, --serial           Enable serial output (console)
  -l, --log <file>       Capture serial otput to log file (implies --serial option)
                         <file> is optional, default is "${LOGFILE}".
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
    -s|--serial)
        SERIAL=1
        shift # past argument
        ;;
    -l|--log)
        LOGGING=1
        if [[ $2 ]] && [[ ! $2 == -* ]]; then
            LOGFILE="$2"
            shift # past argument
        fi
        print_info "Log file: ${LOGFILE}"
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

#ps -C ${QEMM} >/dev/null
lsof ${WORKSPACE}/${VM_FOLDER}/${DISK_IMAGE_FILENAME}
if [ $? -eq 0 ]; then
    print_err "VM already running"
    exit 1
fi
if [ ${SERIAL} -eq 1 ] && [ ${LOGGING} -eq 0 ]; then
    ADD_SW="-serial stdio"
elif [ ${LOGGING} -eq 1 ]; then
    ADD_SW="-chardev stdio,id=char0,logfile=${LOGFILE},signal=off -serial chardev:char0"
fi
cd ${WORKSPACE}/${VM_FOLDER}
${QEMM} -cpu qemu64\
                    -name "$(basename ${WORKSPACE})"\
                    -m 1024M\
                    ${QEMU_HANG_OVERRIDE}\
                    -drive if=pflash,format=raw,unit=0,file=OVMF_CODE.fd,readonly=on\
                    -drive if=pflash,format=raw,unit=1,file=OVMF_VARS.fd\
                    -drive format=raw,file=${DISK_IMAGE_FILENAME},if=virtio\
                    ${ADD_SW} &

exit 0
