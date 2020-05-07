#jinja2: trim_blocks:False
# Data transfers - Push to or pull from {{ slurm_cluster_name | capitalize }} User Interface via Jumphost with GUI on macOS

On macOS you can use _**SSHFS**_ (SSH File System) to browse the file systems of the {{ slurm_cluster_name | capitalize }} cluster directly in the _**Finder**_ over a normal SSH connection.
_SSHFS_ depends on the _FUSE libraries_, which extend the native macOS file handling capabilities via third-party file systems.

## 1. Install FUSE for macOS

Download and install **[FUSE for macOS from https://osxfuse.github.io/](https://osxfuse.github.io/)**

## 2. Install SSHFS for macOS

Download and install **[SSHFS from https://osxfuse.github.io/](https://osxfuse.github.io/)**

## 3. Download and run mount-cluster-drives app

 * Download and unzip the [mount-cluster-drives](../attachments/mount-cluster-drives-macos.zip) AppleScript application.
 * Start the ```mount-cluster-drives``` app by double clicking in the ```Finder``` application.
 * Depending on your macOS version, you may receive a pop-up requesting permission to allow access to the ```Finder``` application:  
   ![Allow access to the Finder.app](img/mount-cluster-drives-1.png)  
   Click _Ok_ to allow access to the ```Finder```.  
   If you want to revoke this permission or change it back to allow later on, you can do so in 
    _System Preferences_ -> _Security & Privacy_ prefs -> _Privacy_ tab -> _Automation_
 * The ```mount-cluster-drives``` app will mount the file systems of all configured clusters in a sub directory of your home dir named ```ClusterDrives```.  
   ![ClusterDrivesInFinder](img/mount-cluster-drives-2.png)  
   You can now drag and drop files in the ```Finder``` to transfer to / from {{ slurm_cluster_name | capitalize }}.
 * To unmount the _SSHFS_ shares click the eject button behind the name of the share.

#### Technical Details

The ```mount-cluster-drives``` app parses special comment lines like this:
```
#
# Special comment lines parsed by our mount-cluster-drives script to create sshfs mounts.
# (Will be ignored by OpenSSH.)
# {% set sshfs_jumphost = groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') %}
# {% set sshfs_ui = groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') %}
#SSHFS {{ sshfs_ui }}_groups={{ sshfs_jumphost }}+{{ sshfs_ui }}:/groups/
#SSHFS {{ sshfs_ui }}_home={{ sshfs_jumphost }}+{{ sshfs_ui }}:/home/${_user}/
#
```
in ```${HOME}/.ssh/conf.d/{{ slurm_cluster_name }}```,
which is the SSH client configuration file for {{ slurm_cluster_name | capitalize }}.

This ```${HOME}/.ssh/conf.d/{{ slurm_cluster_name }}``` file was created by the ```ssh-client-config-for-{{ slurm_cluster_name }}``` app 
from the SSH client configuration [instructions for macOS clients](../logins-macos/) page.

The parsed comment lines result in the following mount commands:
```
sshfs -o "defer_permissions,follow_symlinks,noappledouble,noapplexattr,reconnect,auto_xattr,auto_cache,connecttimeout=10,volname={{ sshfs_ui }}_groups" \
         "{{ sshfs_jumphost }}+{{ sshfs_ui }}:/groups/" \
         "~/ClusterDrives/{{ sshfs_ui }}_groups"
sshfs -o "defer_permissions,follow_symlinks,noappledouble,noapplexattr,reconnect,auto_xattr,auto_cache,connecttimeout=10,volname={{ sshfs_ui }}_home" \
         "{{ sshfs_jumphost }}+{{ sshfs_ui }}:/home/<youraccount>"
         "~/ClusterDrives/{{ sshfs_ui }}_home"
```

If you have access to multiple clusters, which were configured in a similar way, you may have multiple _SSHFS_ mounts,
which are all mounted with the same ```mount-cluster-drives``` app.
