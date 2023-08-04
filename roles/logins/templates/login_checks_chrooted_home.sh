#!/bin/bash

set -u

#
##
### Variables.
##
#

# Set a tag for the log entries.
LOGGER='logger --tag login_checks'

#
##
### Functions.
##
#

#
# Usage: run_with_timeout N cmd args...
#	or: run_with_timeout cmd args...
# In the second case, cmd cannot be a number and the timeout will be 10 seconds.
#
run_with_timeout () {
	local _time=10
	if [[ "${1}" =~ ^[0-9]+$ ]]; then _time="${1}"; shift; fi
	#
	# Run in a subshell to avoid job control messages.
	#
	( "${@}" &
		local _child="${!}"
		#
		# Avoid default notification in non-interactive shell for SIGTERM.
		#
		trap -- "" SIGTERM
		( sleep "${_time}"
			kill "${_child}" 2> /dev/null
		) &
		wait "${_child}"
	)
}

login_actions () {
	#
	# Check if login user is a member of the {{ data_transfer_only_group }}.
	#
	local groups=$(id -Gn "${PAM_USER}")
	#
	# Check if we have a regular user or one from a *-sftp group, 
	# which should have a more restricted chroot (and sftp-only shell).
	#
	if [[ "${groups}" =~ {{ data_transfer_only_group }} ]]; then
		local chrooted_home_dir="/groups/{{ data_transfer_only_group }}/${PAM_USER}/"
		if [[ -e "${chrooted_home_dir}" ]]; then
			${LOGGER} "Chrooted home dir ${chrooted_home_dir} for user ${PAM_USER} already exists."
		else
			${LOGGER} "Creating ${chrooted_home_dir} for user ${PAM_USER} ..."
			mkdir -p -m 2750 "${chrooted_home_dir}"
			chown "${PAM_USER}:${PAM_USER}" "${chrooted_home_dir}"
		fi
	fi
}

#
##
### Main.
##
#

if [[ "${PAM_USER}" != 'root' ]]; then
	run_with_timeout 10 login_actions
fi

exit 0
