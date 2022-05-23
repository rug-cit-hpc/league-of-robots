#!/bin/bash
set -euo pipefail

_log_file="configure_tiering.log"
echo "Using the ${_log_file} file for logging."
rm -f "${_log_file}"
echo "=========== $(date) ===========" >> ${_log_file}

_red='\033[0;31m'    # red color
_grn='\033[0;32m'    # green color
_rst='\033[0m'       # no color

# following istructions from
# https://github.com/irods/irods_capability_storage_tiering

## this example follows the instructions for the 3 levels of tiering:
#     first files are uploded to demoResc > demoRescMed > demoRescSlow
## for the 3 level tiering, uncomment the double comments and run this script

# Check if tiering plugin is installed on serverAnaconda3/5.3.0

# Check if irods tiering plugin is configured in /etc/irods/server_config.json
echo -n "Checking if plugin is configured on the server ... "
if fgrep 'irods_rule_engine_plugin-unified_storage_tiering-instance' /etc/irods/server_config.json &>/dev/null; then
   echo -e "${_grn}ok${_rst}";
else
   echo -e "${_red}error${_rst}, exiting ..."; exit 255; fi

_test_cmds=(
   "if test -d /tmp/irods/demoRescMed ; then echo 'created'; else echo 'missing'; fi"
   "if test -d /tmp/irods/demoRescSlow ; then echo 'created'; else echo 'missing'; fi"
   "ilsresc demoRescMed"
   "ilsresc demoRescSlow"
   "imeta ls -R demoResc irods::storage_tiering::group"
   "imeta ls -R demoRescMed irods::storage_tiering::group"
   "imeta ls -R demoRescSlow irods::storage_tiering::group"
   "imeta ls -R demoResc irods::storage_tiering::time"
   "imeta ls -R demoRescMed irods::storage_tiering::time"
   "imeta ls -R demoResc irods::storage_tiering::minimum_delay_time_in_seconds"
   "imeta ls -R demoResc irods::storage_tiering::maximum_delay_time_in_seconds"
   "imeta ls -R demoRescMed irods::storage_tiering::minimum_restage_tier"
   "iqstat"
)
_test_return_pos=(
   "created"
   "created"
   "demoRescMed:unixfilesystem"
   "demoRescSlow:unixfilesystem"
   "attribute: irods::storage_tiering::group"
   "attribute: irods::storage_tiering::group"
   "attribute: irods::storage_tiering::group"
   "attribute: irods::storage_tiering::time"
   "attribute: irods::storage_tiering::time"
   "attribute: irods::storage_tiering::minimum_delay_time_in_seconds"
   "attribute: irods::storage_tiering::maximum_delay_time_in_seconds"
   "attribute: irods::storage_tiering::minimum_restage_tier"
   "example_group_g2"
)
_test_return_neg=(
   "missing"
   "missing"
   "does not exist"
   "does not exist"
   "None"
   "None"
   "None"
   "None"
   "None"
   "None"
   "None"
   "None"
   'delayed'
)
_install_cmds=(
   "mkdir -p /tmp/irods/demoRescMed"
   "mkdir -p /tmp/irods/demoRescSlow"
   "iadmin mkresc demoRescMed unixfilesystem `hostname`:/tmp/irods/demoRescMed"
   "iadmin mkresc demoRescSlow unixfilesystem `hostname`:/tmp/irods/demoRescSlow"
   "imeta add -R demoResc irods::storage_tiering::group example_group 0"
   "imeta add -R demoRescMed irods::storage_tiering::group example_group 1"
   "imeta add -R demoRescSlow irods::storage_tiering::group example_group 2"
   "imeta add -R demoResc irods::storage_tiering::time 60"
   "imeta add -R demoRescMed irods::storage_tiering::time 300"
   "imeta add -R demoResc irods::storage_tiering::minimum_delay_time_in_seconds 1" 
   "imeta add -R demoResc irods::storage_tiering::maximum_delay_time_in_seconds 30"
   "imeta add -R demoRescMed irods::storage_tiering::minimum_restage_tier true"
   "irule -F start_tiering_loop.r"
)

if [[ ${#_install_cmds[@]} -eq ${#_test_cmds[@]} && \
      ${#_install_cmds[@]} -eq ${#_test_return_pos[@]} && \
      ${#_install_cmds[@]} -eq ${#_test_return_neg[@]} ]] ; then
   echo "all command arrays are same size"
else
   echo -e "${_red}error${_rst}, please check commands array sizes, as they are different:"
   echo "  cmds=${#_install_cmds[@]} test=${#_test_cmds[@]} pos=${#_test_return_pos[@]} neg=${#_test_return_neg[@]}"
   exit 255
fi

cat << EOF > start_tiering_loop.r
{
   "rule-engine-instance-name": "irods_rule_engine_plugin-unified_storage_tiering-instance",
   "rule-engine-operation": "irods_policy_schedule_storage_tiering",
   "delay-parameters": "<INST_NAME>irods_rule_engine_plugin-unified_storage_tiering-instance</INST_NAME><PLUSET>1s</PLUSET><EF>1h</EF>",
   "storage-tier-groups": [
       "example_group_g2",
       "example_group"
   ]
}
INPUT null
OUTPUT ruleExecOut
EOF

chmod u+x start_tiering_loop.r

echo -e "Commands: "                      >> ${_log_file}
for _tmp in "${_install_cmds[@]}";    do echo "    ${_tmp}"; done >> ${_log_file}
echo -e "Test commands: "                 >> ${_log_file}
for _tmp in "${_test_cmds[@]}";       do echo "    ${_tmp}"; done >> ${_log_file}
echo -e "Test positive expected values: " >> ${_log_file}
for _tmp in "${_test_return_pos[@]}"; do echo "    ${_tmp}"; done >> ${_log_file}
echo -e "Test negative expected values: " >> ${_log_file}
for _tmp in "${_test_return_neg[@]}"; do echo "    ${_tmp}"; done >> ${_log_file}

echo -e "\n\n"           >> ${_log_file}
echo "Tiering rule:"     >> ${_log_file}
cat start_tiering_loop.r >> ${_log_file}
echo -e "\n\n"           >> ${_log_file}

_len=${#_install_cmds[@]}
for (( i=0; i<${_len}; i++ )); do
   echo -n "Checking '${_test_cmds[$i]}' ... "
   _test="$(eval ${_test_cmds[$i]} 2>> ${_log_file} || true)"
   if echo "${_test}" | grep -q "${_test_return_pos[$i]}" ; then
      echo -e "${_grn}installed${_rst}"
   elif echo "${_test}" | grep -q "${_test_return_neg[$i]}" ; then
      echo -n "MISSING, installing now ... "
      echo "${_install_cmds[$i]}" >> ${_log_file}
      if $(eval ${_install_cmds[$i]} 2>>${_log_file}) ; then echo -e "${_grn}ok${_rst}"
      else echo -e "${_red}error${_rst}!"
      fi
      
   else
      echo -e "${_red}error${_rst}, unexpected result, stopping script ..."
      exit 1
   fi
done


echo ""
echo ""
echo ""
echo "Check if the script is running correctly, by executing:"
echo "  iqstat        # to see if there is active rule"
echo "  iqdel         # to delete the incorrect rules"

echo "All logs are saved in the ${_log_file}"
