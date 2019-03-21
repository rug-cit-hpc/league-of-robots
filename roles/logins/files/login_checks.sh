#!/bin/bash

set -u

#
##
### Variables.
##
#
SLURM_ACCOUNT='users'
# Set a tag for the log entries.
LOGGER='logger --tag login_checks'

#
##
### Functions.
##
#

#
# Usage: run_with_timeout N cmd args...
#    or: run_with_timeout cmd args...
# In the second case, cmd cannot be a number and the timeout will be 10 seconds.
#
run_with_timeout () {
    local time=10
    if [[ $1 =~ ^[0-9]+$ ]]; then time=$1; shift; fi
    #
    # Run in a subshell to avoid job control messages.
    #
    ( "$@" &
        child=$!
        #
        # Avoid default notification in non-interactive shell for SIGTERM.
        #
        trap -- "" SIGTERM
        ( sleep $time
            kill $child 2> /dev/null
        ) &
        wait $child
    )
}

login_actions () {
    #
    # Check if login user exists as SLURM user in the SLURM accounting DB.
    #
    if [ "$(sacctmgr -p list user "${PAM_USER}" format=User | grep -o "${PAM_USER}")" == "${PAM_USER}" ]; then
      if [ "${PAM_USER}" != 'root' ]; then
        # Only log for users other than root to prevend flooding the logs...
        $LOGGER "User ${PAM_USER} already exists in SLURM DB."
      fi
    else
        #
        # Create account in SLURM accounting DB.
        #
        local _log_message="Creating user ${PAM_USER} in SLURM accounting DB..."
        local _status="$(sacctmgr -iv create user name=${PAM_USER} account=${SLURM_ACCOUNT} fairshare=1 2>&1)"
        #
        # Checking for exit status does not work when executed by pam-script :(
        # Therefore we explicitly re-check if the user now exists in the SLURM DB...
        #
        #if [ $? -eq 0 ]; then
        if [ "$(sacctmgr -p list user "${PAM_USER}" format=User | grep -o "${PAM_USER}")" == "${PAM_USER}" ]; then
            _log_message="${_log_message}"' done!'
        else
            _log_message="${_log_message}"' FAILED. You cannot submit jobs. Contact an admin!'
            $LOGGER "${_status}"
        fi
        $LOGGER -s "${_log_message}"
    fi
}

#
##
### Main.
##
#

#
# Make sure we execute this file only for interactive sessions with a real shell.
# Hence not for SFTP connections,
# which will terminate instantly when anything that is not a valid FTP command is printed on STDOUT or STDERR.
# For SFTP connections as well as SLURM jobs the TERM type is dumb,
# but in the first case there are no SLURM related environment variables defined.
#

#
# ToDo: fix this. As of CentOS 7.x interactive session that eventually report ${TERM} == 'bash'
# report ${TERM} == 'dumb' at the point where this script is executed in the PAM stack :(.
# Makes it impossible to determine the difference between an SFTP session versus a Bash session.
#
if [ ${TERM} == 'dumb' ] && [ -z "${SOURCE_HPC_ENV:-}" ]; then
    $LOGGER "debug: exiting because of dumb terminal"
    exit 0
fi

#
# Run the desired login actions with a timeout of 10 seconds.
#
run_with_timeout 10 login_actions

exit 0
