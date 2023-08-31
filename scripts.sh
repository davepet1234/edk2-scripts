#!/bin/bash

###############################################################################
#
# EDK2 Utility Scripts
#
# Author: David Petroivc
# GitHub: https://github.com/davepet1234/edk2-scripts
#
################################################################################

# Script to list EDK2 utility scripts with brief description

################################################################################
# Automatic/Default parameters

PROGRAM_DIR="$(cd "$(dirname "$0")"; pwd;)"
source "${PROGRAM_DIR}/shared.sh"

################################################################################
# main

    cat <<EOF

EDK2 Utility Scripts

 Script Initialisation

   initscripts.sh    Setup environment for utility scripts

 EDK2 Build Environment and Installation

   edkdep.sh         Check and install dependancies
   edkinstall.sh     Download and configure build environment
   edkinfo.sh        Show current build environment

 Shell Application Tasks
  
   mkapp.sh          Create new shell application
   buildapp.sh       Build a shell application

 Virtual Machine Tasks
  
   initvm.sh         Initialise VM and create disk image
   updatevm.sh       Update files on VM disk image
   lsdisk.sh         List files on VM disk image
  
   runvm.sh          Run VM

 Miscellaneous Tasks

   buildshell.sh     Build the Shell Package
   buildovmf.sh      Build the OVMF Package
  
EOF

exit 0
