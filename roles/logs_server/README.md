# Ansible role for remote logging - SERVER

(see also ../logs_client/README.md)

To connect to the logs servers you need to declare one of the existing jumhosts, for example
```
    export AI_PROXY=portal
```

## I. Overview

This playbook is the first half of ansible logs playbooks and independent of the
second half (the client) role.

## II. Prerequisites

The playbook expects one or more instances defined in a `static_inventory/logs_library.yml`
and already deployed on some environment.
The `single_role_playbooks/logs_server.yml` configures CA and deploys the rsyslog
server `/etc/rsyslog.conf` file.

Role expects
 - preconfigured (for now only) Centos 7 server
 - preinstalled firewall service (or installs if run via `single_group_playbook`)
 - admin permissions
 - working network connection between the server and the clients
 - selinux in `permissive` or `disabled` mode

Playbook steps
 - installing rsyslog software package, and rsyslog reliable module plugin (RELP)
 - installing tools for key and certificate generation
 - deploying (or create, if needed) key and certificate for self signed CA
 - deploy custom made `/etc/rsyslog.conf` and either/both `/etc/rsyslog.d/rsyslog_managed.conf`
   and `/etc/rsyslog.d/rsyslog_unmanaged.conf`
 - enable and start the rsyslog service

## III. Playbook steps

1. Installing rsyslog server, gnutls and some of their plugins
2. Check if CA key exists
    - on repo's directory `{{ rsyslog_repository_dir }}`
    - and on remote system inside

      `{{ rsyslog_remote_cert_dir }}/{{ rsyslog_ca_cert_file }}`

      `{{ rsyslog_remote_key_dir }}/{{ rsyslog_ca_key_file }}`

3. If key and certificate exist in repository, but are not on managed server, it
   simply deploys them.
4. If repository and remote key and certificate are missing, it will create them
    - create a CA key on the managed server
    - copy ca template to server
    - generate ca certficate based on the template
    - fetches ca key and certificate to repository folder
5. Configures the rsyslog `/etc/rsyslog.conf` from the template, where
   - add the rules for the accepting port and machines IP's
   - point to the ca certificate, then to servers's key and certificate
6. Deploys the private key and certificate for the server to use during the client
   communication. When it creates own key and certificate it also uses the CA key
   and certificate, that were created in the step 4.

## IV. Recreating rsyslog's CA

Remove the ca key and ca certificate inside repository folder and on the managed
rsyslog server and then rerun
`single_group_playbooks/rsyslog.yml` (or for just the syslog server's part
`rsyslog_server.yml` playbook).

By default on remote they are at the

   `/etc/pki/tls/certs/rsyslog-ca.pem`

   `/etc/pki/tls/private/rsyslog-ca.key`

   `/etc/pki/tls/certs/[hostname].pem`

   `/etc/pki/tls/private/[hostname].key`

and on the repository at the

   `files/{{stack or library name}}/rsyslog-ca.[key and pem]`

! Note: CA and client certificates are generated with `gnutls`, while the communication has
been later switched to `openssl`.

## V. Deploying a new type of logs server f.e. 'diagnostics'

Every logs type, needs it's own server, to which the clients can connect.

The steps are:
- in the `static_inventory/logs_library.yml` define a new instance
- assign the correct `logs_class` variable for individual instance- example 'diagnostics':
    `logs_class: 'development'`
- deploy the new server and run the `single_group_playbooks/logs.yml` on top of it
- define the client's environment to use the same type of logs servers - example Hyperchicken:
  (edit the `group_vars/hyperchicken_cluster/vars.yml` and configure the lines)
  `logs_class: 'development'` or `logs_class: 'diagnostics'`
  Where the stacks logs servers values are already defined in the `static_inventory/logs_library.yml`
  file, and in the `group_vars/logs_library/ip_addresses.yml`
- initialize the apropriate client LOR stack environment and on them deploy the same `single_group_playbooks/logs.yml`
- in order for jumphost jump to work (explained in VI.) the invididual stack have to have the logs servers added in the
  `additional_etc_hosts` in the file `group_vars/[stack]/vars.yml` and the `single_role_playbooks/static_hostname_lookup.yml` 
  needs to be run on the jumphosts of that individual stack.


## VI. Client connections to the logs server

Log servers have by default opened only ssh (22) and rsyslog (41514) ports. Security group and iptables
limit `ssh` connections to jumphosts machines only. This is defined with the variable `external_jumphosts`
in the `group_vars/logs_library/vars.yml` and `iptables_allow_ssh_inbound` in the `group_vars/logs.yml`.

The rsyslog port is limited with `iptables` to public IP of individual client. Those port and IPs are stored
on the server in the files `/etc/iptables_extras.d/[stack].allow`.

Additionally, the rsyslog accepts only the communication from the clients with certificate singed by apropriate
certificate authority (each type of logs server has different CA).

## VII. Weekly logrotate of collected logs

The script named `/etc/logrotate.d/remote` is weekly collecting all the `/var/log/remote/[machine]/[yyyy-mm]/*`
logs, creates (if needed) `compressed_logs` subfolder, compress every log, and moves it into the subfolder.
Then (for the rsyslog to continue to work) recreates an empty log file and then sends `HUP` signal to the rsyslog
service. As according to the [rsyslog documentation](https://www.rsyslog.com/doc/v8-stable/configuration/modules/omprog.html):

*... Rsyslog will reopen the file whenever it receives a HUP signal. This allows the file to be externally rotated (using a tool like logrotate): after each rotation of the file, make sure a HUP signal is sent to rsyslogd.*

## VIII. Debugging

Get the connections to the server from the clients

```
    $ ss -tpn | grep 41514
    FIN-WAIT-1 0      46     10.0.0.4:41514              45.88.81.169:60964
    ESTAB      0      0      10.0.0.4:41514              45.88.81.169:40136               users:(("rsyslogd",pid=19623,fd=17))
    FIN-WAIT-1 0      46     10.0.0.4:41514              45.88.81.169:60274
```

Ssh connection from the client is not working. Check the `iptables` and security groups of openstack.

### Rsyslog internal logging

Rsyslog have the option of creating a verbose log information about current activity. This
internal log information can be redirected into a log file. To start the internal logging,
edit the `/etc/rsyslog.conf` and add in the middle of the file (just before rules) the lines

```
$DebugFile /var/log/rsyslog.log
$DebugLevel 2
```

and restart the service with `systemctl restart rsyslog`. A new file should appear
in the `/var/log/rsyslog.log`. Note that the logs are quite verbose and can grow with
rate of approximately 100MB per hour (with current default settings).

## IX. Remove packages from logs servers

```
  sudo yum remove -y rsyslog* librelp*
```
