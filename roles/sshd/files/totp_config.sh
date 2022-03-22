#!/usr/bin/env bash

#
# This file should be located in /etc/profile.d/,
# so it will get sourced upon login.
#

function totp-configure() {
	export HISTCONTROL=ignorespace:ignoredups
	if [[ -e "${HOME}/.totp" ]]; then
		echo
		printf 'ERROR: %s\n' "${HOME}/.totp already exists."
		printf '       %s\n' '  * Either delete this file and try again to reconfigure TOTPs generating a new secret.'
		printf '       %s\n' '  * Or use the "totp-show-QR-code" command to configure a new device reuseing the existing secret.'
		echo
		return
	fi
	#
	# IMPORTANT: Each command below is prefixed with a space,
	# so secrets/credentials are NOT logged in your bash history.
	#
	 echo
	 printf 'INFO: %s\n' 'Two factor authentication was not yet configured; generating new secret and recovery codes ...'
	 echo
	 google-authenticator -tdfu -w3 -Q none -s "${HOME}/.totp"
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
	 qr "otpauth://totp/${USER}?secret=$(head -1 "${HOME}/.totp")&issuer=$(hostname -s)"
	 echo
	 printf 'INFO: %s\n' 'Scan the QR code above using an app for generating Time-based One-Time Passwords (TOTPs).'
	 echo
}

#
# Check if 2FA was already configured.
#
if [[ -e "${HOME}/.totp" ]]; then
	: # TOTP already configured
elif [[ "$(whoami)" != "$(logname)" ]]; then
	: # No direct (SSH) login; sudo perhaps.
else
	totp-configure
	totp-show-QR-code
fi