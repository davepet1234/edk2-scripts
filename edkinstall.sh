#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petrovic
#
################################################################################

# Script to download and configure EDK2 build environment

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

EDK2_REPO_URL="https://github.com/tianocore/edk2.git"
TARGET_DIR=$(basename ${EDK2_REPO_URL} .git)
PARENT_DIR="$PWD"
TAG=""
CLONE_OPTS=""
FORCE=0
CLANG=0

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script to download and configure EDK2 build environment
 
 Usage: ${PROGRAM_NAME} [target dir] [OPTIONS]

  [target dir] - directory to clone into (default: ${TARGET_DIR})

 OPTIONS:

  -p, --parent <dir>     Parent directory to clone into (default: current directory)
  -t, --tag <tag>        GIT tag to clone (default: master)
  -c, --clang            Install for Clang compiler (default: gcc)
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
        print_err "Invalid target directory: $1"
        exit 1
    fi
    TARGET_DIR=$1
    shift # past target directory
fi

while [[ $# -gt 0 ]]
    do
    key="$1"
    case $key in
    -p|--parent)
        PARENT_DIR="$2"
        if [ ! -d "${PARENT_DIR}" ]; then
            print_err "Parent directory does not exist: ${PARENT_DIR}"
            exit 1
        fi
        PARENT_DIR="$( cd "$2" && pwd )"
        shift # past argument
        shift # past value
        ;;
    -t|--tag)
        TAG="$2"
        CLONE_OPTS="--branch ${TAG}"
        shift # past argument
        shift # past value
        ;;
    -c|--clang)
        CLANG=1
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

if [ -n "${WORKSPACE}" ]; then
    print_err "EDK2 workspace already configured: ${WORKSPACE}"
    exit 1
fi

START_SECONDS=$(date +%s)

# determine location
if [ ! -d "${PARENT_DIR}" ]; then
    print_err "Parent directory does not exist"
    exit 1
fi
TARGET_DIR="${PARENT_DIR}/${TARGET_DIR}"
if [ -d "${TARGET_DIR}" ]; then
    print_err "Directory already exists with that name: ${TARGET_DIR}"
    exit 1
fi
print_info "Install directory: ${TARGET_DIR}"
if [ -n "${TAG}" ]; then
    print_info "Clone tag: ${TAG}"
fi
if [ ${CLANG} -eq 1 ]; then
    print_info "Clang compiler"
fi
user_confirm "Continue" ${FORCE}
if [ $? -ne 0 ]; then
    print_warn "Aborted by user"
    exit 1
fi

# clone repo
print_info "Cloning ${TAG}"
cd ${PARENT_DIR}
git clone ${CLONE_OPTS} ${EDK2_REPO_URL} ${TARGET_DIR}
if [ $? -ne 0 ]; then
    print_err "Failed to clone repo"
    exit 1
fi

# switch to repo directory
cd ${TARGET_DIR}

# initialise submodules
print_info "Initialise Submodules"
git submodule update --init
if [ $? -ne 0 ]; then
    print_err "Failed to initialise submodules"
    exit 1
fi

# build BaseTools
print_info "Build BaseTools"
make -C BaseTools
if [ $? -ne 0 ]; then
    print_err "Failed to build BaseTools"
    exit 1
fi

print_info "Initialise Configuration"
source ./${EDK2_SETUP_FILENAME} --reconfig
#CONF_PATH="./Conf"
FILE="${CONF_PATH}/${EDK2_CONFIG_FILENAME}"
set_var ${FILE} ACTIVE_PLATFORM ShellPkg/ShellPkg.dsc
set_var ${FILE} TARGET DEBUG
set_var ${FILE} TARGET_ARCH X64
if [ ${CLANG} -eq 1 ]; then
    set_var ${FILE} TOOL_CHAIN_TAG CLANGPDB
else
    set_var ${FILE} TOOL_CHAIN_TAG GCC5
fi

print_info "Creating: ${EDKINIT_FILENAME}"
######################################
cat << EOF_SCRIPT > ${EDKINIT_FILENAME}
#!/bin/bash

################################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petroivc
#
################################################################################

# Script to initialise EDK2 development environment

INIT_SCRIPTS="${EDK2_SCRIPTS}/initscripts.sh"

# check if script sourced
if [ "\${BASH_SOURCE[0]}" == "\${0}" ]; then
    cat <<EOF

 Script to initialise EDK2 development environment
 
 Usage: source ./edkinit.sh

EOF
    echo -e " \033[97;41mNote that script must be \"sourced\" not merely executed!\033[0m" >&2
    echo
    exit 1
fi

if [ -f "\${INIT_SCRIPTS}" ]; then
    # initialise EDK2 Utility scripts
    source \${INIT_SCRIPTS}
    # initialise EDK2 build enviroment
    if [ -f "./${EDK2_SETUP_FILENAME}" ]; then
        source ./${EDK2_SETUP_FILENAME}
    else
        echo -e "\033[97;41m[ERROR] EDK2 Setup script not found: ./${EDK2_SETUP_FILENAME}\033[0m" >&2
    fi
else    
    echo -e "\033[97;41m[ERROR] EDK2 Utility script not found: \${INIT_SCRIPTS}\033[0m" >&2
fi
unset INIT_SCRIPTS

EOF_SCRIPT
######################################
chmod +x ${EDKINIT_FILENAME}

END_SECONDS=$(date +%s)
print_info "Elapsed time $(get_elapsed_time ${START_SECONDS} ${END_SECONDS})"

print_info "EDK2 Info"
edkinfo.sh

# prompt to setup environment
print_info "Run 'source ${EDKINIT_DST_FILENAME}' from workspace directory to setup environment"

exit 0
