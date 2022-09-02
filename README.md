# EDK2 Utility Scripts

These Linux scripts were created to ease development of EFI Shell applications and were tested under Ubuntu 22.04 LTS.

# Getting Started

## First Time Setup

First create a suitable directory to store the files.

```
$ cd ~/
$ mkdir dev
$ cd dev
```

Clone and then setup the environment for EDK2 utility scripts.

```
$ git clone https://github.com/davepet1234/edk2-scripts.git
$ cd edk2-scripts
$ source ./initscripts.sh
```

You will then need to check and install EDK2 dependancies required for build.

```
$ ./edkdep.sh -i
```

Download and configure EDK2 build environment, this will create an `edk2` workspace under the current directory.

```
$ cd ~/dev
$ edkinstall.sh
$ cd edk2
$ source ./edkinit.sh
```

Initialise VM and create disk image from which to store the EFI shell applications.

```
$ initvm.sh
```

You should now have an environemnt to build and run EFI shell applications. 

## Creating and Running an EFI Shell application

You will first need to initialise the build enviroment, if not already done so.

```
$ cd ~/dev/edk2
$ source ./edkinit.sh
```

Create a EFI Shell application called `TestApp`.

```
$ mkapp.sh TestApp
```

This will automatically create the following application files under the `edk2` directory.

```
ShellPkg/Application/TestApp/TestApp.c
ShellPkg/Application/TestApp/TestApp.inf
```

The `TestApp.inf` file will also be added to the to the `[Components]` section of the `ShellPkg.dsc` file so it will be built.

Build the shell application.

```
$ buildapp.sh TestApp
```

Copy shell application to VM disk image.

```
$ updatevm.sh TestApp
```

Run the VM so you can execute your EFI Shell application.

```
$ runvm.sh
```

From the VM, listing the files on disk should show the `TestApp.efi` executable.

```
FS0:\> dir
```

Run your application.

```
FS0:\> TestApp.efi
TestApp application
```

![edk2-scripts](/screenshots/Ubuntu.png?raw=true "Ubuntu")

## Getting Help

Running `scripts.sh` will list all available scripts.

```
$ ./scripts.sh

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
```

You can then get help on any script using the `-h` switch, e.g.

```
$ buildapp.sh -h

 Script to build EDK2 shell application

 Usage: buildapp.sh [app name] [OPTIONS]

  [app name] - application name

 OPTIONS:

  -d, --debug            Force DEBUG build
  -r, --release          Force RELEASE build
  -c, --clean            Clean build
  -u, --updatevm         Update VM after build
  -v, --runvm            Run VM after build, (implies '--updatevm' option)
  -f, --force            No prompts
  -h, --help             Print this help and exit
```

# Script Usage

## Script Initialisation

The `initscripts.sh` script will setup the environemnt for running the scripts, it simply sets the `EDK2_SCRIPTS` variable and adds the scripts location to the `PATH` variable. The script must be sourced and not merely executed, e.g.

```
$ source ./initscripts.sh 
[INFORMATION] EDK2_SCRIPTS: /home/dave/dev/edk2-scripts
```

## EDK2 Dependacies

The `edkdep.sh` script will check your Linux installation for the required packages, use the `-i` switch to install them.

```
$ edkdep.sh -i
EDK2 Packages
[INFORMATION] 9 package(s) missing:
  (1) git
  (2) build-essential
  (3) uuid-dev
  (4) acpica-tools
  (5) git
  (6) nasm
  (7) python3-distutils
  (8) qemu-system-x86
  (9) tree

[PROMPT] Install missing packages? [y/n]
```

In addition to the above packages a `python` symolic link is created to the currently installed python executable.

## EDK2 Installation

The `edkinstall.sh` script will clone the required EDK2 files and setup the build enironment.

```
$ edkinstall.sh -h

 Script to download and configure EDK2 build environment
 
 Usage: edkinstall.sh [<workspace>] [OPTIONS]

 OPTIONS:

  <workspace>            The name of a 'new' workspace folder

  -p, --parent <dir>     Parent directory to clone into (default is current directory)
  -t, --tag <tag>        GIT tag to clone (default: master)
  -c, --clang            Install for Clang compiler (default: gcc)
      --libc             Install EDK2 LIBC
  -f, --force            No prompts
  -h, --help             Print this help and exit
```

By default running the script with no options will install the [edk2](https://github.com/tianocore/edk2) package into an `edk2` folder in the current directory, this will be your workspace. If this is not what you want you can use a different name instead by specifying the `<workspace>`.

LIBC is also supported by specifying the `--libc` option. In this instance the default workspace name will be `edk2libc` and both the [edk2](https://github.com/tianocore/edk2) and [edk2-libc](https://github.com/tianocore/edk2-libc) packages are cloned into this workspace.

Once the required packages are cloned into your workspace the build tools are built before the default build options are set in the `Conf/target.txt` file. i.e.

```
ACTIVE_PLATFORM       = ShellPkg/ShellPkg.dsc
TARGET                = DEBUG
TARGET_ARCH           = X64
TOOL_CHAIN_TAG        = GCC5
```

Finally an `edkinit.sh` script is created in the workspace root, this is to setup your environment.

## Workspace Initialisation

The `edkinit.sh` script is created in the workspace root during EDK2 installation, this is to setup your environment and must be sourced pior to startig any work.

```
$ source ./edkinit.sh
```

This sets up a path to the EDK2 scripts and runs the `edksetup.sh` script to initialise the EDK2 build environment.

## Creating Application

The `mkapp.sh` will create a new shell application and update the appropriate files to add it to the ShellPkg.

```
$ mkapp.sh -h

 Script to create a new EDK2 shell application
 
 Application will be created under "ShellPkg/Application/..."
 Application .inf file will be added to "ShellPkg/ShellPkg.dsc"
 
 Usage: mkapp.sh <app name> [OPTIONS]

  <app name> - application name

 OPTIONS:

      --edk2             Force creation of an EDK2 native application
      --libc             Force creation of a StdLib application
  -f, --force            No prompts
  -h, --help             Print this help and exit
```

The `<app name>` must be specified which will specify the name of the directory and associated files that are created.

### EDK2 Application

Below is an example of creating a "TestApp" application:

```
$ mkapp.sh TestApp
[INFORMATION] Creating an EDK2 application
Files to be created:
/home/dave/dev/edk2/ShellPkg/Application/TestApp/TestApp.c
/home/dave/dev/edk2/ShellPkg/Application/TestApp/TestApp.inf
Files to be modified:
/home/dave/dev/edk2/ShellPkg/ShellPkg.dsc

[PROMPT] Continue [y/n]?y
[INFORMATION] Creating: /home/dave/dev/edk2/ShellPkg/Application/TestApp/TestApp.c
[INFORMATION] Creating: /home/dave/dev/edk2/ShellPkg/Application/TestApp/TestApp.inf
[INFORMATION] Modifying: /home/dave/dev/edk2/ShellPkg/ShellPkg.dsc
Filename: /home/dave/dev/edk2/ShellPkg/ShellPkg.dsc
String  : "ShellPkg/Application/TestApp/TestApp.inf"
ADD[ 158]:   ShellPkg/Application/TestApp/TestApp.inf
```

The source for application is as follows

```
/**

 TestApp.c

**/

#include  <Uefi.h>
#include  <Library/UefiLib.h>
#include  <Library/ShellCEntryLib.h>

INTN
EFIAPI
ShellAppMain (
  IN UINTN Argc,
  IN CHAR16 **Argv
  )
{
  Print(L"TestApp application\n");

  return 0;
}
```

While the `inf` file is shown below. Note that a new GUID is generated for each application created.

```
##
#
# TestApp.inf
#
##

[Defines]
  INF_VERSION                    = 0x00010006
  BASE_NAME                      = TestApp
  FILE_GUID                      = 314384a4-c6bd-4ed0-8edb-f93e697d7a6f
  MODULE_TYPE                    = UEFI_APPLICATION
  VERSION_STRING                 = 1.0
  ENTRY_POINT                    = ShellCEntryLib

[Sources]
  TestApp.c

[Packages]
  MdePkg/MdePkg.dec
  ShellPkg/ShellPkg.dec

[LibraryClasses]
  UefiLib
  ShellCEntryLib
```

### EDK2+LIBC application

Note that for a LIBC install the location is as follows:

```
 Application will be created under "edk2-libc/AppPkg/Applications/..."
 Application .inf file will be added to "edk2-libc/AppPkg/AppPkg.dsc"
```

By default this will a StdLib application for an EDK2+LIBC install, however this can be forced to be a native EDK2 application by using the `--edk2` switch if needed.

Below is an example of creating a "TestApp" application and the contents of the resultant files.

```
$ mkapp.sh TestApp
[INFORMATION] Creating an EDK2 + LIBC application
Files to be created:
/home/dave/dev/edk2libc/edk2-libc/AppPkg/Applications/TestApp/TestApp.c
/home/dave/dev/edk2libc/edk2-libc/AppPkg/Applications/TestApp/TestApp.inf
Files to be modified:
/home/dave/dev/edk2libc/edk2-libc/AppPkg/AppPkg.dsc

[PROMPT] Continue [y/n]?y
[INFORMATION] Creating: /home/dave/dev/edk2libc/edk2-libc/AppPkg/Applications/TestApp/TestApp.c
[INFORMATION] Creating: /home/dave/dev/edk2libc/edk2-libc/AppPkg/Applications/TestApp/TestApp.inf
[INFORMATION] Modifying: /home/dave/dev/edk2libc/edk2-libc/AppPkg/AppPkg.dsc
Filename: /home/dave/dev/edk2libc/edk2-libc/AppPkg/AppPkg.dsc
String  : "edk2-libc/AppPkg/Applications/TestApp/TestApp.inf"
ADD[ 147]:   edk2-libc/AppPkg/Applications/TestApp/TestApp.inf
```

```
/**

 TestApp.c

**/

#include  <stdio.h>

int
main (
  IN int Argc,
  IN char **Argv
  )
{
  printf("TestApp application (LibC)\n");

  return 0;
}
```

```
##
#
# TestApp.inf
#
##

[Defines]
  INF_VERSION                    = 0x00010006
  BASE_NAME                      = TestApp
  FILE_GUID                      = cc6ecc4b-1aa9-4ada-962c-ad32c4dcf51c
  MODULE_TYPE                    = UEFI_APPLICATION
  VERSION_STRING                 = 1.0
  ENTRY_POINT                    = ShellCEntryLib

[Sources]
  TestApp.c

[Packages]
  StdLib/StdLib.dec
  MdePkg/MdePkg.dec
  ShellPkg/ShellPkg.dec

[LibraryClasses]
  LibC
  LibStdio
```
