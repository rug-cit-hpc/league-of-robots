#!/usr/bin/env python

'''
=============================================================
External inventory script for Ansible
=============================================================

Generates Ansible inventory with hostnames from a static inventory file located in the same dir as this script.
By default this script looks for an inventory named 
    inventory.ini
 (default) or alternatively from a file defined in
    export AI_INVENTORY='some_inventory.ini'
Optionally the hostnames can be prefixed with one of our proxy/jumphost servers.
Note we only use hostnames and not FQDN nor IP addresses as those are managed 
together with usernames and other connection settings in
our ~/.ssh/config files like this:

########################################################################################################
#
# HPC hosts.
#
Host lobby foyer *calculon *boxy !*.hpc.rug.nl
    HostName %h.hpc.rug.nl
    User prefix-youraccount
#
# Proxy settings.
#
Host lobby+* foyer+* airlock+*
    PasswordAuthentication No
    ProxyCommand ssh -X -q prefix-youraccount@$(echo %h | sed 's/+[^+]*$//').hpc.rug.nl -W $(echo %h | sed 's/^[^+]*+//'):%p
########################################################################################################


When the environment variable AI_PROXY is set like this:
    export AI_PROXY='lobby'
then the hostname 'calculon' from inventory.ini will be prefixed with 'lobby' and a '+'
resulting in:
    lobby+calculon
which will match the 'Host lobby+*' rule from the ~/.ssh/config file.
=============================================================
'''
import os
import argparse
import ConfigParser
import re
import sys
try:
    import json
except ImportError:
    import simplejson as json


class ProxiedInventory(object):

    def __init__(self):

        # A list of groups and the hosts in that group.
        self.inventory = dict()

        # Get proxy from ENV VAR.
        self.proxy = os.getenv('AI_PROXY')
        if self.proxy:
            self.proxy += '+'
        else:
            self.proxy = ''
            
        # Get inventory file name from ENV VAR.
        self.inventory_file = os.getenv('AI_INVENTORY')
        if self.inventory_file:
            self.inventory_path = os.path.dirname(os.path.realpath(__file__)) + '/' + self.inventory_file
        else:
            self.inventory_path = os.path.dirname(os.path.realpath(__file__)) + '/inventory.ini'
        if not (os.path.isfile(self.inventory_path) and os.access(self.inventory_path, os.R_OK)):
            print 'FATAL: The static inventory file ' + self.inventory_path + ' is either missing or not readable: Check path and permissions.'
            print '       You may need to export the AI_INVENTORY environment variable to point to a static inventory file in the same dir as where '
            print '           ' + os.path.realpath(__file__)
            print '       is located.'
            sys.exit(1)

        # Read settings and parse CLI arguments.
        self.read_inventory_template()
        self.parse_cli_args()

        data_to_print = ""
        data_to_print += self.dict_to_json(self.inventory, True)
        print(data_to_print)

    def read_inventory_template(self):
        """
        Read the inventory details from an Ansible inventory file
         * named 'inventory',
         * in *.ini format and
         located in the same place as this script.
        """
        _config = ConfigParser.SafeConfigParser(allow_no_value=True)
        _config.optionxform = self.prepend_proxy
        
        _config.read(os.path.dirname(os.path.realpath(__file__)) + '/' + self.inventory_file)

        for _section in _config.sections():
            for (_key, _value) in _config.items(_section):
                self.push(self.inventory, _section, _key)

    def prepend_proxy(self, _string):
        """
        Prepends proxy before host.
        """
        return re.sub('^', self.proxy, _string)

    def parse_cli_args(self):
        """
        Process command line arguments.
        """
        parser = argparse.ArgumentParser(description='Produce an Ansible Inventory file.')
        parser.add_argument('--list', action='store_true', default=True,
                            help='List instances (default: True)')
        self.args = parser.parse_args()

    def push(self, _dict, _key, _element):
        """
        Push an element into an array that may or may not have been defined already in the dict.
        """
        if _key in _dict:
            _dict[_key].append(_element)
        else:
            _dict[_key] = [_element]

    def dict_to_json(self, _data, _pretty=False):
        """
        Convert a dict into a string in JSON format.
        """
        if _pretty:
            return json.dumps(_data, sort_keys=True, indent=2)
        else:
            return json.dumps(_data)

#
# Main
#
if __name__ == "__main__":
    ProxiedInventory()
