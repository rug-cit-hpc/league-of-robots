#!/bin/bash

#
# Compile JSON message payload.
#
read -r -d '' message << EOM
{
	"type": "mrkdwn",
	"text": "*The _{{ slurm_cluster_name | capitalize }}_ cluster needs help*:  
Please check and fix my nodes!  
The \`sinfo\` command reports:
\`\`\`
$(sinfo -o "%P|%a|%D|%T|%N|%E" | tr \" \' | column -t -s '|')
\`\`\`"
}
EOM

#
# Post message to Slack channel.
#
curl -X POST '{{ slurm_notification_slack_webhook }}' \
	 -H 'Content-Type: application/json' \
	 -d "${message}"
