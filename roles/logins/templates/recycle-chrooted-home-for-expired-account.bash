#!/bin/bash

#
##
### Environment and bash sanity.
##
#
set -u
set -e
umask 0077
memyselfandi="$(basename "${0}")"
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
	echo "Sorry, you need at least bash 4.x to use ${memyselfandi}." >&2
	exit 1
fi

#
# The LDAP connection details can be fetched from the readonly-ldapsearch-credentials.bash,
# which is deployed by the sssd Ansible role from the league-of-robots repo.
#
declare ldap_config_file='/etc/openldap/readonly-ldapsearch-credentials.bash'
declare backup_retention_time='45' # unit = days.
declare recycle_latency_time='7'   # unit = days.
declare chroot_base_dir='/groups/{{ data_transfer_only_group }}/'

#
##
### functions.
##
#

function _Usage() {
	echo '######################################################################################################################'
	echo "${memyselfandi}:"
	echo '######################################################################################################################'
	echo 'Purpose:'
	echo "    Checks all chrooted homes in ${chroot_base_dir} to see if the owner's account has expired."
	echo '    Home dirs of expired accounts are first moved to a location only acessible by the root user'
	echo '    to create a backup and allow expired accounts to be recycled.'
	echo "    Backups are deleted automatically after ${backup_retention_time} days."
	echo 'Options:'
	echo '    -h  Show this help message.'
	echo '    -d  Dryrun mode: logs what would have been cleaned if this script was executed with the -c option.'
	echo "    -c  Cleanup mode: Move home dirs of expired accounts to backup location and delete backups older than ${backup_retention_time} days."
	echo '######################################################################################################################'
}

#
# Given a username, return expiration date of the account.
# We'll search all LDAP servers in the order listed.
#
function _GetLoginExpirationTime() {
	local _user="${1}"
	local _login_expiration_time='9999-99-99'
	local _ldap_domain
	for _ldap_domain in "${domain_names[@]}"; do
		local _query_result
		local _line
		local _ldap_user_expiration_regex="${domain_configs[${_ldap_domain}'_user_expiration_regex']}"
		_query_result=$(ldapsearch -LLL -o ldif-wrap=no \
				-H "${domain_configs[${_ldap_domain}'_uri']}" \
				-D "${domain_configs[${_ldap_domain}'_bind_dn']}" \
				-w "${domain_configs[${_ldap_domain}'_bind_pw']}" \
				-b "${domain_configs[${_ldap_domain}'_search_base']}" \
				"(&(ObjectClass=${domain_configs[${_ldap_domain}'_user_object_class']})(cn:dn:=${_user}))" \
				"${domain_configs[${_ldap_domain}'_user_expiration_date']}"
			)
		while read -r _line; do
			if [[ "${_line}" =~ ${_ldap_user_expiration_regex} ]]; then
				_login_expiration_time="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
				printf '%s' "${_login_expiration_time}"
				return
			fi
		done < <(printf '%s\n' "${_query_result}")
	done
	printf '%s' "${_login_expiration_time}"
}

function _ProcessChrootedHome() {
	local _user="${1}"
	local _current_date
	local _timestamp
	local _user_experation_date
	local _date_difference_in_days
	_current_date=$(date "+%Y-%m-%d")
	_timestamp=$(date "+%Y-%m-%dT%H%M%S")
	_user_experation_date=$(_GetLoginExpirationTime "${_user}")
	if [[ -z "$(ls -A "${chroot_base_dir}/${_user}")" ]]; then
		printf '%s\n' "INFO: Skipping ${_user}, because ${chroot_base_dir}/${_user} is empty."
		return
	elif [[ "${_user_experation_date}" == "9999-99-99" ]]; then
		printf '%s\n' "INFO: Skipping ${_user}, because user never expires."
		return
	else
		#printf '%s\n' "DEBUG: ${chroot_base_dir}/${_user} is not empty."
		#printf '%s\n' "DEBUG: got _user_experation_date: ${_user_experation_date} and _current_date: ${_current_date}."
		local _current_date_in_seconds
		local _user_experation_date_in_seconds
		_current_date_in_seconds="$(date '+%s' -d "${_current_date}")"
		_user_experation_date_in_seconds="$(date '+%s' -d "${_user_experation_date}")"
		_date_difference_in_days=$(( (${_current_date_in_seconds} - ${_user_experation_date_in_seconds}) / 86400 ))
		#printf '%s\n' "DEBUG: Days diff: ${_date_difference_in_days}."
		if [[ "${_date_difference_in_days}" -gt "${recycle_latency_time}" ]]; then
			printf '%s\n' "INFO: ${_user} expired more than ${recycle_latency_time} days ago."
			if [[ "${cleanup}" == 'true' ]]; then
				printf '%s' "      Moving ${chroot_base_dir}/${_user} -> ${chroot_base_dir}/.${_user}.backup_${_timestamp} ... "
				chown root:root "${chroot_base_dir}/${_user}"
				chmod -R go-rwx "${chroot_base_dir}/${_user}"
				mv "${chroot_base_dir}/${_user}" "${chroot_base_dir}/.${_user}.backup_${_timestamp}"
				local _log="${chroot_base_dir}/.${_user}.backup_${_timestamp}/${_user}.backup_${_timestamp}.log"
				local _gecos
				_gecos="$(getent passwd "${_user}" | cut -d ':' -s -f 5)"
				printf 'GECOS: %s\n' "${_gecos}"                          > "${_log}"
				printf 'ExpirationTime: %s\n' "${_user_experation_date}" >> "${_log}"
				printf '%s\n' 'done.'
			elif [[ "${dryrun}" == 'true' ]]; then
				printf '%s\n' "      Dry run: will move ${chroot_base_dir}/${_user} -> ${chroot_base_dir}/.${_user}.backup_${_timestamp} when cleanup option is specified."
			else
				printf '%s\n' 'FATAL: either dryrun or cleanup mode must be specified.'
				exit 1
			fi
		else
			printf '%s\n' "INFO: Skipping ${_user}, because user has not yet expired or expired less than ${recycle_latency_time} days ago."
		fi
	fi
}

function _DeleteOutdatedBackups() {
	local _current_date
	local _regex
	local _backup
	local _backup_date
	local _date_difference_in_days
	_current_date=$(date "+%Y%m%d")
	_regex='.backup_([0-9]{4})-([0-9]{2})-([0-9]{2})T.+$'
	
	IFS=' ' read -ra _backups <<< "$(find "${chroot_base_dir}" -mindepth 1 -maxdepth 1 -type d | grep backup | grep -o '[^/]*$' | sort | tr '\n' ' ')"
	for _backup in "${_backups[@]:-}"; do
		if [[ "${_backup}" =~ ${_regex} ]]; then
			_backup_date="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
			local _current_date_in_seconds
			local _backup_date_in_seconds
			_current_date_in_seconds="$(date '+%s' -d "${_current_date}")"
			_backup_date_in_seconds="$(date '+%s' -d "${_backup_date}")"
			_date_difference_in_days=$(( (${_current_date_in_seconds} - ${_backup_date_in_seconds} ) / 86400 ))
			if [[ "${_date_difference_in_days}" -gt "${backup_retention_time}" ]]; then
				printf '%s\n' "INFO: ${_backup} is more than ${backup_retention_time} days old."
				if [[ "${cleanup}" == 'true' ]]; then
					printf '%s' "      Deleting outdated backup ${chroot_base_dir}/${_backup} ... "
					rm -Rf "${chroot_base_dir}/${_backup:-missing}"
					printf '%s\n' 'done.'
				elif [[ "${dryrun}" == 'true' ]]; then
					printf '%s\n' "      Dry run: will delete outdated backup ${chroot_base_dir}/${_backup} when cleanup option is specified."
				else
					printf '%s\n' 'FATAL: either dryrun or cleanup mode must be specified.'
					exit 1
				fi
			else
				printf 'INFO: %s\n' "Keeping backup ${chroot_base_dir}/${_backup}, which is less than ${backup_retention_time} days old."
			fi
		fi
	done
}


#
##
### Main.
##
#


#
# Get commandline arguments.
#
declare cleanup='false'
declare dryrun='false'
while getopts "cdh" opt; do
	case "${opt}" in
		h)
			_Usage
			exit 0
			;;
		c)
			cleanup='true'
			;;
		d)
			dryrun='true'
			;;
		\?)
			printf 'FATAL: %s\n' "Invalid option -${OPTARG}. Try $(basename "${0}") -h for help."
			;;
		:)
			printf 'FATAL: %s\n' "Option -${OPTARG} requires an argument. Try $(basename "${0}") -h for help."
			;;
		*)
			printf 'FATAL: %s\n' "Unhandled option. Try $(basename "${0}") -h for help."
			;;
		esac
done

#
# Check if one of the required, mutually exclusive options was specified.
#
if [[ "${cleanup:-}" != 'true' && "${dryrun}" != 'true' ]]; then
	_Usage
	exit 1
elif [[ "${cleanup:-}" == 'true' && "${dryrun}" == 'true' ]]; then
	_Usage
	exit 1
fi

#
# Parse LDAP config file.
#
if [[ -e  "${ldap_config_file}" && -r "${ldap_config_file}" ]]; then
	# shellcheck source=/dev/null
	source "${ldap_config_file}"
else
	logger "FATAL: Config file ${ldap_config_file} missing or not readable."
	exit 1
fi

#
# Compile list of chrooted home dirs and process them.
#
IFS=' ' read -ra users <<< "$(find "${chroot_base_dir}" -mindepth 1 -maxdepth 1 -type d | grep -o '[^/]*$' | grep -v backup | sort | tr '\n' ' ')"
for user in "${users[@]}"; do
	_ProcessChrootedHome "${user}"
done

#
# Delete outdated backups.
#
_DeleteOutdatedBackups

printf '%s\n' 'INFO: Finished!'
