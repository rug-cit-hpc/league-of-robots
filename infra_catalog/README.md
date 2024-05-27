# Infra Catalog

Extra inventory files for keeping track of our infra.
These inventory files contain values not required for deploying playbooks to configure machines.
They are only used to keep track of things like

 * Make
 * Model
 * Serial number / service tag
 * Expiration data of support contract
 * etc.

#### Ansible ad-hoc commands to query machines

Some of the info in these inventory files can also be queried using _Ansible ad-hoc commands_ as long as the machine is accessible via SSH.
Some examples:

```bash
ansible cluster -u <admin_account> --become -a 'dmidecode -s system-manufacturer'
ansible cluster -u <admin_account> --become -a 'dmidecode -s system-serial-number'
ansible cluster -u <admin_account> --become -a 'dmidecode -s system-product-name'
```

The inventory files in the infra_catalog dir are there to manage situations when the machines are unreachable.

#### Querying the Infra Catalog

Use the ```infra_catalog.yml``` playbook to display details for certain/all machines.
Examples:

```bash
#
# List all infra for a specific stack
#
ANSIBLE_STDOUT_CALLBACK="infra_catalog" ansible-playbook infra_catalog.yml -i infra_catalog/betabarrel_cluster.yml

#
# List all infra for a specific stack and located in a certain datacenter.
# The search_attr_value is a case insensitive Python regex
#
ANSIBLE_STDOUT_CALLBACK="infra_catalog" ansible-playbook infra_catalog.yml -i infra_catalog/betabarrel_cluster.yml  -e 'search_attr_name=location' -e 'search_attr_value=dce'

#
# List all infra for a specific stack and located in a cloud (can be a VM or bare metal machine)
# The search_attr_value is a case insensitive Python regex
#
ANSIBLE_STDOUT_CALLBACK="infra_catalog" ansible-playbook infra_catalog.yml -i infra_catalog/betabarrel_cluster.yml  -e 'search_attr_name=location' -e 'search_attr_value=cloud'

#
# List all infra for any stack and located in a certain datacenter.
#
ANSIBLE_STDOUT_CALLBACK="infra_catalog" ansible-playbook infra_catalog.yml -i infra_catalog/ -e 'search_attr_name=location' -e 'search_attr_value=cbc'

#
# List all infra for any stack and made by a certain vendor.
#
ANSIBLE_STDOUT_CALLBACK="infra_catalog" ansible-playbook infra_catalog.yml -i infra_catalog/ -e 'search_attr_name=make' -e 'search_attr_value=dell'
```
