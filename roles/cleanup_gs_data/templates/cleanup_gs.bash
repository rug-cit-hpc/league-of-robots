# If folder is empty for 1 week -> notify helpdesk
# If folder is empty for 2 weeks -> delete folder
# If folder is not empty and no .finished file is present (1 week) -> notify helpdesk
# If folder is not empty and no .finished file is present (2 weeks) -> delete folder

#TODO: notifications and removal of folders

#!/bin/bash

dirToCheck="/groups/umcg-genomescan/"*
dateInSecNow=$(date +%s)

# Check only dirs, ignore files
for dir in $(find ${dirToCheck} -maxdepth 1 -type d)
do
	# Check if dir contains data
	if [[ $(ls -A "${dir}")  ]]
	then
		echo "There is Data in ${dir}, check if .finished file is present"
		if [[ ! "${dir}/"*".finished" ]]
		then
			echo "No .finished file found, but ${dir} is not empty"
		else
			echo ".finished file found, processing of data should start soon"
		fi
	else
		echo "${dir} is empty, check if it's older than 1 week -> mail"
		if [[ $(((${dateInSecNow} - $(date -r "${dir}" +%s)) / 86400)) -gt 14 ]]
		then
			echo "${dir} is older than 14 days and will be deleted"
			#rm -rf "${dir}"
		elif [[ $(((${dateInSecNow} - $(date -r "${dir}" +%s)) / 86400)) -gt 7 ]]
		then
			echo "${dir} is older than 7 days, notification will be send"
		else
			echo "${dir} is not older than 7 days"
		fi
	fi
done
