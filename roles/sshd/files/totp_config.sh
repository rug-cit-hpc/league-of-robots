#!/usr/bin/env bash

#
# Check if 2FA was already configured.
#
if [[ -e "${HOME}/.totp" ]]; then
	: # TOTP already configured
elif [[ "$(whoami)" != "$(logname)" ]]; then
	: # No direct (SSH) login; sudo perhaps.
else
	export HISTCONTROL=ignorespace:ignoredups
	#
	# IMPORTANT: Each command below is prefixed with a space,
	# so secrets/credentials are NOT logged in your bash history.
	#
	 printf '\nINFO: %s\n\n' 'Two factor authentication was not yet configured; generating new secret and recovery codes ...'
	 google-authenticator -tdfu -w3 -Q none -s "${HOME}/.totp"
	 printf '\nINFO: %s\n' 'Make sure you save the recovery codes and optionally the secret in a secure location;'
	 printf '      %s\n' ' * You will not see these codes again upon next login!'
	 printf '      %s\n' ' * If you loose them and no longer have access to the device you will configure with the QR code below,'
	 printf '      %s\n\n' '   you will have locked yourself out!'
	 qr "otpauth://totp/${USER}?secret=$(head -1 "${HOME}/.totp")&issuer=$(hostname -s)"
	 printf '\nINFO: %s\n\n' 'Scan the QR code above using an app for generating Time-based One-Time Passwords (TOTPs).'
fi