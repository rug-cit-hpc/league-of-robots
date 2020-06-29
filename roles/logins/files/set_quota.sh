#!/bin/bash

#
# Limit disk quota for regular users, which have a home dir in /home/${PAM_USER}/.
# The admin users and root are not affected as they have their home in /admin/${PAM_USER}/ or /root/, respectively.
# This prevents users from accidentally transferring large data sets to the jumphosts with only a small local disk 
# as opposed to a cluster machine with large shared storage mounts. Filling up the small OS disk on the jumphost,
# would effectively kill the ability to login for all other users.
#

homedir="$(getent passwd "${PAM_USER}"| cut -d: -f6)"
if [[ "${homedir}" =~ ^/home/* ]]; then
	setquota -u "${PAM_USER}" 512 1024 64 128 -a
fi

exit 0