#!/usr/bin/env bash

#
# This file should be located in /etc/profile.d/,
# so it will get sourced upon login.
#

totp_config="{{ sshd_user_totp_config_path }}"
totp_dir="$(dirname "${totp_config}")"

{% raw %}

function totp-configure() {
	export HISTCONTROL=ignorespace:ignoredups
	if [[ -e "${totp_config}" ]]; then
		echo
		printf 'ERROR: %s\n' "${totp_config} already exists."
		printf '       %s\n' '  * Either delete this file and try again to reconfigure TOTPs generating a new secret.'
		printf '       %s\n' '  * Or use the "totp-show-QR-code" command to configure a new device reuseing the existing secret.'
		echo
		return
	elif [[ ! -e "${totp_dir}" ]]; then
		printf 'INFO: %s\n' "Creating ${totp_dir} ..."
		mkdir -p -m 700 "${totp_dir}"
	fi
	#
	# IMPORTANT: Each command below is prefixed with a space,
	# so secrets/credentials are NOT logged in your bash history.
	#
	 echo
	 printf 'INFO: %s\n' 'Two factor authentication was not yet configured; generating new secret and recovery codes ...'
	 echo
	 google-authenticator -tdfu -w3 -Q none -s "${totp_config}"
	 echo
	 printf 'INFO: %s\n' 'Make sure you save the recovery codes and optionally the secret in a secure location;'
	 printf '      %s\n' ' * You will not see these codes again upon next login!'
	 printf '      %s\n' ' * If you loose them and no longer have access to the device you will configure with the QR code below,'
	 printf '      %s\n' '   you will have locked yourself out!'
	 echo
	 totp-show-QR-code
}

function totp-show-QR-code() {
	export HISTCONTROL=ignorespace:ignoredups
	#
	# IMPORTANT: Each command below is prefixed with a space,
	# so secrets/credentials are NOT logged in your bash history.
	#
	if [[ -x "$(command -v qr)" ]]; then
		 qr "otpauth://totp/${USER}?secret=$(head -1 "${totp_config}")&issuer=$(hostname -s)"
	elif [[ -x "$(command -v qrencode)" ]]; then
		 qrencode -t ANSI256 "otpauth://totp/${USER}?secret=$(head -1 "${totp_config}")&issuer=$(hostname -s)"
	else
		 printf 'ERROR: %s\n' 'Cannot find qr nor qrencode command: cannot generate a QR code.'
		 return
	fi
	 echo
	 printf 'INFO: %s\n' 'Scan the QR code above using an app for generating Time-based One-Time Passwords (TOTPs).'
	 echo
}

#
# Check if 2FA was already configured.
#
if [[ "${TERM:-dumb}" == 'dumb' ]]; then
	: # No terminal available. Hence, also no display available, so we cannot show the QR-code to the user.
elif [[ -e "${totp_config}" ]]; then
	printf 'INFO: %s\n' 'Two factor authentication was already configured.'
	printf '      %s\n' 'Use the totp-show-QR-code command to rescan the QR code when you need to reconfigure your authenticator app.'
elif [[ "$(whoami)" != "$(logname)" ]]; then
	: # No direct (SSH) login; sudo perhaps.
else
	totp-configure
fi

{% endraw %}