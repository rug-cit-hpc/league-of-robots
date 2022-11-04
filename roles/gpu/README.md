# NVidia GPU installation role for Centos 7

This role follows the latest instructions of the newest version of available
drivers, avaiable at [NVIDIA CUDA Installation Guide for
Linux](https://docs.nvidia.com/cuda/pdf/CUDA_Installation_Guide_Linux.pdf).

## Role outline

- installs `pciutils` tools
- checks if there is pci device from nvidia and if there is, then it
- installs on system needed yum packages that can later build the driver
- downloads the .run driver from nvidia (driver version is defined in defualts)
- installs and compile the driver module
- blacklists nouveau
- installs systemd service file, that automatically loads the driver upons system
  boot, and that reloads the driver when/if it has failed operating

## TO-DO
- extensive testing and benchmarking
- role for development software installation
