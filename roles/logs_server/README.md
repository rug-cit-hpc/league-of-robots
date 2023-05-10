# Remote logs SERVER ansible role

(see also ../logs_client/README.md)

## I. Overview
This playbook is a (first) half of ansible rsyslog server role. It is independent
of a second half (the client) role.

## II. Prerequisites

The playbook expects that there are one or more servers defined and deployed in a
`static_inventory/logs_library.yml`.
The `single_role_playbooks/logs_server.yml` then configures CA and deploys the rsyslog
server `/etc/rsyslog.conf` file.
It expects
 - preconfigured (for now only) Centos 7 server
 - preinstalled firewall service (or installs if run via `single_group_playbook`)
 - admin permissions
 - working network connection between the server and the clients
 - selinux in `permissive` or `disabled` mode

Playbook
 - installs rsyslog software package, and rsyslog reliable module plugin (RELP)
 - installs tools for key and certificate generation
 - deploys (or if needed creates) key and certificate for self signed ca
 - overwrites the `/etc/rsyslog.conf` with one predefined from the template
 - opens firewall port (if deployed through the single_group_playbooks)
 - enables and start the rsyslog service

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
6. Opens a port based on defined port under static inventory rsyslog server's
   rsyslog port on `41514` by default
7. Deploys the private key and certificate for the server to use during the client
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


## V. Deploying a new type of logs server f.e. 'diagnostics'

Every logs type, needs it's own server, to which the clients can connect.

The steps are:
- in the `static_inventory/logs_library.yml` define a new instance
- under the instance assing the correct `logs_ca_name` variable, for example 'diagnostics'
    `logs_ca_name: 'development'`
- deploy the new server and run the `single_group_playbooks/logs.yml` on top of it
- define the client's environment to use the same type of logs servers for example for Hyperchicken, 
  edit the `group_vars/hyperchicken_cluster/vars.yml` and configure the lines
  ```
    logs_ca_name: 'development'
    logs_ca_name: 'diagnostics'
    stacks_logs_servers:    # selected servers from the 'logs_library' static inventory
       - name: 'earl4'
         external_network: 'vlan16' # to retrieve public IP from
       - name: 'earl3'
         external_network: 'logs_external_network'
  ```
  Where the stacks logs servers values are already defined in the `static_inventory/logs_library.yml`
  file, and in the `group_vars/logs_library/ip_addresses.yml`
- initialize the apropriate client LOR stack environment and on them deploy the same `single_group_playbooks/logs.yml`


## VI. Client connections to the logs server

Log servers have by default opened only ssh (22) and rsyslog (41514) ports. The ssh is limited
(with the security groups, as well as with iptables) to various stacks for jumphosts public IPs,
with variable `external_jumphosts` in the `group_vars/logs_library/vars.yml`, and with variable
`iptables_allow_ssh_inbound` in the `group_vars/logs.yml`.
The rsyslog port is limited with `iptables` to clients public IP

Additionally the rsyslog accepts only the communication from the clients that use certificate that
were singed by apropriate certificate authority (each type of logs server has different CA).
