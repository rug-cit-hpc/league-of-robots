#!/usr/bin/env python
"""
Generate new secrets.yml file based on a template.
 - Creates random passwords.
 - New secrets.yml is backed up with timestamp suffix if it already exists.
"""

import argparse
import string
import random
from datetime import datetime
from ruamel.yaml import YAML
from ruamel.yaml.comments import CommentedMap
from subprocess import call
from os import path, rename
from pathlib import Path

def generate_secrets(yaml_data, nesting_level):
	padding = nesting_level * '  '
	#
	# Loop over YAML structure and generate random secret values
	# for keys that do not yet have a value (preserves existing values).
	#
	for key in yaml_data.keys():
		print('INFO: ' + padding + 'Processing key: ' + str(key) + ' ...')
		if isinstance(yaml_data[key], str):
			if yaml_data[key] is None or yaml_data[key] == '':
				print(padding + '      Generating new secret/password ...')
				#
				# Length of generated passwords is semi random too for extra complexity.
				# We use a minimum password length of 60 and a max length of 80.
				#
				pass_length = random.randint(60, 80)
				if key == 'cloud_console_pass':
					pass_length = 12
				yaml_data[key] = ''.join(
					random.choice(string.ascii_letters + string.digits + '!?@[]^_+{}=~.,:/')
					for _ in range(pass_length))
			else:
				print(padding + '      Preserving existing value ...')
		elif isinstance(yaml_data[key], CommentedMap):
			nesting_level += 1
			generate_secrets(yaml_data[key], nesting_level)
		else:
			raise SystemExit('FATAL: unsupported value data type ' + str(type(yaml_data[key])) + ' for key ' + key + ' in YAML data structure.')


def write_secrets(template_file, secrets_file):
	#
	# Configure ruamel YAML to:
	#  * preserve comments from the template.
	#  * preserve the order of items in the template
	#  * preserve quotes for value.
	#
	template_path = Path(template_file)
	secrets_path = Path(secrets_file)
	yaml = YAML()
	yaml.default_flow_style = False
	yaml.explicit_start = True
	yaml.explicit_end = True
	yaml.preserve_quotes = True
	#
	# Read YAML template.
	#
	data = yaml.load(template_path)
	#
	# Append new random passwords.
	#
	generate_secrets(data, 0)
	#
	# Make numbered backups of the secrets file.
	#
	if path.isfile(secrets_file):
		timestamp_object = datetime.now()
		timestamp_string = timestamp_object.strftime(".%Y-%m-%dT%H:%M:%S%z")
		rename(secrets_file, secrets_file + timestamp_string)
	#
	# Write new secrets.yml file.
	#
	yaml.dump(data, secrets_path)


if __name__ == '__main__':
	parser = argparse.ArgumentParser()
	parser.add_argument('template_file', nargs='?', default='group_vars/template/secrets.yml')
	parser.add_argument('secrets_file', nargs='?', default='secrets.yml')
	args = parser.parse_args()
	write_secrets(args.template_file, args.secrets_file)
