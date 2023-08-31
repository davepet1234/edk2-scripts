#!/bin/bash

################################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petroivc
# GitHub: https://github.com/davepet1234/edk2-scripts
#
################################################################################

# Common include for EDK2 Utility Scripts

################################################################################
# Automatic/Default parameters

PROGRAM_NAME="$(basename "$0")"
PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
CURRENT_DIR="$(pwd)"

EDKINIT_FILENAME="edkinit.sh"
EDK2_SETUP_FILENAME="edksetup.sh"
EDK2_CONFIG_FILENAME="target.txt"

EDK2_APP_ROOT_FOLDER_RELPATH="ShellPkg/Application"
LIBC_APP_ROOT_FOLDER_RELPATH="edk2-libc/AppPkg/Applications"
EDK2_DSC_FILE_RELPATH="ShellPkg/ShellPkg.dsc"
LIBC_DSC_FILE_RELPATH="edk2-libc/AppPkg/AppPkg.dsc"
EDK2_BUILD_ROOT_RELPATH="Build/Shell"
LIBC_BUILD_ROOT_RELPATH="Build/AppPkg"

VM_FOLDER="vm"
DISK_IMAGE_FILENAME="edkdisk.img"
MOUNT_POINT="/mnt/edkdisk"

BUILD_OUTPUT_FOLDER="Build/Shell/RELEASE_GCC5/X64"

QEMM="qemu-system-x86_64"

################################################################################
# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

################################################################################
# print_err - Prints an error message on the stderr

function print_err {
    echo -e "\033[97;41m[ERROR] $@\033[0m" >&2
}

################################################################################
# print_warn - Prints a warning messagge on the stderr

function print_warn {
    echo -e "\033[93m[WARNING] $@\033[0m" >&2
}

################################################################################
# print_info -Prints a message on the stdout

function print_info {
    echo -e "\033[96m[INFORMATION] $@\033[0m"
}

################################################################################
# get_filepath - Translates a file path to an absolute file path

function get_filepath () {
    local FILEPATH="$1"
    echo "$(cd "$(dirname "${FILEPATH}")"; pwd;)/$(basename "${FILEPATH}")"
}

################################################################################
# get_dirpath - Translates a directory path to an absolute path

function get_dirpath () {
    local DIRPATH="$1"
    echo "$( cd "${DIRPATH}" && pwd )"
}

################################################################################
# valid_filename - Checks for valid characters

function valid_filename () {
    local NAME="$1"
    if ! [[ ${NAME} =~ ^[0-9a-zA-Z._-]+$ ]]; then
        return 1
    fi
    return 0
}

################################################################################
# user_confirm - Asks user for confirmation; prompt $1; force flag $2 (=1)

function user_confirm() {
    if [ -n "$2" ] && [ $2 -eq 1 ]; then
        # forced yes
        return 0
    fi
    echo
    echo -en "\033[37;100m[PROMPT] $1 [y/n]?\033[0m"
    read -n 1 -r </dev/tty
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # yes
        return 0
    fi
    # no
    return 1
}

################################################################################
# ctrl_c() - trap handler

function ctrl_c() {
    echo
    print_err "Execution terminated by user!"
    exit 2
}

################################################################################
# check_script_env - Check if script env set

function check_script_env() {
    if [ -z "${EDK2_SCRIPTS}" ]; then
        print_err "Please source 'initscripts.sh' to setup environment"
        exit 1
    fi
}

################################################################################
# display_var - Display variable

function display_var() {
    local VAR=$1   # variable to display
    if [ -z "${VAR}" ]; then
        echo "<unset>"
    else
        echo "${VAR}"
    fi
}

################################################################################
# check_edk2_workspace - Exit script if not configured or invalid

function check_edk2_workspace() {
    if [ -z "${WORKSPACE}" ]; then
        print_err "EDK2 workspace has not been set!"
        exit 1
    fi
    if [ ! -z ${EDK2_LIBC} ] && [ ${EDK2_LIBC} -eq 1 ]; then
        local FILE_TO_CHECK=${WORKSPACE}/edk2/${EDK2_SETUP_FILENAME}
    else
        local FILE_TO_CHECK=${WORKSPACE}/${EDK2_SETUP_FILENAME}
    fi
    if [ ! -f "${FILE_TO_CHECK}" ]; then
        print_err "Invalid EDK2 workspace, ${EDK2_SETUP_FILENAME} not found!"
        exit 1
    fi
}

################################################################################
# get_app_root_relpath - Get root directory of applications relative to workspace

function get_app_root_relpath() {
    local LIBC=$1   # flag specifying a EDK2+LIBC installation
    if [ ! -z ${LIBC} ] && [ ${LIBC} -eq 1 ]; then
        local RELPATH="${LIBC_APP_ROOT_FOLDER_RELPATH}"
    else
        local RELPATH="${EDK2_APP_ROOT_FOLDER_RELPATH}"
    fi
    echo ${RELPATH}
}

################################################################################
# get_dsc_file_relpath - Get platform file (.dsc) relative to workspace

function get_dsc_file_relpath() {
    local LIBC=$1   # flag specifying a EDK2+LIBC installation
    if [ ! -z ${LIBC} ] && [ ${LIBC} -eq 1 ]; then
        local RELPATH="${LIBC_DSC_FILE_RELPATH}"
    else
        local RELPATH="${EDK2_DSC_FILE_RELPATH}"
    fi
    echo ${RELPATH}
}

################################################################################
# get_build_root_relpath - Get the application build root directoty relative to workspace

function get_build_root_relpath() {
    local LIBC=$1   # flag specifying a EDK2+LIBC installation
    if [ ! -z ${LIBC} ] && [ ${LIBC} -eq 1 ]; then
        local RELPATH="${LIBC_BUILD_ROOT_RELPATH}"
    else
        local RELPATH="${EDK2_BUILD_ROOT_RELPATH}"
    fi
    echo ${RELPATH}
}

################################################################################
# check_vm_dir - Check if VM directory exists

function check_vm_dir() {
    if [ ! -d "${WORKSPACE}/${VM_FOLDER}" ]; then
        print_err "Please initialise VM first"
        exit 1
    fi
}

################################################################################
# get_var - Read variable value from file

function get_var() {
    local FILE=$1
    local VAR_NAME=$2
    if [ ! -f "${FILE}" ]; then
        print_err "${FILE} not found"
        exit 1
    fi
    local COUNT=$(grep -E "^\s*${VAR_NAME}\s*=" ${FILE} | wc -l)
    if [ ${COUNT} -ne 1 ]; then
        print_err "${FILE} contains multiple ${VAR_NAME} definitions"
        exit 1
    fi
    grep -E --color=never -m 1 "^\s*${VAR_NAME}\s*=" ${FILE} | tr -d "\r" | sed 's|.*=\s*\([a-zA-Z0-9]*\)|\1|'
}

################################################################################
# set_var - Set variable value in file

function set_var() {
    local FILE=$1
    local VAR_NAME=$2
    local VAR_VALUE=$3
     if [ ! -f "${FILE}" ]; then
        print_err "${FILE} not found"
        exit 1
    fi
    local COUNT=$(grep -E "^\s*${VAR_NAME}\s*=" ${FILE} | wc -l)
    if [ ${COUNT} -eq 0 ]; then
        return 0
    fi
    if [ ${COUNT} -ne 1 ]; then
        print_err "${FILE} contains multiple ${VAR_NAME} definitions"
        exit 1
    fi
    SED_PARAM="s|\(^\s*${VAR_NAME}\s*=\s*\)\([a-zA-Z0-9\/\._]*\)|\1${VAR_VALUE}|"
    sed -i "${SED_PARAM}" ${FILE}
    #echo "${VAR_NAME} = ${VAR_VALUE}"
    return $?
}

################################################################################
# get_elapsed_time - Prints an elapsed time ($2 - $1) as hours, minutes and secs

function get_elapsed_time() {
    local START_SECONDS=$1
    local END_SECONDS=$2
    local ELAPSED_SECONDS=$(( END_SECONDS - START_SECONDS ))
    local ELAPSED_TIME="TEST"
    local SECONDS_IN_A_MINUTE=60
    local SECONDS_IN_AN_HOUR=$(( SECONDS_IN_A_MINUTE * 60 ))
    local SECONDS_IN_A_DAY=$(( SECONDS_IN_AN_HOUR * 24 ))
    local _HOURS_=0
    local _MINUTES_=0
    local _SECONDS_=0

    _HOURS_=$(( ELAPSED_SECONDS / SECONDS_IN_AN_HOUR ))
    ELAPSED_SECONDS=$(( ELAPSED_SECONDS - (SECONDS_IN_AN_HOUR * _HOURS_) ))
    _MINUTES_=$(( ELAPSED_SECONDS / SECONDS_IN_A_MINUTE ))
    ELAPSED_SECONDS=$(( ELAPSED_SECONDS - (SECONDS_IN_A_MINUTE * _MINUTES_) ))
    _SECONDS_=${ELAPSED_SECONDS}
    ELAPSED_SECONDS=$(( END_SECONDS - START_SECONDS ))
    ELAPSED_TIME="$(printf %02d ${_HOURS_}):$(printf %02d ${_MINUTES_}):$(printf %02d ${_SECONDS_}) (${ELAPSED_SECONDS}s)"

    echo ${ELAPSED_TIME}
}


################################################################################
# get_disk_info - Returns START_SECTOR, END_SECTOR and SECTOR_SZIE for disk image ($1)

function get_disk_info() {
    local FILE=$1
    
    # get start and end sectors
    local buf=$(gdisk -l ${FILE} 2>/dev/null | grep -A1 -i "start (sector)")
    local NUMLINES=$(echo "${buf}" | wc -l)
    if [ ${NUMLINES} -ne 2 ]; then
        return 1
    fi
    local LINE=$(echo "${buf}" | tail -n 1)
    START_SECTOR=$(echo "${LINE}" | awk '{print $2}')
    END_SECTOR=$(echo "${LINE}" | awk '{print $3}')
    # get sector size
    buf=$(gdisk -l ${FILE} 2>/dev/null | grep -i "sector size")
    if [ $? -ne 0 ]; then
        return 1
    fi
    SECTOR_SIZE=$(echo ${buf#*:} | awk '{print $1}')

    return 0
}

################################################################################
# main



