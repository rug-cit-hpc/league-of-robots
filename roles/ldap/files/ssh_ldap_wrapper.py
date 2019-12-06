#!/usr/bin/env python3
"""
Usage: ssh_ldap_wrapper.py <user>

Custom ssh-ldap-wrapper script.
1. Fetches public keys
   * For admin users from local credentials (~/.ssh/authorized_keys).
     This ensures the system will be maintainable in case of a lost connection to the ldap.
   * For regular users from LDAP using default ssh-ldap-helper.
2. Filters the public keys by dropping unsupported key types or short key sizes considered weak.
   We accept fixed size ED25519 keys and >= 4096 bits RSA keys.
3. Optionally and only for non-admin users: prepend ForcedCommand to each public key
   to limit what the key pair may be used for. E.g. rsync-only.

"""

import argparse
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
        #
        #  Get all public keys either from local authorized_keys files or from an LDAP.
        #
        if self.is_admin():
            self.keys = self.local_keys
        else:
            self.keys = self.ldap_keys
        #
        # Filter keys for valid (strong) ones dropping keys based on weak algorithms.
        #
        self.keys = self.filtered_keys
        #
        # Optional post processing to restrict SSH options and use ForcedCommands
        #  * only for regular accounts
        #  * not for admins to make sure they won't get locked out
        #    when further processing fails.
        #
        if self.is_admin():
            # Stop any further processing.
            return
        if self.is_rsync_only():
            self.keys = self.rsync_only_keys

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
            sys.exit(0)

        return int(gid) == self.admin_gid

    def is_rsync_only(self):
        """
        It would be best if users get minimal privileges and only receive "full" shell access
        if they have certain attributes. This currently does not work, so we have to do it 
        the other way around: limit users to rsync-only if they have certain attributes.

        Returns:
            bool: whether the user is an rsync-only user.
        """
        if 'guest' in self.user:
            return True

        try:
            groups = subprocess.run(
                ['id', '-Gn', self.user],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=True).stdout
        except subprocess.CalledProcessError as err:
            logging.error(err)
            logging.error(err.stderr)
            sys.exit(0)
        if 'rsync-only' in str(groups):
            return True
        elif 'sftp-only' in str(groups):
            # This is for backwards compatibility with old account management systems
            # from the days we used SFTP as opposed to Rsync servers.
            return True

        return False

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
                "Invalid key: minimum key size for RSA is {} bits".format(
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
        if self.keys != '':
            return '\n'.join(filter(self.is_ok, self.keys.split('\n')))
        else:
            return ''

    @property
    def rsync_only_keys(self):
        """
        Return keys that are restricted to use for rsync-only.
        This is enforced by using a "ForceCommand" prepended to each public key resulting in the following format:

        restrict,command="/bin/rsync --server --daemon --config=/etc/rsyncd.conf ." <public key> <key comment>

        Returns:
            str: list of keys prefixed with forced rsync daemon command.
        """
        if self.keys != '':
            return "\n".join(['restrict,command="/bin/rsync --server --daemon --config=/etc/rsyncd.conf ." {0}'.format(line)
                for line in self.keys.split('\n')])
        else:
            return ''

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
    config_file = os.path.splitext(os.path.abspath(__file__))[0] + '.yml'
    with open(os.path.join(config_file), 'r') as f:
        config = yaml.load(f.read(), Loader=yaml.BaseLoader)
    parser = argparse.ArgumentParser(description='Fetch public keys for a user.')
    parser.add_argument('user')
    arguments = parser.parse_args()
    user_keys = UserKeys(arguments.user, int(config['admin_gid']))
    print(user_keys.keys)
