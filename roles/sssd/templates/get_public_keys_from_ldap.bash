#!/bin/bash

#
# Custom script top fetch public keys from one or more LDAP servers.
#
#  * Fetches public keys
#     * For regular users from the LDAP: from LDAP using default ssh-ldap-helper or
#     * For local admin users: from a local ~/.ssh/authorized_keys file.
#  * Filters the public keys by dropping unsupported key types or short key sizes considered weak.
#
# Note that
#  * /usr/libexec/openssh/ssh-ldap-helper:
#      Cannot handle multiple LDAP servers for users from multiple domains.
#  * /usr/bin/sss_ssh_authorizedkeys:
#      Cannot handle multiple public keys per user when the public keys are stored in OpenSSH format.
#

declare -a domain_names=({% for ldap_domain, ldap_config in ldap_domains.items() %}'{{ ldap_domain }}'{% if not loop.last %} {% endif %}{% endfor %})
declare -A domain_configs=(
{% for ldap_domain, ldap_config in ldap_domains.items() %}
    [{{ ldap_domain }}_uri]='{{ ldap_config['uri'] }}'
    [{{ ldap_domain }}_search_base]='{{ ldap_config['base'] }}'
    [{{ ldap_domain }}_bind_dn]='{{ ldap_credentials[ldap_domain]['readonly']['dn'] }}'
    [{{ ldap_domain }}_bind_pw]='{{ ldap_credentials[ldap_domain]['readonly']['pw'] }}'
    [{{ ldap_domain }}_user_object_class]='{{ ldap_config['user_object_class'] }}'
    [{{ ldap_domain }}_user_name]='{{ ldap_config['user_name'] }}'
    [{{ ldap_domain }}_user_ssh_public_key]='{{ ldap_config['user_ssh_public_key'] }}'
{% endfor %}
)
declare admin_gid='{{ auth_groups['admin']['gid'] }}'
{% raw %}
#
# No more Ansible variables below this point!
#
export LDAPTLS_CACERT=/etc/pki/tls/certs/ca-bundle.trust.crt
declare user="${1}"
declare base64='/usr/bin/base64'
declare grep='/usr/bin/grep'
declare ldapsearch='/usr/bin/ldapsearch'
declare ssh_keygen='/usr/bin/ssh-keygen'
declare minimal_rsa_key_size='4096'
declare -a authorized_keys=()

#
##
### Functions.
##
#

function filterKeys() {
  local _public_key="${1}"
  local _fingerprint_value
  local _fingerprint_regex='^([0-9][0-9]*) .* \((.*)\)$'
  #echo "DEBUG: checking public key: ${_public_key:-}" 1>&2
  test -z "${_public_key:-}" && return
  _fingerprint_value="$("${ssh_keygen}" -l -f /dev/stdin <<< "${_public_key}")"
  if [[ "${_fingerprint_value}" =~ ${_fingerprint_regex} ]]; then
    local _key_size="${BASH_REMATCH[1]}"
    local _key_type="${BASH_REMATCH[2]}"
    if [[ "${_key_type}" == 'ED25519' ]]; then
      authorized_keys=("${authorized_keys[@]}" "${_public_key}")
    elif [[ "${_key_type}" == 'RSA' ]] && [[ "${_key_size}" -ge "${minimal_rsa_key_size}" ]]; then
      authorized_keys=("${authorized_keys[@]}" "${_public_key}")
    else
      echo "WARN: Skipping unsupported ${_key_size} bit ${_key_type} key." 1>&2
    fi
  else
    echo "ERROR: Failed to parse key fingerprint ${_fingerprint_value:-}." 1>&2
  fi
}

function getPublicKeysFromLDAP() {
  local _ldap
  for _ldap in "${domain_names[@]}"; do
    local _uri="${domain_configs[${_ldap}_uri]}"
    local _search_base="${domain_configs[${_ldap}_search_base]}"
    local _bind_dn="${domain_configs[${_ldap}_bind_dn]}"
    local _bind_pw="${domain_configs[${_ldap}_bind_pw]}"
    local _user_object_class="${domain_configs[${_ldap}_user_object_class]}"
    local _user_name="${domain_configs[${_ldap}_user_name]}"
    local _user_ssh_public_key_attr="${domain_configs[${_ldap}_user_ssh_public_key]}"
    local _user_ssh_public_key_regex="${_user_ssh_public_key_attr}(::*) (.*)"
    local _ldap_query_results
    #echo 'DEBUG: Querying LDAP using:' 1>&2
    #echo "       ${ldapsearch} -LLL -o ldif-wrap=no" 1>&2
    #echo "    -H ${_uri}"  1>&2
    #echo "    -D ${_bind_dn}"  1>&2
    #echo "    -w ${_bind_pw}"  1>&2
    #echo "    -b ${_search_base}"  1>&2
    #echo "       (&(ObjectClass=${_user_object_class})(uid:=${user}))" 1>&2
    #echo "       ${_user_ssh_public_key_attr}" 1>&2
    #echo "    | ${grep} ${_user_ssh_public_key_attr}" 1>&2
    #
    # Get public keys using ldapsearch command.
    #
    _ldap_query_results=$("${ldapsearch}" -LLL -o ldif-wrap=no \
        -H "${_uri}" \
        -D "${_bind_dn}" \
        -w "${_bind_pw}" \
        -b "${_search_base}" \
           "(&(ObjectClass=${_user_object_class})(${_user_name}=${user}))" \
           "${_user_ssh_public_key_attr}" \
        | "${grep}" "${_user_ssh_public_key_attr}")
    if [[ -z "${_ldap_query_results}" ]]; then
      #echo "DEBUG: User ${user} or its ${_user_ssh_public_key_attr} LDAP attribute does not exist in ${_ldap} LDAP." 1>&2
      continue
    fi
    local _ldap_query_result_line
    readarray -t _ldap_query_result_lines <<< "${_ldap_query_results}"
    for _ldap_query_result_line in "${_ldap_query_result_lines[@]}"; do
      local _separator
      local _user_ssh_public_key_value
      local _public_key
      if [[ "${_ldap_query_result_line}" =~ ${_user_ssh_public_key_regex} ]]; then
        _separator="${BASH_REMATCH[1]}"
        _user_ssh_public_key_value="${BASH_REMATCH[2]}"
        #echo "DEBUG: Found ${_user_ssh_public_key_attr} LDAP attribute:" 1>&2
        #echo "${_user_ssh_public_key_value}" 1>&2
      else
        echo "ERROR: Failed to parse LDAP attribute ${_user_ssh_public_key_attr} in LDAP query result line: ${_ldap_query_result_line:-}." 1>&2
        continue
      fi
      if [[ "${_separator}" == ':' ]]; then
        while read -r _public_key; do
          test -z "${_public_key:-}" && continue
          filterKeys "${_public_key}"
        done < <(printf '%s\n' "${_user_ssh_public_key_value}" && echo)
      elif [[ "${_separator}" == '::' ]]; then
        while read -r _public_key; do
          test -z "${_public_key:-}" && continue
          filterKeys "${_public_key}"
        done < <(printf '%s\n' "${_user_ssh_public_key_value}" | "${base64}" -di && echo)
      else
        echo "ERROR: Got an unsupported key value separator ${_separator} in LDAP query result line:: ${_ldap_query_result_line:-}." 1>&2
        continue
      fi
    done
  done
}

#
##
### Main.
##
#

#
# Check if specified user exists.
#
if id "${user:-missing}" >/dev/null 2>&1; then
  if [[ "$(id -g "${user}")" == "${admin_gid}" ]]; then
    #
    # Use ~/.ssh/authorized_keys file from a local home dir for members of the admin group,
    # so admins can still login in case of an LDAP (connection) failure.
    #
    key_file="$(getent passwd "${user}" | cut -d: -f6)/.ssh/authorized_keys"
    while read -r public_key; do
      filterKeys "${public_key}"
    done < "${key_file}"
  else
    #
    # Fetch public keys from LDAP server for non-admin users.
    #
    getPublicKeysFromLDAP
  fi
else
  echo "ERROR: user ${user:-} does not exist." 1>&2
  exit
fi

#
# Return filtered public keys.
#
( printf '%s\n' "${authorized_keys[@]}" ) || exit 0

{% endraw %}
