#jinja2: trim_blocks:False
# Apptainer (previously known as Singularity)

## Table of contents
- [About Apptainer](#about-apptainer)
    - [Containers and apptainer](#containers-and-apptainer)
- [List of commonly used commands](#list-of-commonly-used-commands)
- [Building Apptainer images](#building-apptainer-images)
    - [Building Without Elevated Permissions](#building-without-elevated-permissions)
- [Sandbox](#sandbox)
    - [Example with Ubuntu 18.04](#example-with-ubuntu-1804)
    - [Converting sandbox directory to sif file](#converting-sandbox-directory-to-sif-file)
- [Building image as a regular user](#building-image-as-a-regular-user)
- [Making an image from the definition file with elevated permissions](#making-an-image-from-the-definition-file-with-elevated-permissions)
- [Definition file](#definition-file)
    - [Header](#header)
    - [Sections](#sections)
- [Important](#important)
- [Caching redirect or disable](#caching-redirect-or-disable)
- [Running Apptainer on Windows or Mac](#running-apptainer-on-windows-or-mac)
- [Using images from the Docker repository](#using-images-from-the-docker-repository)
- [Isolated runs](#isolated-runs)
- [Mounting host folders inside containers](#mounting-host-folders-inside-containers)
- [Other considerations](#other-considerations)
    - [Architecture considerations](#architecture-considerations)
    - [Licence considerations](#licence-considerations)
- [Environment variables](#environment-variables)
- [Debug information](#debug-information)
- [Additional examples](#additional-examples)
    - [Alpine as regular user build static file via sandbox directory](#alpine-as-regular-user-build-static-file-via-sandbox-directory)
    - [Simple CentOS 7 example via sandbox](#simple-centos-7-example-via-sandbox)

## About Apptainer

### In short

> Container is an isolated environment that holds the software and its dependencies and configurations. Containers can be run on any machine with compatible container technology.
Container instances can be run (deployed) from an existing image. Therefore, users must first either build (create) an image or fetch an existing image (f.e. pull from a public registry). They can also share their prebuilt images with each other to easily distribute software to different systems and can expect to always get the same results.
> _Apptainer_ and _Docker_ are different implementations of container technology. _Docker_ is the most popular one, but unfortunately not suited for multi-user environments. _Apptainer_ is suited for multi-user environments, was specifically designed for HPC clusters and can run both _Singularity_ as well as _Docker_ container images.
> Users can deploy containers, and inside those containers can access the same resources as they can access outside of those containers - nothing more.
> Container technology described here is focused only on building and deploying Linux containers on Linux host systems.

Documentation is available on the official [Apptainer's documentation website](https://apptainer.org/docs/)

### Containers and apptainer

Linux containers

* are a method for running multiple isolated Linux systems (containers) on a control host using a single Linux kernel,
* provides the cgroups functionality that allows limitation and prioritization of resources (CPU, memory, block I/O, network, etc.) without the need for starting any virtual machines.

Apptainer is a container platform

* highly optimized to be run on a laptop or high-performance cluster,
* extremely fast and lightweight - as there is no virtualization, and images are simply executed just as any other program,
* enables a secure way of running containers - images can be easily verified,
* limits security risk, as it can only access user-accessible resources,
* can directly run images from the Docker repository (via path `docker://...`).

Apptainer container image

* is a file (e.g. `ubuntu_18.04.sif`) containing all programs and libraries needed to execute that environment,
* can contain a small subset of programs (with libraries), or entire Linux operating system (like Alpine, CentOS or Ubuntu),
* is highly portable between various Linux operating systems and environments - it only requires installed Apptainer,
* container filesystem environment is by default read-only when deployed (this can be partially changed by the user at the runtime - see section `Sandbox`),
* is usually in format`.sif` (Singularity Image Format), `.sqfs` (SquashFS) or `.img` (image) ext3
* can be also a directory instead of a single file, containing all the needed files, browsable by the user outside the container.


## List of commonly used commands

1. Pull container image from Docker repository

    `$ apptainer pull docker://alpine:latest`

2. Start an interactive shell within your container

    `$ apptainer shell alpine_latest.sif`

3. Run container (this executes its predefined runscript command)

    `$ apptainer run alpine_latest.sif`

4. Execute custom command inside the container

    `$ apptainer exec alpine_latest.sif cat /etc/os-release`

5. Execute a command directly from the Docker's repository container

    `$ apptainer exec docker://busybox:latest busybox | head -n1`

6. Build sandbox directory directly from the Docker image

    `$ apptainer build --sandbox alpine_sandbox docker://busybox:latest`

7. Shell into the sandbox, pretend to be a root user and permanently save all changes

    `$ apptainer shell --fakeroot --writable alpine_sandbox`

8. Convert sandbox to static image

    `$ apptainer build alpine.sif alpine_sandbox`

## Building Apptainer images

In order to use apptainer containers, the image first needs to be built. Images can be built on top of another images (they can be local images or from the Docker repository), which can be done without elevated permissions. On the other hand, if an image is being built from scratch with f.e. `yum` installer, the elevated permissions are needed on the system to execute `sudo apptainer build ...`. 

Normally, regular users don't have elevated permissions on multi-user systems, which is also true on {{ slurm_cluster_name | capitalize }}. Section `Building without elevated permissions` describes how to build images without elevated permissions.

### Building without elevated permissions

At the time of writing this documentation (late 2022) the Apptainer documentation exaplains the option of using a `--fakeroot` parameter as a way to bypass some of these limitations. The latest version `1.1.4` has still some know issues with this option and will hopefully be soon resolved.

Fortunately, there are at least two alternatives, as users can either:
- simply build an `.sif` image file on a system where they have elevated (sudo) permissions, and then copy that `.sif` file to the cluster, or
- build an image on the cluster itself, but doing via the additional step of using the sandbox option and then convert the sandbox into the `.sif` file. To use this option, read sections `Sandbox` and `Building image as regular user`.

## Sandbox

The _sandbox_ option builds a container image inside a directory, which allows users to:

* to use the  `--fakeroot` option and become root inside container,
* to change any files inside the container, and those changes *can be* (if used `--writable`) permanently saved,
* can convert sandbox back to `.sif` file.

The drawbacks on the other hand are

* the changes inside the sandbox are not `recorded` in the image (in contrast to the build from `.def` files), and therefore,
* the `.sif` file is hard to maintain in the long run,
* running sandbox often brings lower performance: due to the converting of the image, and (in case of shared remote file system use) the access of individual files inside the sandbox is slower than the use of .sif format.

Example: Rocky Linux 9 - from Docker repository to sandbox container

```
    $ apptainer build --sandbox --disable-cache rocky_9.0-minimal.sif docker://rockylinux:9.0-minimal
    $ apptainer shell --fakeroot --writable ./rocky_9.0-minimal/
```

where `--fakeroot` will emulate elevated (root) permissions inside container and `--writable` will allow files in the sandbox to be changed.

### Example with Ubuntu 18.04

Alternatively, you can use `.def` recipe file. Example file named `ubuntu_18.04.def`
```
    Bootstrap: docker
    From: ubuntu:18.04
    
    %post
       apt-get update
       apt install --assume-yes neofetch
    
    %runscript
       neofetch
```

which can be built as sandbox
```
    $ apptainer build --sandbox --disable-cache ubuntu_18.04.sandbox ubuntu_18.04.def
```

This created in the current working directory a subdirectory `ubuntu_18.04.sandbox`, which contains all the files of the operating filesystem and software that was defined in `.def` file. This directory **is a container**, and as such can be also executed
```
    $ apptainer run ubuntu_18.04.sandbox
```

### Converting sandbox directory to sif file

```
    $ apptainer build ubuntu_18.04.sif ubuntu_18.04.sandbox
```

Will create in a current working directory a file `ubuntu_18.04.sif`, which can be executed either directly as any other executable:

```
    $ ./ubuntu_18.04.sif
```
or it can be normally run via `apptainer` command, which gives the user more options (`run`, `exec`, `shell` ...)

```
    $ apptainer run ubuntu_18.04.sif
```

## Building image as a regular user

(https://sylabs.io/guides/3.0/user-guide/build_a_container.html)

Regular users cannot build an image on the {{ slurm_cluster_name | capitalize }} by executing `sudo apptainer build ...`. Users can therefore either

- build an image on any apptainer Linux machine where they also have elevated permissions (f.e. their laptop, or dedicated apptainer build server), or
- they can build an image in a sandbox directory mode and then convert that directory to static `.sif` file

**Example of building an image from the definition file**

1. first we need to make sure we are not using our home folder - we need to create a directory inside the appropriate tmpXX filesystem and execute our commands from within
   
   `$ mkdir /groups/umcg-MYGROUP/tmpXX/umcg-MYUSERNAME/mycontainers && cd $_ && pwd`
  
  change capitalized part of the path with appropriate values.

2. inside we can create new or copy pre-existent definition file, here is an example for the tiny definition file `busybox_min.def`
```
    Bootstrap: busybox
    MirrorURL: https://www.busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
    %runscript
      /bin/busybox sh
```

3. now let's create a container image - first it will be just a sandbox directory made out of the definition file
   
   `$ apptainer build --sandbox --disable-cache /groups/umcg-group/tmpXX/umcg-myusername/busybox_sandbox ./busybox_min.def`
   
   where `./my_apptainer.def` is a container recipe file in local directory.

4. then we need to convert the sandbox into a static `.sif` file
   
   `$ apptainer build ./busybox.sif /groups/umcg-group/tmpXX/umcg-myusername/busybox_sandbox`
   
5. now we can execute the container, either (faster options) directly as any other executable file
   
   `$ ./my_apptainer.sif`
   
   or by calling the `apptainer` command first (this gives you more apptainer options)
   
   `$ apptainer run ./my_apptainer.sif`
   

## Making an image from the definition file with elevated permissions

Definition file `lolcow.def`:
```
    BootStrap: library
    From: centos:7.9
    
    %post
        apt-get -y update
        apt-get -y install fortune cowsay lolcat
    
    %environment
        export LC_ALL=C
        export PATH=/usr/games:$PATH
    
    %runscript
        fortune | cowsay | lolcat
    
    %labels
        Author GodloveD
```

Build from this file
```
    $ sudo singularity build lolcow.sif lolcow.def
```

## Definition file

Apptainer images can be created either from
- 'writable sandbox directory' environment,
- or (recommended) from a `.def` file, a definition file with instructions on how to build a custom container.

Definition file consists
- setting the initial operating system (or another container with already defined OS) as an underlying base image,
- set instructions on how to configure, unpackage or install the required software,
- configures the runtime environment and its variables,
- sets the container metadata.

More specifically, an Apptainer Definition file is divided into two parts: `Header` and `Sections`

### Header

At the top of the file is the Header with `Bootstrap` - and it defines base operating filesystem of the image, usually is set to either `docker`, `localimage`, `busybox` or `yum`, but [many others options](https://apptainer.org/docs/user/1.0/definition_files.html#other-bootstrap-agents) are also available.

### Sections

Contains some or all of the following sections:

- `%setup` commands in the %setup section are first executed on the host system outside of the container after the base OS has been installed,
- `%files` allows you to copy files into the container with greater safety than using the %setup section,
- `%app` it may be redundant to build different containers for each app with nearly equivalent dependencies, Apptainer supports installing apps within internal modules,
- `%post` download files from the internet with tools like git and wget, install new software and libraries, write configuration files, create new directories,
- `%test` runs at the very end of the build process to validate the container,
- `%environment` define environment variables that will be available at runtime,
- `%startscript` contents of this section are written to a file within the container at build time. This file is executed when the instance start command is issued,
- `%runscript` contents of this section are written to a file within the container that is executed when the container image is run,
- `%labels` are key-value pairs, and define the metadata of your container (f.e. `Author d@sylabs.io`),
- `%help` at build time is added to the metadata of the container, and can be displayed using the run-help command,
- `%post` section executes within the container at build time after the base OS has been installed. The `%post` section is therefore the place to perform installations of new applications.

You can read more about the definition file on the [Apptainer's documentation website](https://docs.sylabs.io/guides/3.7/user-guide/definition_files.html)

## Important

It depends on how the container was built, but often `/home` folder is shared between the container and the host machine. **This means that the users home folder files can be changed or deleted just by running a container**. Make sure you check first (either by running with `shell` option) and then run an isolated environment (check the section about `Isolated runs`).

Word of advice: docker and apptainer repositories are developed and maintained by the community, and therefore **images can and do contain all sorts of software and configurations**. While most of them are safe to use, users should be careful and avoid running containers from unknown sources. They might contain either buggy software or malicious code. Try to run only trusted images and when not sure, first try running inside an isolated environment (check the section about `Isolated runs`).

Storage consumption: each container consumes a lot of storage. Making a new container will quickly fill up the disk. Make sure you keep only containers that you need. At the same time, pulling containers from public repositories, stores image layers locally in the `~/.apptainer/cache` folder. Your home folder can be quickly  filled up with these temporary files. Caching should either be disabled or redirected to another location (see the section about `Caching redirect or disable`).

## Caching redirect or disable

By default _Apptainer_ caches all the downloaded image layers. Simply pulling a docker image, e.g.

```
    $ apptainer pull gate-9.2.sif docker://opengatecollaboration/gate:9.2-docker
    INFO:    Converting OCI blobs to SIF format
    INFO:    Starting build...
    Getting image source signatures
    Copying blob c84400a81634 [=============================>--------] 213.6MiB / 273.7MiB
    Copying blob bdf5ec5a2e5d done  
    Copying blob ebbbc5f611f3 done  
    Copying blob 1a930d163dca done  
    Copying blob 1d58a538c5fc [=======>------------------------------] 219.8MiB / 1.0GiB
    Copying blob 7da40ae7e7dd done  
    ...
```

will fail, as the layer `blobs` will be by default downloaded inside your home's `~/.apptainer/cache` directory. It will fill it up until 1.3GB and then the system quota will prevent further writing of the data - making the apptainer command fail.

To mitigate this, users can either run the `apptainer` command with argument  `--disable-cache`

```
    $ apptainer pull --disable-cache alpine.sif docker://alpine
```

or by redirecting the caching directory to the appropriate folder location. This can be done by setting the environment path variable pointing to the correct cache directory

```
    export APPTAINER_CACHEDIR=/groups/umcg-MYGROUP/tmpXX/$(id -un)/apptainer_cachedir
    mkdir $APPTAINER_CACHEDIR
    apptainer pull docker://alpine
```

where the user should change uppercase words into appropriate values.

Note: **this variable is set for the duration of login. To make it permanent, the `APPTAINER_CACHEDIR` variable should be defined inside the `~/.bashrc` file or create a cache folder and link users `~/.apptainer/cache` to that folder, f.e.

```
    # change group and tmp filesystem to appropriate values
    _new_cache="/groups/umcg-MYGROUP/tmpXX/$(id -un)/apptainer_cache"
    mkdir -p ${_new_cache}
    mv ~/.apptainer/cache ${_new_cache}/
    ln -s ${_new_cache}/cache ~/.apptainer/cache
```

This will keep all the caches and store them on the `tmp` filesystem.

## Running Apptainer on Windows or Mac

Apptainer cannot run natively on Windows or Mac, but it is possible to run apptainer on non-Linux machines. At the moment only by using full virtualization or [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/install) (WSL 2 or higher).

For more information please visit [Apptainer's installation documentation](https://apptainer.org/docs/admin/main/installation.html).

## Using images from the Docker repository

Users can shell, import, run, and exec Docker images directly from the Docker Registry:

* Run image directly from Docker repository

`$ apptainer run docker://alpine:latest`

* Download image from Docker reposiroty to local folder

`$ apptainer pull docker://centos:latest`

* Directly execute shell inside Docker repository image

`$ apptainer shell docker://alpine:latest`

* Execute command inside the image

`$ apptainer exec docker://alpine:latest echo "Hi from inside the container."`

* Build image from Docker repository - expects user to have elevated permissions:

`$ sudo apptainer build ubuntu.img docker://ubuntu:latest`

* Build sandbox image directly from Docker repository:

`$ apptainer build --sandbox --disable-cache ubuntu.img docker://ubuntu:latest`

* Convert sandbox to static .sif image

`$ apptainer build busybox.sif busybox_sandboxdir`

* Prevent caching downloaded files from online repositories

`$ apptainer pull --disable-cache centos.sif docker://centos:7.9`

## Isolated runs

**Be careful, by default some folders are automatically shared between host machine and container.** This depends on the options with which container was built and container runtime parameters. Most commonly, on host system user's current working directoy is automatically as `/home` folder inside the container. Badly written or malicious software from inside container, could change and delete current working directory or `/home/` directory on host system. Apptainer provides options to control this exposure, by controlling mount points. User can either limit with arguments `-c` or `-C`

```
    $ apptainer run -C mycontainer.sif
```

where

```
       -c, --contain[=false]        use minimal /dev and empty other directories (e.g. /tmp and $HOME) instead of sharing filesystems from your host
       -C, --containall[=false]     contain not only file systems, but also PID, IPC, and environment
```

First option will share no folders, while the second one will (inside container) show only processes of the container.

The `--no-mount` flag allows specific system mounts to be disabled, even if they are set in the `apptainer.conf` configuration file by the administrator.

## Mounting host folders inside containers

User can also manually control where the individual hosts folder will be mounted to, by using `--bind` (or short `-B`) argument. For example

```
    apptainer shell --bind /home/SOMEUSER/mydata:/mnt busybox.sif
```

this will expose host machine users `mydata` folder to `/mnt` folder inside container. User can instead also use `--mount` and `,ro` argument to expose a folder as a read-only inside container, f.e.

```                                                                             
    apptainer shell --mount type=bind,source=/home/SOMEUSER/mydata,destination=/mnt,ro busybox.sif
```

For more information, check Apptainer's website [about mount points](https://apptainer.org/docs/user/main/bind_paths_and_mounts.html).


## Other considerations

### Architecture considerations

Software build for specific architecture, can be only executed on the systems of the same architecture. For example, an apptainer image build on Apple M1 (ARM) or PowerPC (RISC) architecture will not run on x86 systems and vice versa.

The software compiled within the apptainer image can also have issues when running on same type of architecture, but older genration. For example, the software inside the image compiled on a modern x86 architecture CPU and with high level of optimization, can fail from running on older architecture CPU. This happens because compiled binary contains instructions of modern processor, that older ones cannot understand. Running software build on older architectures, should work on any new architecture of a same type.

### Licence considerations

A non-free software - a closed-source or proprietary software, can be used within the licence agreement of that software. Using a proprietary software from publicly available containers are not allowed. And conversly also creating and publicly share your own containers with closed-source software is usually prohibited.

Before using, and sharing containers, please check for software limitations, which can be (among many others) limited to

* group-wide, company-wide, enterprise-wide use,
* use on-premise only or geographically limited - for example to a region or country,
* limited to specific person (in some cases only when working at specific company and/or position),
* prohibited from running in the cloud,
* locked to a specific host or hardware (MAC address limited).

## Environment variables

If you have environment variables set outside of your container, on the host, then by default they will be available inside the container.
You can overwrite variable set inside container by defining it outside first. The variables that can overwrite the default set ones start with `APPTAINERENV_...`, f.e.

```
    $ export APPTAINERENV_PATH="/some/path"
    $ apptainer exec alpine_sandbox/ /bin/busybox sh -c 'echo $PATH'
    /some/path
```

or by providing argument `--env myvariable="myvalue1"` at container execution

```
    $ apptainer exec --env PATH=/some/path alpine_sandbox/ /bin/busybox sh -c 'echo $PATH'
    /some/path
```

## Debug information

In some cases you might need more information about how the container is behaving while running. Adding `-d` argument to `apptainer` call, will enable printing more information about the container environment and what system call is being executed. For example without debug:

```
    $ apptainer run -C ./busybox.sif 
    Apptainer> 
    (base) [umcg-user@gearshift mycontainer]$
```

and the same container with debug option

```
    $ apptainer -d run -C ./busybox.sif 
      DEBUG   [U=50101501,P=19806]persistentPreRun()            Apptainer version: 1.1.3-1.el7
      DEBUG   [U=50101501,P=19806]persistentPreRun()            Parsing configuration file /etc/apptainer/apptainer.conf
      DEBUG   [U=50101501,P=19806]SetBinaryPath()               Setting binary path to /usr/libexec/apptainer/bin:/apps/software/Anaconda3/2022.05/bin:/apps/software/Anaconda3/2022.05/condabin:/apps/software/lmod/lmod/libexec:/apps/software/Lua/5.1.4.9/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
      DEBUG   [U=50101501,P=19806]SetBinaryPath()               Using that path for all binaries
    ... 185 other lines ...
      DEBUG   [U=50101501,P=1]   sylogBuiltin()                Sourcing /.singularity.d/env/94-appsbase.sh
      DEBUG   [U=50101501,P=1]   sylogBuiltin()                Sourcing /.singularity.d/env/95-apps.sh
      DEBUG   [U=50101501,P=1]   sylogBuiltin()                Sourcing /.singularity.d/env/99-base.sh
      DEBUG   [U=50101501,P=1]   sylogBuiltin()                Sourcing /.singularity.d/env/99-runtimevars.sh
      DEBUG   [U=50101501,P=1]   sylogBuiltin()                Running action command run
      DEBUG   [U=50101501,P=19806]PostStartProcess()            Post start process
    Apptainer>
```
## Additional examples

### Alpine - as regular user build static file via sandbox directory

Alpine has a known bug in that is still present in apptainer version `1.1.4`. It prevents users to build apptainer images from `.def` file, reporting:
```
    INFO:    Running post scriptlet
    /.singularity.d/libs/fakeroot: eval: line 140: /.singularity.d/libs/faked: not found
    fakeroot: error while starting the `faked' daemon.
    sh: you need to specify whom to kill
    FATAL:   While performing build: while running engine: exit status 1
```

Users can still use alpine linux, if the issue can be bypassed with:
1. first pulling image from repository, saving it in current working directory as sandbox,
2. then all the packages can be installed inside the sandbox with `apptainer exec --writable`, where changes are saved permanently,
4. lastly the sandbox is convert back to static file

But this involves manual run of the commands, and can needs extra work to be automatized. The example is:

```
    $ apptainer build --sandbox alpine_sandbox docker://alpine:latest
     INFO:    Starting build...
     Getting image source signatures
     Copying blob c158987b0551 done  
     Copying config 79c58fdfff done  
     Writing manifest to image destination
     Storing signatures
     2023/01/03 21:04:12  info unpack layer: sha256:c158987b05517b6f2c5913f3acef1f2182a32345a304fe357e3ace5fadcad715
     2023/01/03 21:04:13  warn xattr{etc/shadow} ignoring ENOTSUP on setxattr "user.rootlesscontainers"
     2023/01/03 21:04:13  warn xattr{/home/umcg-scimerman/build-temp-2831576097/rootfs/etc/shadow} destination filesystem does not support xattrs, further warnings will be suppressed
     WARNING: The sandbox contain files/dirs that cannot be removed with 'rm'.
     WARNING: Use 'chmod -R u+rwX' to set permissions that allow removal.
     WARNING: Use the '--fix-perms' option to 'apptainer build' to modify permissions at build time.
     INFO:    Creating sandbox directory...
     INFO:    Build complete: alpine_sandbox
    $ apptainer exec --writable alpine_sandbox apk add R
... long output shortened ...
    $ apptainer build ./alpine_R.sif ./alpine_sandbox
    INFO:    Starting build...
    INFO:    Creating SIF file...
    INFO:    Build complete: ./alpine_R.sif
```

### Simple CentOS 7 example via sandbox

This simple CentOS 7 example is created in two steps from a definition file `centos7.def`

```
    BootStrap: docker
    From: centos:7
    
    %post
       yum install -y wget
       wget -O /tmp/screenfetch https://raw.githubusercontent.com/KittyKatt/screenFetch/v3.9.1/screenfetch-dev
       chmod 0755 /tmp/screenfetch
    
    %runscript
       /tmp/screenfetch
```

Building sandbox directory first

```
    $ apptainer build --sandbox centos7.sandboxdir centos7.def
     INFO:    User not listed in /etc/subuid, trying root-mapped namespace
     INFO:    Could not start root-mapped namespace
     INFO:    The %post section will be run under fakeroot
    ... long output ...
    $ 
```

Then either run directly

```
    $ apptainer run centos7.sandboxdir
```

Or first converting sandbox directory into single static `centos7.sif` file

```
    $ apptainer build centos7.sif centos7.sandboxdir
```
and the run with

```
    $ apptainer run centos7.sif
                   ..                    umcg-scimerman@gearshift
                 .PLTJ.                  OS: CentOS 
                <><><><>                 Kernel: x86_64 Linux 3.10.0-1160.80.1.el7.x86_64
       KKSSV' 4KKK LJ KKKL.'VSSKK        Uptime: 42d 20h 33m
       KKV' 4KKKKK LJ KKKKAL 'VKK        Packages: 150
       V' ' 'VKKKK LJ KKKKV' ' 'V        Shell: sh
       .4MA.' 'VKK LJ KKV' '.4Mb.        Disk: 13G / 149G (9%)
     . KKKKKA.' 'V LJ V' '.4KKKKK .      CPU: Intel Core (Broadwell, IBRS) @ 24x 2.4GHz
   .4D KKKKKKKA.'' LJ ''.4KKKKKKK FA.    GPU: 
  <QDD ++++++++++++  ++++++++++++ GFD>   RAM: 109412MiB / 217778MiB
   'VD KKKKKKKK'.. LJ ..'KKKKKKKK FV    
     ' VKKKKK'. .4 LJ K. .'KKKKKV '     
        'VK'. .4KK LJ KKA. .'KV'        
       A. . .4KKKK LJ KKKKA. . .4       
       KKA. 'KKKKK LJ KKKKK' .4KK       
       KKSSA. VKKK LJ KKKV .4SSKK       
                <><><><>                
                 'MKKM'                 
                   ''                   

```
