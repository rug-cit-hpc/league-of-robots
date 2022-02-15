#!/bin/bash

# Search for all existing groups inside the '/groups' folder
# that are inside /mnt/*/ folder on the SAI machines
for _each_pfs in /mnt/*; do
   cd "${_each_pfs}/groups"
   # Find should be pretty robust way, but you need to manually
   # remove the leading dot slash from from the group name: "./umcg-atd"
   _accounts_list="$(find . -maxdepth 1 -mindepth 1 -type d | sed "s/^\.\///g")"
   
   IFS=$'\n'
   for _each_group in "${_accounts_list}"; do
      _output="$(sacctmgr -i create account ${_each_group} descr=scientists org=various parent=users fairshare=parent 2>&1)"
      if [[ "${?}" -ne "1" ]]; then           # suppress the normal output of " Nothing new added." with exit code 1
         echo "${_output}"
      fi
   done
done
