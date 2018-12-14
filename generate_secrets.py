#!/usr/bin/env python
"""
Open the secrets.yml and replace all passwords.
Original is backed up.
"""

import argparse
import string
import random
from yaml import load, dump
from subprocess import call
from os import path

try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper

# length of generated passwords.
pass_length = 20


def write_secrets(topology_file, secrets_file):
    with open(topology_file, 'r') as f:
        data = load(f, Loader=Loader)

    for key, value in data.iteritems():
        data[key] = ''.join(
            random.choice(string.ascii_letters + string.digits)
            for _ in range(pass_length))

    # Make numbered backups of the secrets file.
    if path.isfile(secrets_file):
        call([
            'cp', '--backup=numbered', secrets_file,
            '{}.bak'.format(secrets_file)
        ])

    with open(secrets_file, 'w') as f:
        dump(data, f, Dumper=Dumper, default_flow_style=False)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('topology_file', nargs='?', default='secrets.yml.topol')
    parser.add_argument('secrets_file', nargs='?', default='secrets.yml')
    args = parser.parse_args()
    write_secrets(args.topology_file, args.secrets_file)
