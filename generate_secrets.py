#!/usr/bin/env python

"""
Open the secrets.yml and replace all passwords.
Original is backed up.
"""

from os import path
import random
import string
from subprocess import call
from yaml import load, dump

try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper

# length of generated passwords.
pass_length = 20

with open('secrets.yml.topol', 'r') as f:
    data = load(f, Loader=Loader)

for key, value in data.iteritems():
    data[key] = ''.join(
        random.choice(string.ascii_letters + string.digits)
        for _ in range(pass_length))

# Make numbered backups of the secrets file.
if path.isfile('secrets.yml'):
    call(['cp', '--backup=numbered', 'secrets.yml', 'secrets.yml.bak'])

with open('secrets.yml', 'w') as f:
    dump(data, f, Dumper=Dumper, default_flow_style=False)
