#!/usr/bin/env python3
"""
Usage: ssh_ldap_wrapper.py <user>

Custom ssh-ldap-wrapper script.
Fetches public keys from LDAP using default ssh-ldap-helper and
Filters the public keys by dropping unsupported key types or short key sizes considered weak.
We accept fixed size ed25519 keys and >= 4096 bits rsa keys.

Admin users will be sourced from local credentials. This ensures the system will be maintainable in case of a lost connection to the ldap.

Refactored from a original in bash, which became too obfustcated.
"""

import logging
import os.path
import sshpubkeys
import subprocess
import sys
import yaml

class UserKeys(object):
    """
    Class holding information about a user and her/his keys.
    """
    # The gid of the admin group.

    rsa_key_size = 4096
    ssh_ldap_helper = '/usr/libexec/openssh/ssh-ldap-helper'

    def __init__(self, user: str, admin_gid: int):
        self.user = user
        self.admin_gid = admin_gid
        if self.is_admin():
            self.keys = self.local_keys
        else:
            self.keys = self.ldap_keys

    def is_admin(self):
        """
        Returns:
            bool: whether the user is an admin.
        """
        try:
            gid = subprocess.run(
                ['id', '-g', self.user],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=True).stdout
        except subprocess.CalledProcessError as err:
            logging.error(err)
            logging.error(err.stderr)
            return False

        return int(gid) == self.admin_gid

    def is_ok(self, key: str):
        """
        Args:
            key (str): the ssh key to check.
        Returns:
            bool: is the key ok or not.
        """
        if key == '':
            return False

        ssh_key = sshpubkeys.SSHKey(key)
        try:
            ssh_key.parse()
        except sshpubkeys.InvalidKeyError as err:
            logging.error("Invalid key: {}".format(err))
            return False
        except NotImplementedError as err:
            logging.error("Invalid key type: {}".format(err))
            return False
        if ssh_key.key_type == b'ssh-rsa' and ssh_key.bits < self.rsa_key_size:
            logging.error(
                "Invalid key: minimum keysize for rsa is {} bits".format(
                    self.rsa_key_size))
            return False
        elif ssh_key.key_type in (b'ssh-ed25519', b'ssh-rsa'):
            return True
        else:
            logging.error("Skipping unsupported key type {}".format(
                ssh_key.key_type))
            return False

    @property
    def filtered_keys(self):
        """
        Return only keys that comply with standards and regulations.

        Returns:
            str: list of keys
        """
        return '\n'.join(filter(self.is_ok, self.keys.split('\n')))

    @property
    def local_keys(self):
        """
        Return the local keys of a user.
        Returns:
            str: The keys of a user.
        """
        homedir = os.path.expanduser('~{}'.format(self.user))
        with open(os.path.join(homedir, '.ssh/authorized_keys')) as keyfile:
            return keyfile.read()

    @property
    def ldap_keys(self):
        """
        Retreive the keys from the standard ldap wrapper.

        Returns:
            str: The keys of a user.
        """
        try:
            result = subprocess.run(
                [self.ssh_ldap_helper, '-s', self.user],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=True)

        except subprocess.CalledProcessError as err:
            logging.error(err)
            return ''

        return result.stdout.decode('utf-8')


if __name__ == '__main__':
    # Log messages will go to sys.stderr.
    logging.basicConfig(level=logging.INFO)
    dirname = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(dirname, 'ssh_ldap_wrapper.yml'), 'r') as f:
        config = yaml.load(f.read(), Loader=yaml.BaseLoader)
    user_keys = UserKeys(sys.argv[1], int(config['admin_gid']))
    print(user_keys.filtered_keys)
