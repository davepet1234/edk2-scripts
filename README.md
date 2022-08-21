# EDK2 Utility Scripts

These Linux scripts were created to ease development of EFI Shell applications and were tested under Ubuntu 22.04 LTS.

## First Time Setup

First create a suitable directory to store the files

```
$ cd ~/
$ mkdir dev
$ cd dev
```

Clone and then setup the environment for EDK2 utility scripts

```
$ git clone git@github.com:davepet1234/edk2-scripts.git
$ cd edk2-scripts
$ source ./initscripts.sh
```

You will then need to check and install EDK2 dependancies required for build

```
$ ./edkdep.sh -i
```

Download and configure EDK2 build environment, this will create an `edk2` workspace under the current directory

```
$ cd ~/dev
$ edkinstall.sh
$ cd edk2
$ source ./edkinit.sh
```

Initialise VM and create disk image from which to store the EFI shell applications

```
$ initvm.sh
```

## Creating and Running an EFI Shell application

You will first need to initialise the build enviroment, if not already done

```
$ cd ~/dev/edk2
$ source ./edkinit.sh
```

Create a EFI Shell application called `TestApp`

```
$ mkapp.sh TestApp
```

This will automatically create the following application files under the `edk2` directory

```
ShellPkg/Application/TestApp/TestApp.c
ShellPkg/Application/TestApp/TestApp.inf
```

The `TestApp.inf` file will also be added to the to the `[Components]` section of the `ShellPkg.dsc` file so it will be built

Build the shell application

```
$ buildapp.sh TestApp
```

Copy shell application to VM disk image

```
$ updatevm.sh TestApp
```

Run the VM so you can execute your EFI Shell application

```
$ runvm.sh
```

From the VM, listing the files on disk should show the `TestApp.efi` executable

```
FS0:\> dir
```

Run your application

```
FS0:\> TestApp.efi
TestApp application
```

![edk2-scripts](/screenshots/Ubuntu.jpg?raw=true "Ubuntu")

## Help

Running `scripts.sh` will list all available scripts

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

You can then get help on any script using the '-h' switch, e.g.

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

