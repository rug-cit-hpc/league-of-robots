# About

## Why
This role was created for providing a fix sized disk capacity to be available.
Under normal conditions this would be done with the partitioning, but the system
reformatting is not an option.

## What

The role creates predefined file size. Then formats the file to the apropriate filesystem type.
It mounts the file and at the same time adds the mount line to the /etc/fstab.
At the end it changes the permissions of the mounted directory to the apropriate mode/user and
group values. This permissions are permanent across the remounts and the reboots.

## Disadvantages

The performance of the loop moutned filesystem is approximately half of the original
disk speed, due to the (on how I understand) double filesystem conversion.

## Removing the mount point

- Unmount the folders
- Delete the original source files
- Remove the appropriate entry line from the `/etc/fstab`

## Samba dependency

This role should be run before the `smb_server` (Samba server) role. Samba *can* reuse
the loop mounted directory only after this role has created one.
