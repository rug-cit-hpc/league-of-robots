# Create Rocky-9.2 image #

### 1. Install Docker

Before creating the image, make sure you have Docker installed and the Docker daemon running on your machine

```
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce docker-ce-cli containerd.io
systemctl start docker
```

### 2. Make changes to yum repo's

To avoid error messages about failing mirrorlists, some changes need to be done in /etc/yum.repos.d/

Change variabele $releasever in hardcoded 8 (without minor version) in the following repo's:
- Rocky-AppStream.repo
- Rocky-BaseOS.repo
- Rocky-Extras.repo

### 3. Clone GitHub repo and setup virtual environment

For the creation of images, you can use https://github.com/stackhpc/openstack-config

```
git clone https://github.com/stackhpc/openstack-config.git 
cd openstack-config
# At the time this documentation was written, you still need code from an unmerged branch/PR:
git checkout more-images
python3 -m venv ansible.venv 
source ansible.venv/bin/activate 
pip install -U pip 
pip install -r requirements.txt
ansible-galaxy role install \                                                    
     -p ansible/roles \     
     -r requirements.yml
ansible-galaxy collection install \                                                    
    -p ansible/collections \
    -r requirements.yml
```

### 4. Adjust playbook to only create a Rocky-9.2 image and add required variables

- Comment images you don't need in ```examples/images.yml```
- Change ```TYPE``` from raw to qcow2
- Set ```FS_TYPE``` to xfs (default ext4) 

Run the playbook:
```
tools/openstack-config -p ansible/openstack-images.yml -- --extra-vars "@examples/images.yml"
```

The created image is available in: ansible/openstack-config-image-cache/

### 5. Upload image in OpenStack and add parameters to image manually

- Add SCSI model: virtio-scsi
- Add OS type: linux

### 6. Upload image to webslag

Copy image to: /home/www/f114592/site/apps/sources/r/RockyLinux/9.2/
