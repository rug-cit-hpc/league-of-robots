# ssh role

This role configures the ssh _**client**_ on a machine.
For configuration of the ssh _server_ see the _ssh_host_signer_ and _sshd_ roles.

### Adding the CA's public key for validation of the signed host keys.

This role will add the public key of the Certificate Authority (CA) that signed the host keys of this stack to

```
/etc/ssh/ssh_known_hosts
```

on all machines of the stack. This allows the SSH client to validate the host keys when creating SSH connection
from one machine of the _stack_ to anther of the same _stack_.

### Optional: Including SSH client setting for login on other stacks.

You can configure the SSH client on ```stack_name``` for logins on e.g. ```some_other_stack_name``` and ```yet_another_stack_name```
by including in ```group_vars/stack_name/vars.yml```:

```
#
# Configure the SSH client on this stack for logins on other stacks listed in ssh_client_configs.
#
ssh_client_configs:
  - some_other_stack_name
  - yet_another_stack_name
```

This will depend on the availability of

```
group_vars/some_other_stack_name/ssh_client_settings.yml
group_vars/yet_another_stack_name/ssh_client_settings.yml
```

The ```group_vars/stack_name/ssh_client_settings.yml``` files are based on the template in ```group_vars/template/ssh_client_settings.yml.j2```
and can be generated with the ```openstack_computing``` role.

When the SSH client is configured for connections to other _stacks_ this role will
 - Add the public key of the Certificate Authority (CA) that signed the host keys of the given _stack_ to ```/etc/ssh/ssh_known_hosts```
 - Create ```/etc/ssh/ssh_config.d/{{ some_other_stack_name }}.conf```, which contains the settings for using the jumphosts of the other _stack_.
