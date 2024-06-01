#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petrovic
# GitHub: https://github.com/davepet1234/edk2-scripts
#
################################################################################

# Script to create a new EDK2 shell application

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

APP_ROOT_FOLDER_RELPATH=$(get_app_root_relpath ${EDK2_LIBC})
DSC_FILE_RELPATH=$(get_dsc_file_relpath ${EDK2_LIBC})
APP_NAME=""
LIBC_APP=${EDK2_LIBC}
GUID="$(uuidgen)"
FORCE=0

################################################################################
# print_help

function print_help {
    cat <<EOF

 Script to create a new EDK2 shell application
 
 Application will be created under "${APP_ROOT_FOLDER_RELPATH}/..."
 Application .inf file will be added to "${DSC_FILE_RELPATH}"
 
 Usage: ${PROGRAM_NAME} <app name> [OPTIONS]

  <app name> - application name

 OPTIONS:

      --edk2             Force creation of an EDK2 native application
      --libc             Force creation of a StdLib application
  -f, --force            No prompts
  -h, --help             Print this help and exit

EOF
    exit 1
}

################################################################################
# Options parser

if [ $# -eq 0 ]; then
    print_help
fi
if [ ! "${1::1}" == "-" ]; then 
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
    --edk2)
        LIBC_APP=0
        shift # past argument
        ;;
    --libc)
        if [ ! -z ${EDK2_LIBC} ] && [ ${EDK2_LIBC} -eq 1 ]; then
            LIBC_APP=1
        else
            print_err "Workspace does not support LIBC appliactions"
            exit 1
        fi
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

if [ -z "${APP_NAME}" ]; then
    print_err "Please specify application name"
    exit 1
fi

APP_ROOT_FOLDER_ABSPATH="${WORKSPACE}/${APP_ROOT_FOLDER_RELPATH}"
APP_FOLDER_ABSPATH="${APP_ROOT_FOLDER_ABSPATH}/${APP_NAME}"
if [ -d "${APP_FOLDER_ABSPATH}" ]; then
    print_err "Application already exists: ${APP_FOLDER_ABSPATH}"
    exit 1
fi
APP_C_FILE_ABSPATH="${APP_FOLDER_ABSPATH}/${APP_NAME}.c"
APP_INF_FILE_ABSPATH="${APP_FOLDER_ABSPATH}/${APP_NAME}.inf"
APP_INF_FILE_RELPATH="${APP_ROOT_FOLDER_RELPATH}/${APP_NAME}/${APP_NAME}.inf"
DSC_FILE_ABSPATH="${WORKSPACE}/${DSC_FILE_RELPATH}"

if [ ${LIBC_APP} -eq 1 ]; then
    print_info "Creating an EDK2 + LIBC application"
else
    print_info "Creating an EDK2 application"
fi

echo "Files to be created:"
echo "${APP_C_FILE_ABSPATH}"
echo "${APP_INF_FILE_ABSPATH}"
echo "Files to be modified:"
echo "${DSC_FILE_ABSPATH}"

user_confirm "Continue" ${FORCE}
if [ $? -ne 0 ]; then
    print_warn "Aborted by user"
    exit ${retval}
fi

mkdir ${APP_FOLDER_ABSPATH}
if [ $? -ne 0 ]; then
    print_err "Failed to create application directory: ${APP_FOLDER_ABSPATH}"
    exit 1
fi

print_info "Creating: ${APP_C_FILE_ABSPATH}"

if [ ${LIBC_APP} -eq 1 ]; then
######################################
cat << EOF > ${APP_C_FILE_ABSPATH}
/**

 ${APP_NAME}.c

**/

#include <stdio.h>

int main(IN int Argc, IN char **Argv)
{
    printf("${APP_NAME} application (LibC)\n");

    return 0;
}
EOF
######################################
else
######################################
cat << EOF > ${APP_C_FILE_ABSPATH}
/**

 ${APP_NAME}.c

**/

#include <Uefi.h>
#include <Library/UefiLib.h>
#include <Library/ShellCEntryLib.h>

INTN EFIAPI ShellAppMain(IN UINTN Argc, IN CHAR16 **Argv)
{
    Print(L"${APP_NAME} application\n");

    return 0;
}
EOF
######################################
fi

print_info "Creating: ${APP_INF_FILE_ABSPATH}"

if [ ${LIBC_APP} -eq 1 ]; then
######################################
cat << EOF >> ${APP_INF_FILE_ABSPATH}
##
#
# ${APP_NAME}.inf
#
##

[Defines]
  INF_VERSION                    = 0x00010006
  BASE_NAME                      = ${APP_NAME}
  FILE_GUID                      = ${GUID}
  MODULE_TYPE                    = UEFI_APPLICATION
  VERSION_STRING                 = 1.0
  ENTRY_POINT                    = ShellCEntryLib

[Sources]
  ${APP_NAME}.c

[Packages]
  StdLib/StdLib.dec
  MdePkg/MdePkg.dec
  ShellPkg/ShellPkg.dec

[LibraryClasses]
  LibC
  LibStdio
EOF
######################################
else
######################################
cat << EOF > ${APP_INF_FILE_ABSPATH}
##
#
# ${APP_NAME}.inf
#
##

[Defines]
  INF_VERSION                    = 0x00010006
  BASE_NAME                      = ${APP_NAME}
  FILE_GUID                      = ${GUID}
  MODULE_TYPE                    = UEFI_APPLICATION
  VERSION_STRING                 = 1.0
  ENTRY_POINT                    = ShellCEntryLib

[Sources]
  ${APP_NAME}.c

[Packages]
  MdePkg/MdePkg.dec
  ShellPkg/ShellPkg.dec

[LibraryClasses]
  UefiLib
  ShellCEntryLib
EOF
######################################
fi

print_info "Modifying: ${DSC_FILE_ABSPATH}"
dscfile "${DSC_FILE_ABSPATH}" "${APP_INF_FILE_RELPATH}" -a
if [ $? -ne 0 ]; then
    print_err "Failed to add application inf to: ${DSC_FILE_ABSPATH}"
    exit 1
fi

exit 0
