#jinja2: trim_blocks:True, lstrip_blocks: True
#!/bin/bash

#
# Code Conventions:
# 	Indentation:           TABs only
# 	Functions:             camelCase
# 	Global Variables:      lower_case_with_underscores
# 	Local Variables:       _lower_case_with_underscores_and_prefixed_with_underscore
# 	Environment Variables: UPPER_CASE_WITH_UNDERSCORES
#

#
# Mailinglist server
#
# We use sending emails combined with "screen-scraping" of the web interface
# as some rudimentary form of API to interact with the LISTSERV server :o
#
listserv_api_email_from="{{ listserv_api_email_from }}"
listserv_api_email_to="{{ listserv_api_email_to }}"
listserv_api_webinterface_url="{{ listserv_api_webinterface_url }}"
listserv_admin_user="{{ listserv_admin_user }}"
listserv_admin_pass="{{ listserv_admin_pass }}"
#
# Entitlement groups a.k.a. LDAP containers a.k.a. LDAP domains.
#
# We use an array of listserv_domains in combination with a fake multi-dimensional hash 
# using listserv_domain and key joined with an underscore to make the hash keys unique.
#

declare -a listserv_domains=({% for ldap_domain, ldap_config in ldap_domains.items() %}{% if ldap_config['listserv_mailinglist'] is defined %}{% if not loop.first %} {% endif %}'{{ ldap_domain }}'{% endif %}{% endfor %})
declare -A listserv_configs=(
{% for ldap_domain, ldap_config in ldap_domains.items() %}
  {% if ldap_config['listserv_mailinglist'] is defined %}
    ['{{ ldap_domain }}_mailinglist']='{{ ldap_config['listserv_mailinglist'] }}'
  {% endif %}
{% endfor %}
)
{% raw %}
declare ldap_config_file='/etc/openldap/readonly-ldapsearch-credentials.bash'
#
# Accounts that should be excluded from the mailing lists
# and hence from processing by this script.
# These are usually functional accounts.
# The values of this array are used as POSIX bash regex patterns.
# Some examples:
#
declare -a no_subscription_account_name_patterns=(
	'-guest[0-9]{1,}$'
	'-dm$'
	'-ateambot$'
)

#
##
### Environment and Bash sanity.
##
#

if [[ "${BASH_VERSINFO}" -lt 4 || "${BASH_VERSINFO[0]}" -lt 4 ]]; then
	echo "Sorry, you need at least bash 4.x to use ${0}." >&2
	exit 1
fi

set -e # Exit if any subcommand or pipeline returns a non-zero exit status.
set -u # Raise exception if variable is unbound. Combined with set -e will halt execution when an unbound variable is encountered.
#set -o pipefail # Fail when any command in series of piped commands failed as opposed to only when the last command failed.

umask 0077

export TMPDIR="${TMPDIR:-/tmp}" # Default to /tmp if $TMPDIR was not defined.
SCRIPT_NAME="$(basename ${0})"
SCRIPT_NAME="${SCRIPT_NAME%.*sh}"
INSTALLATION_DIR="$(cd -P "$(dirname "${0}")/.." && pwd)"
LIB_DIR="${INSTALLATION_DIR}/lib"
CFG_DIR="${INSTALLATION_DIR}/etc"
HOSTNAME_SHORT="$(hostname -s)"

#
# Make sure dots are used as decimal separator.
#
LANG='en_US.UTF-8'
LC_NUMERIC="${LANG}"

#
##
### Functions.
##
#
function showHelp() {
	#
	# Display commandline help on STDOUT.
	#
	cat <<EOH
===============================================================================================================
Script to fetch users from the LDAP server and (un)subscribe them to a mailinglist.

Usage:

	$(basename $0) OPTIONS

OPTIONS:

	-h   Show this help.
	-u   Update mailinglist subscriptions.
	     By default this script will only do a "dry run": fetch users from the LDAP and show whether they will be (un)subscribed.
	-n   Notify users by email when they are subscribed, unsubscribed or when their email address is updated.
	-b   Backup directory. Will create a full backup of the list of subscribers for each mailing list in the specified dir.
	-l   Log level.
	     Must be one of TRACE, DEBUG, INFO (default), WARN, ERROR or FATAL.

Details:

	Values are always reported with a dot as the decimal seperator (LC_NUMERIC="en_US.UTF-8").
	Values for some variables are inserted using Jinja templating when this script is deployed with Ansible.
===============================================================================================================

EOH
	#
	# Reset trap and exit.
	#
	trap - EXIT
	exit 0
}

#
# Custom signal trapping functions (one for each signal) required to format log lines depending on signal.
#
function trapSig() {
	local _trap_function="${1}"
	local _line="${2}"
	local _function="${3}"
	local _status="${4}"
	shift 4
	for _sig; do
		trap "${_trap_function} ${_sig} ${_line} ${_function} ${_status}" "${_sig}"
	done
}

function trapHandler() {
	local _signal="${1}"
	local _line="${2}"
	local _function="${3}"
	local _status="${4}"
	log4Bash 'FATAL' "${_line}" "${_function}" "${_status}" "Trapped ${_signal} signal."
}

#
# Trap all exit signals: HUP(1), INT(2), QUIT(3), TERM(15), ERR.
#
trapSig 'trapHandler' '${LINENO}' '${FUNCNAME:-main}' '$?' HUP INT QUIT TERM EXIT ERR

#
# Catch all function for logging using log levels like in Log4j.
# ARGS: LOG_LEVEL, LINENO, FUNCNAME, EXIT_STATUS and LOG_MESSAGE.
#
function log4Bash() {
	#
	# Validate params.
	#
	if [ ! ${#} -eq 5 ] ;then
		echo "WARN: should have passed 5 arguments to ${FUNCNAME}: log_level, LINENO, FUNCNAME, (Exit) STATUS and log_message."
	fi
	
	#
	# Determine prio.
	#
	local _log_level="${1}"
	local _log_level_prio=${l4b_log_levels[$_log_level]}
	local _status="${4:-$?}"
	
	#
	# Log message if prio exceeds threshold.
	#
	if [ ${_log_level_prio} -ge ${l4b_log_level_prio} ]; then
		local _problematic_line="${2:-'?'}"
		local _problematic_function="${3:-'main'}"
		local _log_message="${5:-'No custom message.'}"
		
		#
		# Some signals erroneously report $LINENO = 1,
		# but that line contains the shebang and cannot be the one causing problems.
		#
		if [ "${_problematic_line}" -eq 1 ]; then
			_problematic_line='?'
		fi
		
		#
		# Format message.
		#
		local _log_timestamp=$(date "+%Y-%m-%dT%H:%M:%S") # Creates ISO 8601 compatible timestamp.
		local _log_line_prefix=$(printf "%-s %-s %-5s @ L%-s(%-s)>" "${SCRIPT_NAME}" "${_log_timestamp}" "${_log_level}" "${_problematic_line}" "${_problematic_function}")
		local _log_line="${_log_line_prefix} ${_log_message}"
		if [ ! -z "${mixed_stdouterr:-}" ]; then
			_log_line="${_log_line} STD[OUT+ERR]: ${mixed_stdouterr}"
		fi
		if [ ${_status} -ne 0 ]; then
			_log_line="${_log_line} (Exit status = ${_status})"
		fi
		
		#
		# Log to STDOUT (low prio <= 'WARN') or STDERR (high prio >= 'ERROR').
		#
		if [[ ${_log_level_prio} -ge ${l4b_log_levels['ERROR']} || ${_status} -ne 0 ]]; then
			printf '%s\n' "${_log_line}" > /dev/stderr
		else
			printf '%s\n' "${_log_line}"
		fi
	fi
	
	#
	# Exit if this was a FATAL error.
	#
	if [ ${_log_level_prio} -ge ${l4b_log_levels['FATAL']} ]; then
		#
		# Reset trap and exit.
		#
		trap - EXIT
		if [ ${_status} -ne 0 ]; then
			exit ${_status}
		else
			exit 1
		fi
	fi
}

function getSubscriptions () {
	#
	local _listserv_domain="${1}"
	local _login_file="${TMPDIR}/${SCRIPT_NAME}/login_result.html"
	local _cookie_file="${TMPDIR}/${SCRIPT_NAME}/cookiejar.txt"
	local _subscribtions_file="${TMPDIR}/${SCRIPT_NAME}/${_listserv_domain}-subscriptions.list"
	local _mailinglist="${listserv_configs[${_listserv_domain}'_mailinglist']}"
	#
	# Login to get cookie, which we store in our cookiejar.
	#  * LOGIN1 and X are required empty arguments.
	#  * Order of arguments is essential and not random.
	#
	mixed_stdouterr=$(curl --silent --show-error \
		--cookie-jar "${_cookie_file}" \
		--data-urlencode 'LOGIN1=' \
		--data-urlencode "Y=${listserv_admin_user}" \
		--data-urlencode "p=${listserv_admin_pass}" \
		--data-urlencode "e=Log+In" \
		--data-urlencode 'X=' \
		--output "${_login_file}" \
		"${listserv_api_webinterface_url}" 2>&1) \
			|| log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" "${?}" "Failed to login as ${listserv_admin_user} on ${listserv_api_webinterface_url}."
	
	log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Login as ${listserv_admin_user} on ${listserv_api_webinterface_url} succeeded. Cookies were stored in ${_cookie_file}."
	#
	# Use cookie from our jar to retrieve a subscribers list,
	# which is pipe (|) separated.
	#
	mixed_stdouterr=$(curl --silent --show-error \
		--cookie "${_cookie_file}" \
		--data-urlencode "REPORT=${_mailinglist}" \
		--data-urlencode "Y=${listserv_admin_user}" \
		--data-urlencode '_charset_=UTF-8' \
		--data-urlencode 'z=2' \
		--data-urlencode 'CSV=|ALL' \
		--output "${_subscribtions_file}" \
		"${listserv_api_webinterface_url}" 2>&1) \
			|| log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" "${?}" "Failed to download list of ${_mailinglist} subscribers from ${listserv_api_webinterface_url} to ${_subscribtions_file}."
	log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Downloaded list of ${_mailinglist} subscribers from ${listserv_api_webinterface_url} to ${_subscribtions_file}."
	#
	# Patch formatting issues.
	#
	echo >> ${_subscribtions_file}                    # Append missing line end character on last line.
	perl -pi -e 's/"//g'     "${_subscribtions_file}" # Remove all double quotes.
	perl -pi -e 's/ \| /|/g' "${_subscribtions_file}" # Remove spaces that surround the value separator character (|).
	perl -pi -e 's/\|$//'    "${_subscribtions_file}" # Remove the bogus value separator character (|) at the end of each line.
	#
	# Parse subscriptions file.
	#
	local _header="$(head -1 "${_subscribtions_file}")"
	if [[ "${_header:-}" != 'Email|Name' ]]; then
		log4Bash 'ERROR' "${LINENO}" "${FUNCNAME:-main}" '0' "Header of ${_subscribtions_file} file is malformed."
		log4Bash 'ERROR' "${LINENO}" "${FUNCNAME:-main}" '0' "       Expected 'Email|Name' and got '${_header:-}'."
		log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" '0' "Failed to parse list of ${_mailinglist} subscribers."
	fi
	local _regex='\(([^()]{1,})\)'
	while IFS='|' read -r -a _subscriber_record_values; do
		#
		# * Skip blank lines.
		# * Skip the header line: Email|Name
		#
		local _email="${_subscriber_record_values[0]:-}"
		local _full_name="${_subscriber_record_values[1]:-}"
		if [[ "${_email:-}" != '' ]] && [[ "${_full_name:-}" != '' ]] && [[ "${_email:-}" != 'Email' ]]; then
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Subscriber record contains email ${_email} and full name ${_full_name}."
			if [[ "${_full_name}" =~ ${_regex} ]]; then
				local _account_name="${BASH_REMATCH[1],,}" # Convert key on-the-fly to lowercase just in case.
				log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Found account name ${_account_name} and adding subscribed user to subscriptions hash."
				subscriptions["${_account_name}"]="${_email}|${_full_name}"
			else
				log4Bash 'ERROR' "${LINENO}" "${FUNCNAME:-main}" '0' "No account name found at the end of full name ${_full_name}. Account name must be listed between round brackets at the end of the full name."
				log4Bash 'INFO' "${LINENO}" "${FUNCNAME:-main}" '0' "Deleting ${_email} from the ${_mailinglist} mailing list, because full name '${_full_name}' is malformed and lacks account name."
				sendListservCommand "${_mailinglist}" "${notify_users}" 'DELETE' "${_email}"
			fi
		fi
	done < "${_subscribtions_file}"
	#
	# Optional: Make backup of mailinglist subscriptions.
	#
	if [[ ! -z "${backup_dir:-}" ]]; then
		#
		# Create directory and timestamp for backups.
		#
		log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Making backup of ${_mailinglist} mailing list subscribers..."
		mixed_stdouterr=$(mkdir -m 0700 -p "${backup_dir}" 2>&1) \
						|| log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" "${?}" "Failed to create backup dir ${backup_dir}."
		if [[ -d ${backup_dir} && -w ${backup_dir} ]]; then
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Backup dir ${backup_dir} is Ok."
		else
			log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" '0' "Backup dir ${backup_dir} cannot be used. Check path and permissions."
		fi
		local _backup_ts=`date "+%Y-%m-%d-T%H%M"`
		local _backup_file="${backup_dir}/${_listserv_domain}-subscriptions-${_backup_ts}.list"
		#
		# We already have the list of subscribers as a temp file: mv this file to the backup dir.
		#
		mixed_stdouterr=$(mv "${_subscribtions_file}" "${_backup_file}" 2>&1) \
			|| log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" "${?}" "Failed to create backup ${_backup_file}."
		log4Bash 'INFO' "${LINENO}" "${FUNCNAME:-main}" '0' "Backup was saved to ${_backup_file}."
	fi
}

#
# Manage mailing list subscriptions.
#
function manageSubscriptions () {
	#
	local _listserv_domain="${1}"
	local _mailinglist="${listserv_configs[${_listserv_domain}'_mailinglist']}"
	local _ldif_file="${TMPDIR}/${SCRIPT_NAME}/${_listserv_domain}.ldif"
	local _ldap_attr_regex='([^: ]{1,})(:{1,2}) ([^:]{1,})'
	local _timestamp_regex='^([0-9]){4}([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})' # YYYYMMDDhhmm ignores any seocnds and timezomes at the end.
	local _sn_regex='([^,]{1,}),[[:blank:]]*([^,]{1,})[[:blank:]]*'
	local _subscription_regex='([^|]{1,})[|]([^|]{1,})'
	#
	# Query LDAP.
	#
	declare -A _accounts=()
	mixed_stdouterr=$(ldapsearch -LLL -o ldif-wrap=no \
		-H "${domain_configs[${_listserv_domain}'_uri']}" \
		-D "${domain_configs[${_listserv_domain}'_bind_dn']}" \
		-w "${domain_configs[${_listserv_domain}'_bind_pw']}" \
		-b "${domain_configs[${_listserv_domain}'_search_base']}" \
		"(ObjectClass=person)" ${ldap_fields} 2>&1 > "${_ldif_file}") \
			|| log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" "${?}" "ldapsearch failed."
	log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "ldapsearch results were saved to ${_ldif_file}."
	#
	# Append the NULL character to the LDIF file, so we can detect that as EOF instead of a newline.
	#
	printf '\0' >> "${_ldif_file}"
	#
	# Substitute the blank line record separator with a # character and read records into an array.
	#
	IFS='#' read -r -d '' -a _ldif_records < <(sed 's/^$/#/' "${_ldif_file}") || log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" "${?}" "Parsing LDIF file (${_ldif_file}) into records failed."
	#
	# Loop over records in the array and create a faked-multi-dimensional hash.
	#
	local _ldif_record
	for _ldif_record in "${_ldif_records[@]}"; do
		#
		# Remove trailing white space like the new line character.
		# And skip blank lines.
		#
		_ldif_record="${_ldif_record%%[[:space:]]}"
		[[ "${_ldif_record}" == '' ]] && continue
		log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "LDIF record contains: ${_ldif_record}"
		#
		# Parse record's key:value pairs.
		#
		local -A _directory_record_attributes=()
		local    _ldif_line
		while IFS=$'\n' read -r _ldif_line; do
			[[ "${_ldif_line}" == '' ]] && continue # Skip blank lines.
			log4Bash 'TRACE' "${LINENO}" "${FUNCNAME:-main}" '0' "LDIF key:value pair contains: ${_ldif_line}."
			if [[ ${_ldif_line} =~ ${_ldap_attr_regex} ]]; then
				local _key="${BASH_REMATCH[1],,}" # Convert key on-the-fly to lowercase.
				local _sep="${BASH_REMATCH[2]}"
				local _value="${BASH_REMATCH[3]}"
				#
				# Check if value was base64 encoded (double colon as separator)
				# or plain text (single colon as separator) and decode if necessary.
				#
				if [[ "${_sep}" == '::' ]]; then
					log4Bash 'TRACE' "${LINENO}" "${FUNCNAME:-main}" '0' "     decoding base64 encoded value..."
					_value="$(printf '%s' "${_value}" | base64 -di)"
				fi
				#
				# This may be a multi-valued attribute and therefore check if key already exists;
				# When key already exists make sure we append instead of overwriting the existing value(s)!
				#
				if [[ ! -z "${_directory_record_attributes[${_key}]+isset}" ]]; then
					_directory_record_attributes["${_key}"]="${_directory_record_attributes[${_key}]} ${_value}"
				else
					_directory_record_attributes["${_key}"]="${_value}"
				fi
				log4Bash 'TRACE' "${LINENO}" "${FUNCNAME:-main}" '0' "     key   contains: ${_key}."
				log4Bash 'TRACE' "${LINENO}" "${FUNCNAME:-main}" '0' "     value contains: ${_value}."
			else
				log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" '1' "Failed to parse LDIF key:value pair (${_ldif_line})."
			fi
		done < <(printf '%s\n' "${_ldif_record}") || log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" "${?}" "Parsing LDIF record failed."
		#
		# Use processed LDIF record to manage subscription to mailing list.
		# (required fields are: cn givenName sn mail loginExpirationTime loginDisabled sshPublicKey)
		#
		local _account_name
		local _given_name=''
		local _sur_name=''
		local _family_name
		local _middle_name
		local _full_name
		local _email
		#
		# Get account/login name (required).
		#
		if [[ ! -z "${_directory_record_attributes['dn']+isset}" ]]; then
			#
			# Parse account name (cn) from dn.
			#
			_account_name=$(dn2cn "${_directory_record_attributes['dn']}")
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Processing _account_name: ${_account_name}."
			_accounts["${_account_name}"]='found'
		else
			log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" '1' "dn attribute (used as account name) missing for this ldif record."
		fi
		#
		# Skip (functional) accounts [optional].
		# There is no LDAP label/attribute to detect if an account is a functional or regular one for a "real" user,
		# therefore we currently rely on regular expressions to detect functional accounts based on naming schemes.
		# 
		local _no_subscription_account_name_pattern
		for _no_subscription_account_name_pattern in "${no_subscription_account_name_patterns[@]:-no_patterns_specified}"; do
			log4Bash 'TRACE' "${LINENO}" "${FUNCNAME:-main}" '0' "Checking if account: ${_account_name} matches pattern ${_no_subscription_account_name_pattern}."
			if [[ "${_account_name}" =~ ${_no_subscription_account_name_pattern} ]]; then
				log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Skipping account: ${_account_name} matching pattern ${_no_subscription_account_name_pattern}."
				continue 2
			else
				log4Bash 'TRACE' "${LINENO}" "${FUNCNAME:-main}" '0' "Account: ${_account_name} does not match pattern ${_no_subscription_account_name_pattern}."
			fi
		done
		#
		# Get user's name attributes and compile full "real" name (optional).
		#
		if [[ ! -z "${_directory_record_attributes['givenname']+isset}" ]]; then
			_given_name="${_directory_record_attributes['givenname']}"
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Found givenName: ${_given_name}."
			_full_name="${_given_name}"
		else
			log4Bash 'WARN' "${LINENO}" "${FUNCNAME:-main}" '0' "givenName attribute missing in ldif record for ${_account_name}."
		fi
		if [[ ! -z "${_directory_record_attributes['sn']+isset}" ]]; then
			_sur_name="${_directory_record_attributes['sn']}"
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Found sn: ${_sur_name}."
			#
			# Check for comma separated middle name suffixed in the sn field due to lack of proper middle name field.
			#
			if [[ "${_sur_name}" =~ ${_sn_regex} ]]; then
				_family_name="${BASH_REMATCH[1]}"
				_middle_name="${BASH_REMATCH[2]}"
				#
				# Append family name (and middle) when present.
				#
				if [[ ! -z "${_full_name:-}" ]]; then
					_full_name="${_full_name} ${_middle_name} ${_family_name}"
				else
					_full_name="${_middle_name} ${_family_name}"
				fi
			else
				_family_name="${_sur_name}"
				if [[ ! -z "${_full_name:-}" ]]; then
					_full_name="${_full_name} ${_family_name}"
				else
					_full_name="${_family_name}"
				fi
			fi
		else
			log4Bash 'WARN' "${LINENO}" "${FUNCNAME:-main}" '0' "sn attribute missing in ldif record for ${_account_name}."
		fi
		#
		# By default we assume all users must be subscribed.
		# When any of the required attributes is missing or has a 'wrong' value (e.g. account expired),
		# we switch _account_must_be_subscribed to 'no'.
		#
		local _account_must_be_subscribed='yes'
		if [[ -z "${_directory_record_attributes['mail']+isset}" ]]; then
			_account_must_be_subscribed='no'
			_accounts["${_account_name}"]='nomail'
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Skipping ldif record for ${_account_name}, because mail attribute is missing/empty."
			continue
		else
			_email="${_directory_record_attributes['mail']}"
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Found mail: ${_email}."
		fi
		if [[ -z "${_directory_record_attributes['sshpublickey']+isset}" ]]; then
			_account_must_be_subscribed='no'
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "sshPublicKey attribute is empty in ldif record for ${_account_name}."
		fi
		if [[ ! -z "${_directory_record_attributes['logindisabled']+isset}" && "${_directory_record_attributes['logindisabled']}" == 'TRUE' ]]; then
			_account_must_be_subscribed='no'
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "loginDisabled attribute is TRUE in ldif record for ${_account_name}."
		fi
		if [[ ! -z "${_directory_record_attributes['loginExpirationTime']+isset}" ]]; then
			local _expiration_date="${_directory_record_attributes['loginExpirationTime']+isset}"
			#
			# Convert both loginExpirationTime as well as current date into seconds since the POSIX time Epoch (January 1st 1970).
			# loginExpirationTime format example: "20170101165600Z"
			# required format for conversion with date command: "2017-01-01 16:56"
			#
			local _expiration_date_in_seconds_since_epoch
			if [[ "${_expiration_date}" =~ ${_timestamp_regex} ]]; then
				local _YYYY="${BASH_REMATCH[1]}"
				local _MM="${BASH_REMATCH[2]}"
				local _DD="${BASH_REMATCH[3]}"
				local _hh="${BASH_REMATCH[4]}"
				local _mm="${BASH_REMATCH[5]}"
				local _expiration_date_in_seconds_since_epoch=$(date -d "${YYYY}-${MM}-${DD} ${hh}:${mm}" '+%s') \
					|| log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" "${?}" "Failed to convert loginExpirationTime into seconds since Epoch."
				local _current_date_in_seconds_since_epoch=$(date '+%s') \
					|| log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" "${?}" "Failed to convert current date into seconds since Epoch."
				if [[ "${_expiration_date_in_seconds_since_epoch}" -lt "${current_date_in_seconds_since_epoch}" ]]; then
					_account_must_be_subscribed='no'
					log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Account ${_account_name} expired on ${YYYY}-${MM}-${DD} ${hh}:${mm}."
				else
					log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Account ${_account_name} has not expired."
				fi
			else
				_account_must_be_subscribed='unknown'
				log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" '1' "loginExpirationTime in unsupported format (and failed to convert to seconds since epoch): ${_expiration_date}."
			fi
		fi
		log4Bash 'TRACE' "${LINENO}" "${FUNCNAME:-main}" '0' "_account_must_be_subscribed=${_account_must_be_subscribed} for this ldif record."
		#
		# Append account name in round brackets to full name and
		# make sure the combination of e-mail address + full name with appended account name
		# does not exceed the listserv field size limit for this combination, which is 80 bytes.
		# Note that accented characters like é, ü, etc.
		# take up twice the size as a regular character without accents,
		# so we must count byte length and not plain regular string length.
		# The complete combination of e-mail address and full name format contains:
		#		_email _given_name _middle_name _family_name (_account_name)
		#		_email <------------------_full_name----------------------->
		# We need the complete _account_name between round brackets,
		# so we have to truncate the _given_name _middle_name _family_name combination
		# if it exceeds:
		# 80 minus 4 (for 2 spaces & round opening and closing brackets) and
		#    minus the byte length of _account_name and
		#    minus the byte length of _email
		#
		if [[ -n "${_full_name:-}" ]]; then
			local _max_full_name_length
			local _full_name_length
			local _account_name_length
			local _email_length
			_full_name_length="$(printf '%s' "${_full_name}" | wc -c)"
			_account_name_length="$(printf '%s' "${_account_name}" | wc -c)"
			_email_length="$(printf '%s' "${_email:-}" | wc -c)"
			_max_full_name_length=$((80 - 4 - ${_account_name_length} - ${_email_length}))
			if [[ "${_full_name_length}" -gt "${_max_full_name_length}" ]]; then
				#
				# Use truncated name, because it is too long for listserv.
				#
				_full_name="$(printf '%s' "${_full_name}" | cut -b "1-$((${_max_full_name_length} - 3))")... (${_account_name})"
			else
				_full_name="${_full_name} (${_account_name})"
			fi
		else
			_full_name="(${_account_name})"
		fi
		log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Compiled full real name: ${_full_name:-}."
		#
		# subscriptions["${_account_name}"]="${_email}|${_full_name}"
		# _full_name="${_given_name} ${_middle_name} ${_family_name} (${_account_name})"
		#
		if [[ ! -z "${subscriptions["${_account_name}"]+isset}" && "${_account_must_be_subscribed}" == 'no' ]]; then
			_accounts["${_account_name}"]='disabled'
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Unsubscribing expired/inactive account ${_account_name} from '${_mailinglist}' mailing list..."
			sendListservCommand "${_mailinglist}" "${notify_users}" 'DELETE' "${_email}"
		elif [[ -z "${subscriptions["${_account_name}"]+isset}" && "${_account_must_be_subscribed}" == 'yes' ]]; then
			_accounts["${_account_name}"]='active'
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Subscribing new account ${_account_name} to '${_mailinglist}' mailing list..."
			sendListservCommand "${_mailinglist}" "${notify_users}" 'ADD' "${_email}" "${_full_name}"
		elif [[ ! -z "${subscriptions["${_account_name}"]+isset}" && "${_account_must_be_subscribed}" == 'yes' ]]; then
			_accounts["${_account_name}"]='active'
			if [[ "${subscriptions["${_account_name}"]}" =~ ${_subscription_regex} ]]; then
				local _subscribed_email="${BASH_REMATCH[1]}"
				local _subscribed_full_name="${BASH_REMATCH[2]}"
				#
				# Listserv converts the domain name part of the subscribed email address to UPPERCASE.
				# Therefore we convert the complete email address variables to lowercase before comparing them.
				# Hence we ignore lowercase vs. UPPERCASE for detecting a changed email address.
				#
				if [[ "${_subscribed_email,,}|${_subscribed_full_name}" == "${_email,,}|${_full_name}" ]]; then
					log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Subscription for ${_account_name} is still up to date."
				elif [[ "${_subscribed_email,,}" != "${_email,,}" && "${_subscribed_full_name}" == "${_full_name}" ]]; then
					#
					# Update only the email address for this subscribed user.
					# User will receive the a notification based on the CHANGE1 template.
					#
					log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Updating email address for account ${_account_name}..."
					sendListservCommand "${_mailinglist}" "${notify_users}" 'CHANGE' "${_subscribed_email}" "${_email}"
				elif [[ "${_subscribed_email,,}" == "${_email,,}" && "${_subscribed_full_name}" != "${_full_name}" ]]; then
					#
					# Use hardcoded notify_users=0 to do a QUIET ADD,
					# which will only update the name of the subscribed user,
					# without sending a "welcome new user" notification email.
					#
					log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Updating name for account ${_account_name}..."
					sendListservCommand "${_mailinglist}" '0' 'ADD' "${_email}" "${_full_name}"
				else
					#
					# Both the email address as well as the full name of the user have changed.
					# Mostly likely a (functional) account got recycled
					#  -> unsubscribe (delete) the old user and subscribe (add) the new user.
					#
					log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Unsubscribing and resubscribing changed account ${_account_name}..."
					sendListservCommand "${_mailinglist}" "${notify_users}" 'DELETE' "${_subscribed_email}"
					sendListservCommand "${_mailinglist}" "${notify_users}" 'ADD' "${_email}" "${_full_name}"
				fi
			else
				log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" '1' "Failed to split subscriber info using a pipe as separator for ${_account_name}. Contact an admin."
			fi
		elif [[ -z "${subscriptions["${_account_name}"]+isset}" && "${_account_must_be_subscribed}" == 'no' ]]; then
			_accounts["${_account_name}"]='disabled'
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Skipping inactive account ${_account_name} that is not on the mailing list and should not be subscribed..."
		else
			_accounts["${_account_name}"]='strange'
			log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" '1' "I do not know how to handle ${_account_name}. Contact an admin."
		fi
	done
	#
	# Check if all subscribers still have an account for this entitlement 
	# and hence if they got processed using the code above.
	# Unsubscribe any users who no longer can be found in the LDAP
	# or who no longer have an email address configured in the LDAP.
	#
	local _subscribed_account
	for _subscribed_account in "${!subscriptions[@]}"; do
		if [[ ! -z "${_accounts["${_subscribed_account}"]+isset}" && "${_accounts["${_subscribed_account}"]}" != 'nomail' ]]; then
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Subscribed account ${_subscribed_account} was found in the LDAP and processed."
		else
			log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Subscribed account ${_subscribed_account} was not found in the LDAP or no longer has an email address configured and will be unsubscribed..."
			if [[ "${subscriptions["${_subscribed_account}"]}" =~ ${_subscription_regex} ]]; then
				local _subscribed_email="${BASH_REMATCH[1]}"
				log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Unsubscribing account ${_subscribed_account}..."
				sendListservCommand "${_mailinglist}" "${notify_users}" 'DELETE' "${_subscribed_email}"
			else
				log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" '1' "Failed to split subscriber info using a pipe as separator for ${_subscribed_account}. Contact an admin."
			fi
		fi
	done
}

function sendListservCommand () {
	#
	local _mailinglist="${1}"
	local _notify_users="${2}"
	local _command="${3}"
	local _email="${4}"
	local _name="${5:-}" # optional; not required for DELETE command.
	local _body
	#
	log4Bash 'TRACE' "${LINENO}" "${FUNCNAME:-main}" 0 "Args: _mailinglist=${_mailinglist}|_notify_users=${_notify_users}|_command=${_command}|email=${_email}|_name=${_name}."
	#
	# Use QUIET in front of command to disable sending notification messages to users.
	# The // at the beginning of the line is listserv syntax for a command that spans multiple lines.
	# (Putting everything on one line may result in truncated data, when a line exceeds 80 characters.)
	#
	if [[ "${_notify_users}" -eq '0' ]]; then
		_body='// QUIET '
	elif [[ "${_notify_users}" -eq '1' ]]; then
		_body='// '
	else
		log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" '1' "I expected 0 or 1 for _notify_users, but got _notify_users=${_notify_users}. Contact an admin."
	fi
	_body="${_body} ${_command} ${_mailinglist} ${_email} ,\n${_name:-}"
	
	if [[ "${update_subscriptions}" -eq '1' ]]; then
		log4Bash 'INFO' "${LINENO}" "${FUNCNAME:-main}" 0 "Sending command (${_body}) by email on behalf of ${listserv_api_email_from} to ${listserv_api_email_to}..."
		mixed_stdouterr="$(printf '%b\n' "${_body}" | mail -s '' -r "${listserv_api_email_from}" "${listserv_api_email_to}" 2>&1)" \
			|| log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" "${?}" "Failed to send command (${_body}) by email on behalf of ${listserv_api_email_from} to ${listserv_api_email_to}."
	else
		log4Bash 'INFO' "${LINENO}" "${FUNCNAME:-main}" '0' "DRY RUN: would send command (${_body}) by email on behalf of ${listserv_api_email_from} to ${listserv_api_email_to}..."
	fi
}

#
# Extract a CN from a DN LDAP attribute.
#
function dn2cn () {
	# cn=umcg-someuser,ou=users,ou=umcg,o=rs
	local _dn="${1}"
	local _cn='MIA'
	local _regex='cn=([^, ]+)'
	if [[ ${_dn} =~ ${_regex} ]]; then
		_cn="${BASH_REMATCH[1]}"
	fi
	printf '%s' "${_cn}"
}

#
##
### Variables.
##
#
mixed_stdouterr='' # global variable to capture output from commands for reporting in custom log messages.

#
# Initialise Log4Bash logging with defaults.
#
l4b_log_level="${log_level:-INFO}"
declare -A l4b_log_levels=(
	['TRACE']='0'
	['DEBUG']='1'
	['INFO']='2'
	['WARN']='3'
	['ERROR']='4'
	['FATAL']='5'
)
l4b_log_level_prio="${l4b_log_levels[${l4b_log_level}]}"

#
##
### Main.
##
#

#
# Get commandline arguments.
#
declare update_subscriptions='0'
declare notify_users='0'
while getopts "l:b:unh" opt; do
	case $opt in
		h)
			showHelp
			;;
		b)
			backup_dir="${OPTARG}"
			;;
		u)
			update_subscriptions='1'
			;;
		n)
			notify_users='1'
			;;	
		l)
			l4b_log_level=${OPTARG^^}
			l4b_log_level_prio=${l4b_log_levels[${l4b_log_level}]}
			;;
		\?)
			log4Bash "${LINENO}" "${FUNCNAME:-main}" '1' "Invalid option -${OPTARG}. Try $(basename $0) -h for help."
			;;
		:)
			log4Bash "${LINENO}" "${FUNCNAME:-main}" '1' "Option -${OPTARG} requires an argument. Try $(basename $0) -h for help."
			;;
		esac
done

if [[ "${update_subscriptions}" -eq '1' ]]; then
	log4Bash 'INFO' "${LINENO}" "${FUNCNAME:-main}" '0' 'Found option -u: will update mailing list subscriptions.'
else
	log4Bash 'INFO' "${LINENO}" "${FUNCNAME:-main}" '0' 'Option -u not specified: will only perform a "dry run" to show what needs to be updated. Use -u to update subscriptions.'
fi
if [[ "${notify_users}" -eq '1' ]]; then
	log4Bash 'INFO' "${LINENO}" "${FUNCNAME:-main}" '0' 'Found option -n: will notify users when they are added to / changed on / deleted from the mailing list.'
else
	log4Bash 'INFO' "${LINENO}" "${FUNCNAME:-main}" '0' 'Option -n not specified: will not notify users.'
fi

#
# Parse LDAP config file.
#
if [[ -e  "${ldap_config_file}" && -r "${ldap_config_file}" ]]; then
	log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" '0' "Fetching ldapsearch credentials from config file ${ldap_config_file} ..."
	# shellcheck source=/dev/null
	source "${ldap_config_file}"
else
	log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" '1' "Config file ${ldap_config_file} missing or not readable."
fi

#
# Compile list of LDAP fields to retrieve.
#
ldap_fields='cn givenName sn mail loginExpirationTime loginDisabled sshPublicKey'
log4Bash 'TRACE' "${LINENO}" "${FUNCNAME:-main}" '0' "ldap_fields to retrieve = ${ldap_fields}."

#
# Create tmp dir.
#
mixed_stdouterr=$(mkdir -m 0700 -p "${TMPDIR}/${SCRIPT_NAME}/" 2>&1) \
	|| log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" "${?}" "Failed to create tmp dir ${TMPDIR}/${SCRIPT_NAME}/."
#
# Process LDAP domains.
#
if [[ "${#listserv_domains[@]}" -lt 1 ]]; then
	log4Bash 'WARN' "${LINENO}" "${FUNCNAME:-main}" 0 'The ${listserv_domains[@]} list is empty: there are no mailing lists to process.'
else
	for listserv_domain in "${listserv_domains[@]}"; do
		log4Bash 'INFO' "${LINENO}" "${FUNCNAME:-main}" '0' "Processing listserv_domain ${listserv_domain}..."
		#
		# Get current subscribers from mailing list server.
		#
		declare -A subscriptions=()
		getSubscriptions "${listserv_domain}"
		#
		# Query LDAP and add/update/delete subscriptions.
		#
		manageSubscriptions "${listserv_domain}"
	done
fi

#
# Cleanup.
#
if [ ${l4b_log_level_prio} -lt ${l4b_log_levels['INFO']} ]; then
	log4Bash 'DEBUG' "${LINENO}" "${FUNCNAME:-main}" 0 "Debug mode: temporary files in ${TMPDIR}/${SCRIPT_NAME}/ won't be removed."
else
	mixed_stdouterr=$(rm -Rf "${TMPDIR}/${SCRIPT_NAME}/" 2>&1) \
		|| log4Bash 'FATAL' "${LINENO}" "${FUNCNAME:-main}" "${?}" "Failed to remove tmp dir ${TMPDIR}/${SCRIPT_NAME}/."
fi

#
# Reset trap and exit.
#
log4Bash 'INFO' "${LINENO}" "${FUNCNAME:-main}" 0 "Finished!"
trap - EXIT
exit 0

{% endraw %}
