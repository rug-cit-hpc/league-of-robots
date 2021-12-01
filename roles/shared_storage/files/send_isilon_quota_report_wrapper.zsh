#!/bin/zsh
#
# Wrapper script to:
#  * Generate a quota report with "isi quota quotas list" command and
#  * Send the generated report by email using a custom sendmail.py,
#    which is required as Isilon systems are Debian based,
#    but lack a regular Linux command line mail client.
#

declare -a physical_file_systems
physical_file_systems=(
	'umcgst10'  # On UMCG Research Isilon
)

for pfs in "${physical_file_systems}"; do
	isi quota quotas list \
		--recurse-path-children \
		--path "/ifs/rekencluster/${pfs}/groups/" \
		| python /ifs/scripts/send_email.py \
			-f "cron@$(hostname)" \
			-t hpc.helpdesk@umcg.nl \
			-s "HPC report: Quota vs. disk usage for file system ${pfs}."
done
