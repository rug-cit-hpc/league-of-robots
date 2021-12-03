# irods_davrods

## About 
The WebDAV protocol is one of the options to access the iRODS data.
This role implements the latest version of Davrods (An Apache WebDAV interface
to iRODS) inside the docker.

 - github:    https://github.com/MaastrichtUniversity/rit-davrods
 - version:   v3.2.0
 - source:    https://github.com/MaastrichtUniversity/rit-davrods/archive/refs/tags/v3.2.0.tar.gz

## Deployment

Prerequisites satified with other playbooks
 - docker needs to be installed on target host
 - ( optionally: remote irods server needs to be created )

This playbook:
 - the files with templates are copied to server
 - the docker is build
 - cron is defined, for the instances to be continuesly running

