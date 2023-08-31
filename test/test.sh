#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petrovic
# GitHub: https://github.com/davepet1234/edk2-scripts
#
################################################################################

# Test script for EDK2 Utility Scripts

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
PROGRAM_NAME="$(basename "$0")"
TEST_ROOT_DIR="$(realpath ~/dev/test)"
EDK2_ENABLED=0
LIBC_ENABLED=0
APP_NAME="TestApp"

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
# print_help

function print_help {
    cat <<EOF

 Test script for EDK2 Utility Scripts
 
 Usage: ${PROGRAM_NAME} [OPTIONS]

 OPTIONS:

  -a, --all              Run all tests
      --edk2             Run EDK2 test
      --libc             Run EDK2+LIBC test
  -h, --help             Print this help and exit

EOF
    exit 1
}

################################################################################
# print_error

function print_error {
    echo "========================================================================"
    echo "ERROR: $@"
    echo "========================================================================"
}

################################################################################
# run_test - perform EDK2 installation, then create, build and run application
#
#  TEST_DIR         Parent directory of workspace
#  INSTALL_OPT      Install options
#  EDKINIT_ABSPATH  Absolute path to edkinit.sh script
#  APP_NAME         Name of EFI Shell application to create
#
# Note: Do not pass arguments to this function as it confuses the edksetup.sh script

function run_test {
    edkinstall.sh -p ${TEST_DIR} ${INSTALL_OPT} -f
    if [ $? -ne 0 ];then 
        echo "========================================================================"
        echo "ERROR: Failed to install EDK2!"
        echo "========================================================================"
        exit 1
    fi

    source ${EDKINIT_ABSPATH}
    if [ -z "${WORKSPACE}" ]; then
        print_error "WORKSPACE not configured!"
        exit 1
    fi

    initvm.sh -f
    if [ $? -ne 0 ]; then
        print_error "Failed to initialise VM!"
        exit 1
    fi

    mkapp.sh ${APP_NAME} -f
    if [ $? -ne 0 ]; then
        print_error "Failed to create application!"
        exit 1
    fi

    buildapp.sh ${APP_NAME} -f
    if [ $? -ne 0 ]; then
        print_error "Failed to build application!"
        exit 1
    fi

    updatevm.sh ${APP_NAME} -f
    if [ $? -ne 0 ]; then
        print_error "Failed to update VM!"
        exit 1
    fi

    runvm.sh
    if [ $? -ne 0 ]; then
        print_error "Failed to run VM!"
        exit 1
    fi
}

################################################################################
# Options parser

while [[ $# -gt 0 ]]
    do
    key="$1"
    case $key in
    -a|--all)
        EDK2_ENABLED=1
        LIBC_ENABLED=1
        shift # past argument
        ;;
    --edk2)
        EDK2_ENABLED=1
        shift # past argument
        ;;
    --libc)
        LIBC_ENABLED=1
        shift # past argument
        ;;
    -h|--help)
        print_help
        exit 1
        ;;
    *)  # unknown option
        echo "Invalid option: $key"
        exit 1
        ;;
    esac
done

################################################################################
# main

# check if at least one test selected
if [ ${EDK2_ENABLED} -ne 1 ] && [ ${LIBC_ENABLED} -ne 1 ]; then
    print_help
    exit 1
fi

# check scripts have been initialised
if [ -z "${EDK2_SCRIPTS}" ]; then
    print_error "EDK2_SCRIPTS not configured!"
    exit 1
fi

# create test folder
if [ ! -d "${TEST_ROOT_DIR}" ]; then
    print_error "Test folder does not exist: ${TEST_ROOT_DIR}"
    exit 1
fi
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
TEST_DIR="${TEST_ROOT_DIR}/${TIMESTAMP}"
mkdir "${TEST_DIR}"
if [ $? -ne 0 ]; then
    print_error "Failed to create test directory: ${TEST_DIR}"
    exit 1
fi

# temporarily get sudo privileges 
# Ubuntu default timeout is 15 minutes
echo -e "<<< ENTER SUDO PASSWORD >>>"
sudo -k
sudo whoami
if [ $? -ne 0 ]; then
    print_error "No sudo password given!"
    exit 1
fi

# clear any workspace already set
unset WORKSPACE

# --- start test ---
START_SECONDS=$(date +%s)

edkdep.sh -i -f
if [ $? -ne 0 ];then 
    print_error "Failed dependancy check!"
    exit 1
fi

# EDK2
if [ ${EDK2_ENABLED} -eq 1 ]; then
    EDKINIT_ABSPATH="${TEST_DIR}/edk2/edkinit.sh"
    INSTALL_OPT=""
    run_test
fi

# EDK2 + LIBC
if [ ${LIBC_ENABLED} -eq 1 ]; then
    EDKINIT_ABSPATH="${TEST_DIR}/edk2libc/edkinit.sh"
    INSTALL_OPT="--libc"
    run_test
fi

# --- end test ---
END_SECONDS=$(date +%s)

echo "========================================================================"
echo "SUCCESS"
echo "Test dir: ${TEST_DIR}"
echo "Elapsed time: $(get_elapsed_time ${START_SECONDS} ${END_SECONDS})"
echo "========================================================================"
exit 0