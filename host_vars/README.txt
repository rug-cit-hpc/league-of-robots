#
# When to use host_vars
#
Preferably:
 * Either define group_vars and add the host to a group.
 * Or add host specific variables to the host in the static inventory file.

The only exceptions for using host_vars are
 * host_vars/all.yml,
   which may be used to configure stuff for all hosts.
 * host variables for a host that is used/listed in multiple static inventory files.
   To prevent redundantly listing the same variables in those static inventory files,
   you can create a host_vars/{{ inventory_hostyname }}.yml here.