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
#    or: run_with_timeout cmd args...
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
    # Check if permissions on home dir are correct if home dir exists.
    #
    if [[ "${PAM_USER}" != 'root' ]]; then
      home_dir="/home/${PAM_USER}/"
      if [[ -e "${home_dir}" ]]; then
        owner=$(stat -L -c '%U' "${home_dir}")
        group=$(stat -L -c '%G' "${home_dir}")
        mode=$(stat -L -c '%a' "${home_dir}")
        if [[ "${owner}" != "${PAM_USER}" ]]; then
          ${LOGGER} "ERROR: Home dir for user ${PAM_USER} is owned by: ${owner}."
          ${LOGGER} "WARN: Fixing owner for ${home_dir} ${owner} -> ${PAM_USER} ..."
          chown --dereference --silent "${PAM_USER}" "${home_dir}"
        fi
        if [[ "${group}" != "${PAM_USER}" ]]; then
          ${LOGGER} "ERROR: Home dir for user ${PAM_USER} is in the wrong group: ${group}."
          ${LOGGER} "WARN: Fixing group for ${home_dir} ${group} -> ${PAM_USER} ..."
          chgrp --dereference --silent "${PAM_USER}" "${home_dir}"
        fi
        mode_regex='700$'
        if [[ ! "${mode}" =~ ${mode_regex} ]]; then
          ${LOGGER} "ERROR: Home dir for user ${PAM_USER} has wrong permissions mode: ${mode}."
          ${LOGGER} "WARN: Fixing permissions for ${home_dir} ${mode} -> 700 ..."
          chmod --silent 700 "${home_dir}"
        fi
      fi
    fi
}

#
##
### Main.
##
#

#
# Run the desired login actions with a timeout of 10 seconds.
#
run_with_timeout 10 login_actions

exit 0
