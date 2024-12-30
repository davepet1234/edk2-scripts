#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petrovic
# GitHub: https://github.com/davepet1234/edk2-scripts
#
################################################################################

# Script to download and configure EDK2 build environment

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

EDK2_REPO_URL="https://github.com/tianocore/edk2.git"
LIBC_REPO_URL="https://github.com/tianocore/edk2-libc"
PARENT_DIR="$PWD"
TAG=""
CLONE_OPTS=""
FORCE=0
CLANG=0
LIBC=0

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script to download and configure EDK2 build environment
 
 Usage: ${PROGRAM_NAME} [<workspace>] [OPTIONS]


 OPTIONS:

  <workspace>            The name of a 'new' workspace folder (default: edk2)

  -p, --parent <dir>     Parent directory to clone into (default is current directory)
  -t, --tag <tag>        GIT tag to clone (default: master)
  -c, --clang            Install for Clang compiler (default: gcc)
      --libc             Install EDK2 LIBC (default workspace folder: edk2libc)
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
    WORKSPACE_FOLDER=$1
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
    --libc)
        LIBC=1
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

if [ -z "${WORKSPACE_FOLDER}" ]; then
    if [ ${LIBC} -eq 0 ]; then
        WORKSPACE_FOLDER=$(basename ${EDK2_REPO_URL} .git)
    else
        WORKSPACE_FOLDER="edk2libc"
    fi
fi

################################################################################
# main

check_script_env

# check if EDK2 workspace already set
if [ -n "${WORKSPACE}" ]; then
    print_warn "EDK2 workspace already configured: ${WORKSPACE}"
fi

START_SECONDS=$(date +%s)

# determine location
if [ ! -d "${PARENT_DIR}" ]; then
    print_err "Parent directory does not exist"
    exit 1
fi
WORKSPACE_DIR="${PARENT_DIR}/${WORKSPACE_FOLDER}"
if [ -d "${WORKSPACE_DIR}" ]; then
    print_err "Directory already exists with that name: ${WORKSPACE_DIR}"
    exit 1
fi
print_info "Install directory: ${WORKSPACE_DIR}"
if [ -n "${TAG}" ]; then
    print_info "EDK2 clone tag: ${TAG}"
fi
if [ ${CLANG} -eq 1 ]; then
    print_info "Clang compiler"
fi
if [ ${LIBC} -eq 1 ]; then
    print_info "LIBC support"
fi
user_confirm "Continue" ${FORCE}
if [ $? -ne 0 ]; then
    print_warn "Aborted by user"
    exit 1
fi

# create workspace directory
cd ${PARENT_DIR}
if [ ${LIBC} -eq 0 ]; then
    # workspace directory is same as EDK2 repo
    EDK2_DIR="${WORKSPACE_DIR}"
else
    # workspace directory contains EDK2 and LIBC repos
    mkdir ${WORKSPACE_DIR}
    if [ $? -ne 0 ]; then
        print_err "Failed to create directory: ${WORKSPACE_DIR}"
        exit 1
    fi
    cd ${WORKSPACE_DIR}
    EDK2_DIR="${WORKSPACE_DIR}/$(basename ${EDK2_REPO_URL} .git)"
fi

echo "-------------------------------------------"
echo "WORKSPACE_FOLDER = ${WORKSPACE_FOLDER}"
echo
echo "PARENT_DIR       = ${PARENT_DIR}"
echo "WORKSPACE_DIR    = ${WORKSPACE_DIR}"
echo "EDK2_DIR         = ${EDK2_DIR}"
echo "-------------------------------------------"

# clone EDK2 repo
print_info "Cloning EDK2 ${TAG}"
git clone ${CLONE_OPTS} ${EDK2_REPO_URL} ${EDK2_DIR}
if [ $? -ne 0 ]; then
    print_err "Failed to clone repo"
    exit 1
fi

# clone EDK2-LIBC repo
if [ ${LIBC} -eq 1 ]; then
    print_info "Cloning EDK2-LIBC ${TAG}"
    git clone ${CLONE_OPTS} ${LIBC_REPO_URL}
    if [ $? -ne 0 ]; then
        print_err "Failed to clone repo"
        exit 1
    fi
fi

# switch to EDK2 repo directory
cd ${EDK2_DIR}

# initialise EDK2 submodules
print_info "Initialise EDK2 Submodules"
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

# initialise EDK2 configuration
print_info "Initialise EDK2 Configuration"
cd ${WORKSPACE_DIR}
unset WORKSPACE
unset PACKAGES_PATH
unset EDK_TOOLS_PATH
unset CONF_PATH
if [ ${LIBC} -eq 0 ]; then
    source ./${EDK2_SETUP_FILENAME} --reconfig
else
    export WORKSPACE=${WORKSPACE_DIR}
    export PACKAGES_PATH="${WORKSPACE}/edk2-libc:${WORKSPACE}/edk2"
    export EDK_TOOLS_PATH="${WORKSPACE}/edk2/BaseTools"
    source ./edk2/${EDK2_SETUP_FILENAME} --reconfig
fi
export EDK2_LIBC=${LIBC}    
FILE="${CONF_PATH}/${EDK2_CONFIG_FILENAME}"
set_var ${FILE} ACTIVE_PLATFORM ShellPkg/ShellPkg.dsc
set_var ${FILE} TARGET DEBUG
set_var ${FILE} TARGET_ARCH X64
if [ ${CLANG} -eq 1 ]; then
    set_var ${FILE} TOOL_CHAIN_TAG CLANGPDB
else
    set_var ${FILE} TOOL_CHAIN_TAG GCC
fi

# create script to initialise environment in root of workspace
print_info "Creating: ${EDKINIT_FILENAME}"
if [ ${LIBC} -eq 0 ]; then
    DEV_ENV="EDK2"
    SETUP_SCRIPT="\${WORKSPACE_DIR}/${EDK2_SETUP_FILENAME}"
else
    DEV_ENV="EDK2+LIBC"
    SETUP_SCRIPT="\${WORKSPACE_DIR}/edk2/${EDK2_SETUP_FILENAME}"
fi
######################################
cat << EOF_SCRIPT > ${EDKINIT_FILENAME}
#!/bin/bash

################################################################################
#
# EDK2 Utility Scripts
#
# Script to initialise ${DEV_ENV} development environment
#
# Created: $(date)
#
# Author: David Petroivc
#
################################################################################

INIT_SCRIPTS="${EDK2_SCRIPTS}/initscripts.sh"
WORKSPACE_DIR="${WORKSPACE_DIR}"

# check if script sourced
if [ "\${BASH_SOURCE[0]}" == "\${0}" ]; then
    cat <<EOF

 Script to initialise ${DEV_ENV} development environment
 
 Usage: source ./edkinit.sh

EOF
    echo -e " \033[97;41mNote that script must be \"sourced\" not merely executed!\033[0m" >&2
    echo
    exit 1
fi

# initialise EDK2 Utility scripts
if [ -f "\${INIT_SCRIPTS}" ]; then
    source \${INIT_SCRIPTS}    
    # initialise EDK2 build enviroment
    if [ -f "${SETUP_SCRIPT}" ]; then
        pushd \${WORKSPACE_DIR} # > /dev/null 2>&1
EOF_SCRIPT
######################################
# EDK2
if [ ${LIBC} -eq 0 ]; then
cat << EOF_SCRIPT >> ${EDKINIT_FILENAME}
        unset WORKSPACE
        unset PACKAGES_PATH
        unset EDK_TOOLS_PATH
        unset CONF_PATH
EOF_SCRIPT
else
######################################
# EDK2+LIBC
cat << EOF_SCRIPT >> ${EDKINIT_FILENAME}
        export WORKSPACE=\${PWD}
        export PACKAGES_PATH="\${WORKSPACE}/edk2-libc:\${WORKSPACE}/edk2"
        unset EDK_TOOLS_PATH
        unset CONF_PATH
EOF_SCRIPT
fi
######################################
cat << EOF_SCRIPT >> ${EDKINIT_FILENAME}
        source ${SETUP_SCRIPT}
        export EDK2_LIBC=${LIBC}
        popd # > /dev/null 2>&1
    else
        echo -e "\033[97;41m[ERROR] EDK2 Setup script not found: ${SETUP_SCRIPT}\033[0m" >&2
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
print_info "Run 'source ${EDKINIT_FILENAME}' from workspace directory to setup environment"

exit 0
