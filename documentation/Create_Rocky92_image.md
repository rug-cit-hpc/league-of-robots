# Create Rocky-9.2 image #

### 0. Create a VM on cloud using existing image

In this case we created a VM based on the existing Rocky 8.7 image.
Login on this VM and continue with the next steps...

### 1. Fix yum repo configs

To avoid error messages about failing mirrorlists, repo config files need to be updated in ```/etc/yum.repos.d/```

Change variabele `$releasever` in hardcoded `8` (without minor version) in the following repo's:
- ```/etc/yum.repos.d/Rocky-AppStream.repo```
- ```/etc/yum.repos.d/Rocky-BaseOS.repo```
- ```/etc/yum.repos.d/Rocky-Extras.repo```

### 2. Install Docker

Before creating the image, make sure you have Docker installed and the Docker daemon running on your machine.

```
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce docker-ce-cli containerd.io
systemctl start docker
```

### 3. Clone git repo and setup virtual environment

We use https://github.com/stackhpc/openstack-config for creating images.

```
git clone https://github.com/stackhpc/openstack-config.git 
cd openstack-config
# At the time this documentation was written, you still need code from an unmerged branch/PR:
git checkout more-images
python3 -m venv ansible.venv 
source ansible.venv/bin/activate 
pip install -U pip 
pip install -r requirements.txt
ansible-galaxy role install       -p ansible/roles       -r requirements.yml
ansible-galaxy collection install -p ansible/collections -r requirements.yml
```

### 4. Adjust playbook to only create a Rocky-9.2 image and add required variables

Examples are located in ```examples/images.yml```

For our image we created ```rocky-9.2.yml``` with
```
---
###############################################################################
# Configuration of Glance software images.

# List of additional host packages.
os_images_package_dependencies_extra:
  # debootstrap is required to build ubuntu-minimal images.
  - debootstrap

# Drop cloud-init and stable-interface-names from default elements.
os_images_common: enable-serial-console

# Set this to true to force rebuilding images.
os_images_force_rebuild: false

# List of Glance images. Format is as required by the stackhpc.os-images role.
openstack_images:
  - "{{ openstack_image_rocky92 }}"

# Rocky Linux 9.2 built from custom containerfile
openstack_image_rocky92:
  name: "Rocky-9.2"
  type: "qcow2"
  elements:
    - "rocky-container"
    - "cloud-init"
    - "cloud-init-growpart"
    - "selinux-permissive"
    - "dhcp-all-interfaces"
    - "vm"
    - "grub2"
    - "openssh-server"
    # Required for UEFI mode:
    - "block-device-efi"
    - "dracut-regenerate"
  is_public: True
  packages:
    - "git"
    - "tmux"
    - "vim-enhanced"
    - "bash-completion"
    - "git"
    - "linux-firmware"
    # Next 3 are required for UEFI mode:
    - "gdisk"
    - "efibootmgr"
    - "efivar"
    - "dracut"
    - "dracut-network"
  env:
    DIB_CONTAINERFILE_NETWORK_DRIVER: host
    DIB_CONTAINERFILE_RUNTIME: docker
    DIB_CONTAINERFILE_RUNTIME_ROOT: 1
    DIB_CONTAINERFILE_DOCKERFILE: "{{ playbook_dir }}/../containerfiles/rocky-9.2"
    YUM: dnf
    FS_TYPE: "xfs"
    DIB_CLOUD_INIT_GROWPART_DEVICES:
      - "/"
    DIB_RELEASE: "9.2"
    DIB_DRACUT_ENABLED_MODULES:
      - name: lvm
        packages:
          - lvm2
      - name: kernel-modules
      - name: kernel-network-modules
  properties:
    os_type: "linux"
    os_distro: "rocky"
    os_version: "9.2"
    hw_vif_multiqueue_enabled: true
    hw_scsi_model: "virtio-scsi"
    hw_disk_bus: "scsi"
...
```

Run the playbook:
```
tools/openstack-config -p ansible/openstack-images.yml -- --extra-vars "@rocky-9.2.yml"
```

When ```TASK [stackhpc.os-images : Generate diskimage-builder images]``` succeeded,
the created image is available in:

```ansible/openstack-config-image-cache/```

(The ```TASK [stackhpc.os-images : Upload cloud tenant images]``` task will fail due to missing credentials.)

### 5. Upload image in OpenStack and add parameters to image manually

Add:
 - `hw_scsi_model`: `virtio-scsi`
 - `os_type`: `linux`
 - `os_distro`: `rocky`
 - `cpu_arch`: `x86_64`

### 6. Upload image to webslag

Copy image to: /home/www/f114592/site/apps/sources/r/RockyLinux/9.2/
