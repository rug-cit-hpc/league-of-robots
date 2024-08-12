# mount_volume role

This role mounts local volumes and supported both mounting devices as well as bind mounts.
A folder for the _mount point_ will be created automatically,
but the location where the _mount point_ is created must already exist.
Hence the order of of mounts may be relevant.

The `mount_volume` role uses two variables that must be configured in the `group_vars` or `static_inventory`:

* volumes: List of devices to mount (*required*)
* volume_folders: List of devices to mount (*required*)


## Defining volumes to be mounted

Example of mounting a real device first and then mounting a sub folder from that device as bind mount elsewhere:

```yaml
  volumes:
    - mount_point: '/staging'
      device: 'LABEL=staging'
      mounted_owner: root
      mounted_group: root
      mounted_mode: '0755'
      mount_options: 'defaults,noatime,nofail'
      type: xfs
    - mount_point: '/local'
      device: '/staging/slurm'
      mounted_owner: root
      mounted_group: root
      mounted_mode: '0755'
      mount_options: 'bind,nofail'
      type: none
```

Note:
 * The `device` will be formatted if it isn't formatted yet.
 * The `device` should be listed the same way it is listed in `/etc/fstab`
   and can be identiefied using a `LABEL`, an `UUID` or a path like `/dev/vdb`.

## Defining folders to be created on the mounted volumes

Optionally the `mount_volume` role can create sub folders on the mounted volume.
Below is an example for a GD stack:

```yaml
volume_folders:
  - mount_point: '/groups'
    machines: "{{ groups['data_transfer'] }}"
    folders:
      - rel_paths:
          - "{{ data_transfer_only_group }}"
        mode: '2750'
        owner: root
        group: "{{ data_transfer_only_group }}"
      - rel_paths:
          - umcg-genomescan
          - umcg-gst
        mode: '2770'
        owner: root
  - mount_point: '/staging'
    machines: "{{ groups['dragen'] }}"
    folders:
      - rel_paths:
          - development
        mode: '0770'
        owner: umcg-atd-ateambot
        group: umcg-atd
      - rel_paths:
          - slurm
        mode: '0755'
        owner: root
        group: root
```

Note: 
 * Specifying the `group` is optional. When left out the `group` will default to the same value as the item from `rel_paths`.
   This is useful when `rel_paths` contains a list of folders for groups, which should all be put in their own `group`.
