{
   "rule-engine-instance-name": "irods_rule_engine_plugin-unified_storage_tiering-instance",
   "rule-engine-operation": "irods_policy_schedule_storage_tiering",
   "delay-parameters": "<INST_NAME>irods_rule_engine_plugin-unified_storage_tiering-instance</INST_NAME><PLUSET>1s</PLUSET><EF>{{ ir_tier_rule_frequency }}</EF>",
   "storage-tier-groups": [
       "tiergroup_1",
       "tiergroup_2"
   ]
}
INPUT null
OUTPUT ruleExecOut
