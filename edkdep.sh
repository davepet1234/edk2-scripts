#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petrovic
#
################################################################################

# Script to check and install EDK2 dependancies

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

# EDK2
# gcc-5
# acpica-tools instead of iasl
EDK2_PACKAGES="git build-essential uuid-dev acpica-tools git nasm python3-distutils qemu-system-x86 tree"
PYTHON_EXECUTABLE=python3
# Clang
CLANG_VERSION="11"
LLVM_COMPILER_PACKAGE="clang"
LLVM_LINKER_PACKAGE="lld"
LLVM_COMPILE_CMD="clang"
LLVM_LIBTOOL_CMD="llvm-lib"
LLVM_RCTOOL_CMD="llvm-rc"
LLVM_LINK_CMD="lld-link"
CLANG_PACKAGES="${LLVM_COMPILER_PACKAGE}-${CLANG_VERSION} ${LLVM_LINKER_PACKAGE}-${CLANG_VERSION}"
PROG_DIR="/usr/bin"
LLVM_SYMLNKS="${PROG_DIR}/${LLVM_COMPILE_CMD} ${PROG_DIR}/${LLVM_LIBTOOL_CMD} ${PROG_DIR}/${LLVM_RCTOOL_CMD} ${PROG_DIR}/${LLVM_LINK_CMD}"

INSTALL=0
CLANG=0
LIST=0
FORCE=0

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script to check and install EDK2 dependancies
 
 Usage: ${PROGRAM_NAME} [OPTIONS]

 OPTIONS:

  -i, --install          Install packages
  -c, --clang            Install optional clang compiler/linker
  -l, --list             List packages
  -f, --force            No prompts
  -h, --help             Print this help and exit

EOF
    exit 1
}

################################################################################
# Options parser

if [[ $# -eq 0 ]]; then
    print_help
    exit 1
fi

while [[ $# -gt 0 ]]
    do
    key="$1"
    case $key in
    -i|--install)
        INSTALL=1
        shift # past argument
        ;;
    -c|--clang)
        CLANG=1
        shift # past argument
        ;;
    -l|--list)
        LIST=1
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

# EDK2 or Clang
if [[ ${CLANG} -eq 1 ]]; then
    PACKAGE_LIST="${CLANG_PACKAGES}"
    echo "Clang Packages"
else
    echo "EDK2 Packages"
    PACKAGE_LIST="${EDK2_PACKAGES}"
fi

# list packages
if [[ ${LIST} -eq 1 ]]; then
    print_info "Package list"
    count=1
    for pkg in ${PACKAGE_LIST}; do
        echo  "  (${count}) ${pkg}"
        let "count=count+1"
    done
    exit 0
fi

# exit if install not specified
if [[ ${INSTALL} -ne 1 ]]; then
    exit 1
fi

# check if packages installed
declare -a pkglist
for pkg in ${PACKAGE_LIST}; do
    dpkg -s ${pkg} > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        pkglst+=(${pkg})
    fi
done
numpkgs=${#pkglst[@]}
if [ ${numpkgs} -eq 0 ]; then
    # all packages present
    print_info "All required packages installed"
else
    # install missing packages
    print_info "${numpkgs} package(s) missing:"
    count=1
    for pkg in ${pkglst[@]}; do
        echo  "(${count}) ${pkg}"
        let "count=count+1"
    done
    user_confirm "Install missing packages?" ${FORCE}
    if [ $? -ne 0 ]; then
        print_warn "User aborted"
        exit 1
    fi
    for pkg in ${pkglst[@]}; do
        print_info "Installing package: ${pkg}"
        if [[ "${pkg}" = "${LLVM_COMPILER_PACKAGE}-${CLANG_VERSION}" ]]; then
            install_opt="--install-suggests"
        else
            install_opt=""
        fi
        sudo apt-get -y install ${pkg} ${install_opt}
        if [ $? -ne 0 ]; then
            print_err "Failed to install package: ${pkg}"
            exit 1
        fi
    done
fi

# python check
which python > /dev/null
if [ $? -ne 0 ]; then
    which ${PYTHON_EXECUTABLE} > /dev/null
    if [ $? -ne 0 ]; then
        print_err "Failed to find ${PYTHON_EXECUTABLE} executable"
        exit 1
    else
    	PYTHON_LOC=$(which ${PYTHON_EXECUTABLE})
        print_info "Creating python symbolic link: ${PYTHON_LOC}"
        sudo ln -s ${PYTHON_LOC} /usr/bin/python
        if [ $? -ne 0 ]; then
            print_err "Failed to create symbolic link to: ${PYTHON_EXECUTABLE}"    
            exit 1
        fi
    fi
else
    PYTHON_LOC=$(which python)
    print_info "Python present: ${PYTHON_LOC}"
fi

# Clang symbolic links
if [[ ${CLANG} -eq 1 ]]; then
    # check links
    misslnk=0
    for lnk in ${LLVM_SYMLNKS}; do
        if [ ! -e "${lnk}" ]; then
            misslnk=1
        fi
    done
    if [ ${misslnk} -eq 0 ]; then
        print_info "All symbolic links present"
        exit 0
    fi
    # create links
    user_confirm "Install missing symbolic links?" ${FORCE}
    if [ $? -ne 0 ]; then
        print_warn "User aborted"
        exit 1
    fi
    print_info "Creating symbolic links"
    for lnk in ${LLVM_SYMLNKS}; do
        if [ ! -e "${lnk}" ]; then
            sudo ln -s ${lnk}-${CLANG_VERSION} ${lnk}
            if [ $? -ne 0 ]; then
                print_err "Failed to create symbolic link: ${lnk}"
                exit 1
            else
                ls --color=tty -l ${lnk}
            fi
        fi
    done
fi

exit 0
