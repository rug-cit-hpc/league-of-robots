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

import os.path
import subprocess
import sys
import sshpubkeys


class UserKeys(object):
    """
    Class holding information about a user and her/his keys.
    """
    # The gid of the admin group.
    admin_gid = 2000
    admin_gid = 1001

    rsa_key_size = 4096
    ssh_ldap_helper = '/usr/libexec/openssh/ssh-ldap-helper'

    def __init__(self, user: str):
        self.user = user
        if self.is_admin():
            self.keys = self.local_keys
        else:
            self.keys = self.ldap_keys

    def is_admin(self):
        """
        Args:
            user (str): The user to check.
        Returns:
            bool: whether the user is an admin.
        """
        gid = subprocess.run(
            ['id', '-g', self.user],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE).stdout
        return int(gid) == self.admin_gid

    def is_ok(self, key: str):
        """
        Args:
            key (str): the ssh key of the user.
        Returns:
            bool: is the key ok or not.
        """
        ssh_key = sshpubkeys.SSHKey(key)
        try:
            ssh_key.parse()
        except sshpubkeys.InvalidKeyError as err:
            print("Invalid key:", err)
            return False
        except NotImplementedError as err:
            print("Invalid key type:", err)
            return False
        if ssh_key.key_type == b'ssh-rsa' and ssh_key.bits < self.rsa_key_size:
            print("Invalid key: minimum keysize for rsa is {} bits".format(
                self.rsa_key_size))
            return False
        elif ssh_key.key_type in (b'ssh-ed25519', b'ssh-rsa'):
            return True
        else:
            print("Skipping unsupported key type {}".format(ssh_key.key_type))
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
        Args:
            user (str): The user to retreive keys of.
        Returns:
            str: The keys of a user.
        """
        homedir = os.path.expanduser('~{}'.format(self.user))
        with open(os.path.join(homedir, '.ssh/authorized_keys')) as keyfile:
            return keyfile.read()

    @property
    def ldap_keys(self):
        """
        Retreive the keys from the standard ldap wrapper
        Args:
            user (str): The user to retreive keys of.
        Returns:
            str: The keys of a user.
        """
        result = subprocess.check_call(
            [self.ssh_ldap_helper, '-s', self.user],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)

        return result.stdout


if __name__ == '__main__':
    user_keys = UserKeys(sys.argv[1])
    print(user_keys.filtered_keys)
