#!/bin/bash
#
# Script for verifying and fixing permissions of
#   /apps/modules/
#   /apps/software/
#   /apps/data/
#   /apps/sources/
# and their copies on tmp* file sytems.
#
# Executed overnight by cron.
#
# Note make sure that the server on which this script runs has read-write access as root
# and not read-only mounts or (NFS) shares mounted that were exported with root_squash.
#

#
# Bash sanity.
#
set -u
set -e
umask 0027

#
# Global variables.
#
ORIGINAL_HPC_ENV_PREFIX='{{ hpc_env_prefix }}'
declare -a COPIED_HPC_ENV_MOUNT_POINT_PARENTS=('/mnt')
SYS_USER='{{ envsync_user }}'
SYS_GROUP='{{ envsync_group }}'
ROLE_USER="$(whoami)"
REAL_USER="$(logname 2>/dev/null || echo 'no login name')"

{% raw %}

#
##
### Functions.
##
#

#
# Retain ownership and change group + perms if necessary on the originals.
#
function verifyAndFixOriginals() {
  local _ROOT_OF_HPC_ENV_ORIGINAL="${1}"
  declare -a _HPC_ENV_FOLDERS=("${_ROOT_OF_HPC_ENV_ORIGINAL}/modules/" 
                                     "${_ROOT_OF_HPC_ENV_ORIGINAL}/software/" 
                                     "${_ROOT_OF_HPC_ENV_ORIGINAL}/data/" 
                                     "${_ROOT_OF_HPC_ENV_ORIGINAL}/sources/"
                                     "${_ROOT_OF_HPC_ENV_ORIGINAL}/.tmp/")
  for (( i = 0 ; i < ${#_HPC_ENV_FOLDERS[@]} ; i++ ))
  do
    if [[ -e "${_HPC_ENV_FOLDERS[${i}]}" ]]; then
      find "${_HPC_ENV_FOLDERS[${i}]}" \! -group "${SYS_GROUP}" -a \! -type l -exec chgrp "${SYS_GROUP}" '{}' \;
      verifyPermissions "${_HPC_ENV_FOLDERS[${i}]}" '0775' '0664' 'ug+rwX,o+rX,o-w' '2775'
    fi
  done
}

#
# Change ownership, group and perms if necessary on the copies.
#
function verifyAndFixCopies() {
  local _ROOT_OF_HPC_ENV_COPY="${1}"
  declare -a _HPC_ENV_FOLDERS=("${_ROOT_OF_HPC_ENV_COPY}/modules/" 
                               "${_ROOT_OF_HPC_ENV_COPY}/software/" 
                               "${_ROOT_OF_HPC_ENV_COPY}/data/")
  for (( i = 0 ; i < ${#_HPC_ENV_FOLDERS[@]} ; i++ ))
  do
    if [[ -e "${_HPC_ENV_FOLDERS[${i}]}" ]]; then
      find "${_HPC_ENV_FOLDERS[${i}]}" \! -user  "${SYS_USER}"  -a \! -type l -exec chown "${SYS_USER}" '{}' \;
      find "${_HPC_ENV_FOLDERS[${i}]}" \! -group "${SYS_GROUP}" -a \! -type l -exec chgrp "${SYS_GROUP}" '{}' \;
      verifyPermissions "${_HPC_ENV_FOLDERS[${i}]}" '0755' '0644' 'u+rwX,go+rX,go-w' '2755'
    fi
  done
}

#
# Fix folder perms recursively.
# We change perms only if they are wrong, so last modification time stamps do not get changed 
# unless there really was something to change. Mostly used for "group" folders.
#
function verifyPermissions() {
  local _FOLDER="${1}"
  local _FIND_FILE_PERMS_EXECUTABLE="${2}"
  local _FIND_FILE_PERMS_REGULAR="${3}"
  local _CHMOD_FILE_PERMS="${4}"
  local _FOLDER_PERMS="${5}"
  echo "INFO:     Verify and fix permissions with file perms ${_CHMOD_FILE_PERMS} and folder perms ${_FOLDER_PERMS} for for folder ${_FOLDER}... "
  find "${_FOLDER}"  -type f -a \! \( -perm "${_FIND_FILE_PERMS_EXECUTABLE}" -o -perm "${_FIND_FILE_PERMS_REGULAR}" \) -exec chmod "${_CHMOD_FILE_PERMS}" '{}' \;
  find "${_FOLDER}"  -type d -a \!    -perm "${_FOLDER_PERMS}"                                                         -exec chmod "${_FOLDER_PERMS}" '{}' \;
}

#
##
### Main.
##
#

if [[ "${ROLE_USER}" != 'root' ]]; then
  echo "FATAL: This script must be executed by the root user, but you are ${ROLE_USER} (${REAL_USER})."
fi

#
# Check (and fix if necessary) our original shared HPC environment.
#
if [[ -e "${ORIGINAL_HPC_ENV_PREFIX}" ]] && [[ -d "${ORIGINAL_HPC_ENV_PREFIX}" ]]; then
  echo "INFO: Found original environment @ ${ORIGINAL_HPC_ENV_PREFIX}: will verify and fix permissions... "
  verifyAndFixOriginals "${ORIGINAL_HPC_ENV_PREFIX}"
  echo 'INFO: Done!'
else
  echo "WARN: Original environment not found @ ${ORIGINAL_HPC_ENV_PREFIX}: skipping verification and fixing permissions."
fi

#
# Find all rsynced copies of our shared HPC environment.
#
declare -a COPIED_HPC_ENV_PREFIXES=()
for (( i = 0 ; i < ${#COPIED_HPC_ENV_MOUNT_POINT_PARENTS[@]} ; i++ ))
do 
  #
  # Check for presence of folders for logical file system (LFS) names
  # and if present whether they contain a copy of ${ORIGINAL_HPC_ENV_PREFIX}.
  #
  declare -a LFS_MOUNT_POINTS
  readarray -t LFS_MOUNT_POINTS< <(find "${COPIED_HPC_ENV_MOUNT_POINT_PARENTS[${i}]}" -mindepth 1 -maxdepth 1 -type d)
  for (( j = 0 ; j < ${#LFS_MOUNT_POINTS[@]} ; j++ ))
  do
    [[ -z "${LFS_MOUNT_POINTS[${j}]}" ]] && continue
    COPIED_HPC_ENV_PREFIX="${LFS_MOUNT_POINTS[${j}]}${ORIGINAL_HPC_ENV_PREFIX}"
    if [[ -e "${COPIED_HPC_ENV_PREFIX}" ]] && \
       [[ -r "${COPIED_HPC_ENV_PREFIX}" ]] && \
       [[ -w "${COPIED_HPC_ENV_PREFIX}" ]] && \
       [[ -d "${COPIED_HPC_ENV_PREFIX}" ]]; then
      if [[ "${#COPIED_HPC_ENV_PREFIXES[@]}" -eq 0 ]]; then
        COPIED_HPC_ENV_PREFIXES=("${COPIED_HPC_ENV_PREFIX}")
      else
        COPIED_HPC_ENV_PREFIXES=("${COPIED_HPC_ENV_PREFIXES[@]:-}" "${COPIED_HPC_ENV_PREFIX}")
      fi
    else
      echo "INFO: No ${ORIGINAL_HPC_ENV_PREFIX} copy found on ${LFS_MOUNT_POINTS[${j}]}."
    fi
  done
done

#
# Check (and fix if necessary) all rsynced copies of our shared HPC environment.
#
if [[ "${#COPIED_HPC_ENV_PREFIXES[@]}" -eq 0 ]]; then
  echo "WARN: Found no environment copies and will not verify and fix permissions for environment copies."
else
  for THIS_HPC_ENV_PREFIX in "${COPIED_HPC_ENV_PREFIXES[@]:-}"; do
    echo "INFO: Will verify and fix permissions for environment copy @ ${THIS_HPC_ENV_PREFIX} ... "
    verifyAndFixCopies "${THIS_HPC_ENV_PREFIX}"
    echo 'INFO: Done!'
  done
fi

{% endraw %}