# NVidia GPU installation role for Centos 7

This role follows the latest instructions of the newest version of available
drivers, avaiable at [NVIDIA CUDA Installation Guide for
Linux](https://docs.nvidia.com/cuda/pdf/CUDA_Installation_Guide_Linux.pdf).

The driver can be installed via yum repository, but the version limiting and
driver version control is quite hard to implement. Therefore the driver is
installed by downloading and running the cuda .run file.
Driver is installed and compiled as Dynamic Kernel Module Support and will
rebuild with every new kernel instalation.


## Role outline

- it expects the gpu_count to be defined per invididual machine
- attempts to gather the GPU device status by running `nvidia-smi` command
- install the GPU driver if
   - `nvidia-smi` command is not available (cuda driver was not installed)
   - `nvidia-smi` reports different number of GPU devices than expected from `gpu_count`
- yum install on machine packages that is needed for driver install and compile
- downloads the cuda .run driver file from nvidia website (version defined in defualts)
- installs and compile the Dynamic Kernel Module Support driver
- blacklists nouveau
- reboots the machine
- checks if number of GPU devices reported from `nvidia-smi` is same as in `gpu_count`

## Dead-ends discovered

`gpu_count` is needed to install the driver, since any other `automatic` detection is
failing sooner or later. To list few:

 - `lspci` found one nvidia device when there were 8,
 - `nvidia-smi` reported no device found, when it actually should found some,
 - and `nvidia-smi` had up-and-running 3 GPU's when it should be 8

This was just while testing, but I can expect more.

`gpu_count` instead defines the "truth", and can test aginst it, if all the GPUs
are actually working or not.

## Other comments

 - The smaller Nvidia .run driver installation file is also avaialble, but then
   number of commands and options are missing on system (for example `nvidia-smi`)
 - The long term availablitiy of .run file on nvidia website is not of concern as
   the cuda archive website is in 2022 still containing the old versions from 2007
 - driver installation vial yum repository is harder to implement for two reasons:
    - the version needs to be limitied for nvidia-driver rpm and 15 (!) other packages
    - it seems that not all old versions are available on repository, only 'recent' ones

[cuda archive website](https://developer.nvidia.com/cuda-toolkit-archive)
