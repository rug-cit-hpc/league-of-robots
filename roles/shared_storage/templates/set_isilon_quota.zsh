#!/bin/zsh

set -e
set -u

#
# Global variables.
#
declare pfs_base_path='/ifs/rekencluster'
declare pfs_name_prefix='umcgst'
declare TMPDIR="${TMPDIR:-/tmp}" # Default to /tmp if ${TMPDIR} was not defined.
declare SCRIPT_NAME
SCRIPT_NAME="$(basename "${0}" '.bash')"
export TMPDIR
export SCRIPT_NAME
declare mixed_stdouterr='' # global variable to capture output from commands for reporting in custom log messages.

#
# Initialise Log4Zsh logging with defaults.
#
l4z_log_level="${log_level:-INFO}"
declare -A l4z_log_levels
l4z_log_levels=(
	'TRACE' '0'
	'DEBUG' '1'
	'INFO'  '2'
	'WARN'  '3'
	'ERROR' '4'
	'FATAL' '5'
)
l4z_log_level_prio="${l4z_log_levels[${l4z_log_level}]}"

#
# Make sure dots are used as decimal separator.
#
LANG='en_US.UTF-8'
LC_NUMERIC="${LANG}"

#
##
### functions
##
#
function showHelp() {
	#
	# Display commandline help on STDOUT.
	#
	cat <<EOH
===============================================================================================================
Script to apply quota settings to shares served by an Isilon OneFS cluster.
Quota settings are parsed from cache files stored on the shares.

Usage:

	${SCRIPT_NAME} OPTIONS

OPTIONS:

	-h   Show this help.
	-a   Apply (new) settings to the File System(s).
	     By default this script will only do a "dry run" and fetch + list the settings.
	-l   Log level.
	     Must be one of TRACE, DEBUG, INFO (default), WARN, ERROR or FATAL.

Details:

	Values are always reported with a dot as the decimal seperator (LC_NUMERIC="en_US.UTF-8").
===============================================================================================================

EOH
	#
	# Reset trap and exit.
	#
	trap 'trap - EXIT' EXIT
	exit 0
}

#
# Catch all function for logging using log levels like in Log4j.
# ARGS: LOG_LEVEL, LINENO, FUNCNAME, EXIT_STATUS and LOG_MESSAGE.
#
function log4Zsh() {
	#	
	# Validate params.
	#
	if [ ! "${#}" -eq 5 ] ;then
		echo "WARN: should have passed 5 arguments to ${FUNCNAME[0]}: log_level, LINENO, FUNCNAME, (Exit) STATUS and log_message."
	fi
	#
	# Determine prio.
	#
	local _log_level="${1}"
	local _log_level_prio="${l4z_log_levels[$_log_level]}"
	local _status="${4:-$?}"
	#
	# Log message if prio exceeds threshold.
	#
	if [[ "${_log_level_prio}" -ge "${l4z_log_level_prio}" ]]; then
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
		local _log_timestamp
		local _log_line_prefix
		_log_timestamp=$(date "+%Y-%m-%dT%H:%M:%S") # Creates ISO 8601 compatible timestamp.
		_log_line_prefix=$(printf "%-s %-s %-5s @ L%-s(%-s)>" "${SCRIPT_NAME}" "${_log_timestamp}" "${_log_level}" "${_problematic_line}" "${_problematic_function}")
		local _log_line="${_log_line_prefix} ${_log_message}"
		if [[ -n "${mixed_stdouterr:-}" ]]; then
			_log_line="${_log_line} STD[OUT+ERR]: ${mixed_stdouterr}"
		fi
		if [[ "${_status}" -ne 0 ]]; then
			_log_line="${_log_line} (Exit status = ${_status})"
		fi
		#
		# Log to STDOUT (low prio <= 'WARN') or STDERR (high prio >= 'ERROR').
		#
		if [[ "${_log_level_prio}" -ge "${l4z_log_levels[ERROR]}" || "${_status}" -ne 0 ]]; then
			printf '%s\n' "${_log_line}" > '/dev/stderr'
		else
			printf '%s\n' "${_log_line}"
		fi
	fi	
	#
	# Exit if this was a FATAL error.
	#
	if [[ "${_log_level_prio}" -ge "${l4z_log_levels[FATAL]}" ]]; then
		#
		# Reset trap and exit.
		#
		trap 'trap - EXIT' EXIT
		if [[ "${_status}" -ne 0 ]]; then
			exit "${_status}"
		else
			exit 1
		fi
	fi
}

#
# Custom signal trapping functions (one for each signal) required to format log lines depending on signal.
#
function trapHandler() {
	local _signal="${1}"
	local _line="${2}"
	local _function="${3}"
	local _status="${4}"
	log4Zsh 'FATAL' "${_line}" "${_function}" "${_status}" "Trapped ${_signal} signal."
}

#
# Trap all exit signals: HUP(1), INT(2), QUIT(3), TERM(15), ERR.
#
TRAPHUP() {
	trapHandler 'HUP' "${LINENO}" "${FUNCNAME[0]:-main}" "${?}"
}
TRAPINT() {
	trapHandler 'INT' "${LINENO}" "${FUNCNAME[0]:-main}" "${?}"
}
TRAPQUIT() {
	trapHandler 'QUIT' "${LINENO}" "${FUNCNAME[0]:-main}" "${?}"
}
TRAPTERM() {
	trapHandler 'TERM' "${LINENO}" "${FUNCNAME[0]:-main}" "${?}"
}
TRAPEXIT() {
	local _exit_signal="${?}"
	if [[ "${_exit_signal}" -ne 0 ]]; then
		trapHandler 'EXIT' "${LINENO}" "${FUNCNAME[0]:-main}" "${?}"
	else
		log4Zsh 'WARN' "${LINENO}" "${FUNCNAME[0]:-main}" '0' "Ignoring exit zero."
	fi
	printf '%s' "DEBUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"
}
TRAPERR() {
	trapHandler 'ERR' "${LINENO}" "${FUNCNAME[0]:-main}" "${?}"
}

#
# Apply quota using "isi" commands.
#
function setIisilonDirectoryQuota () {
	local _path="${1}"
	local _soft_limit="${2}"
	local _hard_limit="${3}"
	local _grace_period="${4}"
	if [[ "${apply_settings}" -eq 1 ]]; then
		log4Zsh 'INFO' "${LINENO}" "${FUNCNAME[0]:-main}" '0' "Running 'isi quota quotas create' for ${_path} with limits soft=${_soft_limit}, hard=${_hard_limit} and grace=${_grace_period} ..."
		isi quota quotas create "${_path}" directory --enforced=true --container=true \
			--soft-threshold="${_soft_limit}" \
			--hard-threshold="${_hard_limit}" \
			--soft-grace="${_grace_period}"
	else
		log4Zsh 'INFO' "${LINENO}" "${FUNCNAME[0]:-main}" '0' "Dry run: compiled 'isi quota quotas create' command for ${_path} with limits soft=${_soft_limit}, hard=${_hard_limit} and grace=${_grace_period}."
	fi
}

#
##
### Main
##
#

#
# Get commandline arguments.
#
declare apply_settings=0
while getopts ":l:ah" opt; do
	case "${opt}" in
		h)
			showHelp
			;;
		a)
			apply_settings=1
			;;
		l)
			l4z_log_level="${OPTARG:u}"
			l4z_log_level_prio="${l4z_log_levels[${l4z_log_level}]}"
			;;
		\?)
			log4Zsh 'FATAL' "${LINENO}" "${FUNCNAME[0]:-main}" '1' "Invalid option -${OPTARG}. Try ${SCRIPT_NAME} -h for help."
			;;
		:)
			log4Zsh 'FATAL' "${LINENO}" "${FUNCNAME[0]:-main}" '1' "Option -${OPTARG} requires an argument. Try ${SCRIPT_NAME} -h for help."
			;;
		esac
done

log4Zsh 'INFO' "${LINENO}" "${FUNCNAME[0]:-main}" '0' "Configuring quota ..."
#
# Find Physical File Systems/Shares (PFS-ses)
#
if [[ -e "${pfs_base_path}" ]]; then
	log4Zsh 'TRACE' "${LINENO}" "${FUNCNAME[0]:-main}" '0' "${pfs_base_path} exists."
else
	log4Zsh 'FATAL' "${LINENO}" "${FUNCNAME[0]:-main}" '1' "${pfs_base_path} does not exist."
fi
log4Zsh 'TRACE' "${LINENO}" "${FUNCNAME[0]:-main}" '0' "Search for PFS-ses with prefix ${pfs_name_prefix} in ${pfs_base_path} ..."
declare -a pfss
pfss=("${(f)$(find "${pfs_base_path}" -mindepth 1 -maxdepth 1 -type d -name "${pfs_name_prefix}*")}")
log4Zsh 'TRACE' "${LINENO}" "${FUNCNAME[0]:-main}" '0' "Search for PFS-ses in ${pfs_base_path} done!"
if [[ "${#pfss[@]}" -eq 0 ]]; then
	log4Zsh 'FATAL' "${LINENO}" "${FUNCNAME[0]:-main}" '1' "No PFS-ses starting with prefix ${pfs_name_prefix} found in ${pfs_base_path}."
else
	log4Zsh 'TRACE' "${LINENO}" "${FUNCNAME[0]:-main}" '0' "Found ${#pfss[@]} PFS-ses starting with prefix ${pfs_name_prefix} found in ${pfs_base_path}."
fi
#
# Search for Logical File Systems/Shares (LFS-ses) on each of the PFS-ses.
#
for pfs in "${pfss[@]}"; do
	if [[ -e "${pfs}/home" ]]; then
		log4Zsh 'INFO' "${LINENO}" "${FUNCNAME[0]:-main}" '0' "Processing LFS home on PFS ${pfs} ..."
		declare -a home_dirs
		home_dirs=($(find "${pfs}/home/" -mindepth 1 -maxdepth 1 -type d))
		if [[ "${#home_dirs[@]:-0}" -eq 0 ]]; then
			log4Zsh 'TRACE' "${LINENO}" "${FUNCNAME[0]:-main}" '0' "No home dirs found in ${pfs}/home/."
		else
			for home_dir in "${home_dirs[@]}"; do
				setIisilonDirectoryQuota "${home_dir}" '1G' '2G' '7D'
			done
		fi
	fi
done

#
# Reset trap and exit.
#
log4Zsh 'INFO' "${LINENO}" "${FUNCNAME[0]:-main}" 0 'Finished!'
trap 'trap - EXIT' EXIT
exit 0
