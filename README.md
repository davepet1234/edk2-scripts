# EDK2 Utility Scripts

These Linux scripts were created to ease development of EFI Shell applications and were tested under Ubuntu 22.04 LTS.

## Getting Started

### First Time Setup

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

### Creating and Running an EFI Shell application

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

### Getting Help

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
## Script Usage

### EDK2 Dependacies

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

### EDK2 Installation

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

### Workspace Initialisation

The `edkinit.sh` script is created in the workspace root during EDK2 installation, this is to setup your environment and must be sourced pior to startig any work.

```
$ source ./edkinit.sh

 or

$ . ./edkinit.sh
```

This sets up a path to the EDK2 scripts and runs the `edksetup.sh` script to initialise the EDK2 build environment.

### Creating Application

TODO

