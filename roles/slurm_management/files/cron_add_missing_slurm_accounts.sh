#!/bin/bash

# The script create the list of existing accounts in the sacctmgr, then it
# checkes for available groups in the /mnt/*/groups/ and it creates in the
# database all the missing ones.

# sacctmgr: -n removes header, -P makes it parsable (works also for long group names)
readarray -t _existing_accounts < <(sacctmgr -n -P list account format=Account)

# Search for all existing groups inside the '/groups' folder
# that are inside /mnt/*/ folder on the SAI machines
for _each_pfs in /mnt/*; do
   if [[ -e "${_each_pfs}/groups" ]]; then
      cd "${_each_pfs}/groups"
      # Find should be pretty robust way, but you need to manually
      # remove the leading dot slash from from the group name: "./umcg-atd"
      readarray -t _groups < <(find . -maxdepth 1 -mindepth 1 -type d | sed "s/^\.\///g")
      for _each_group in "${_groups[@]}"; do
         # check if group already added
         _group_missing=true
         for _each_existing_account in "${_existing_accounts[@]}"; do
            if [[ "${_each_existing_account}" == "${_each_group}" ]]; then
               _group_missing=false
            fi
         done
         if ${_group_missing}; then
           printf "${0}: missing account for group '%s', adding it now\n" "${_each_group}"
           sacctmgr -i create account "${_each_group}" descr=scientists org=various parent=users fairshare=parent
         fi
      done
   fi
done
