# Ansible role for remote logging - CLIENT

(see also ../logs_server/README.md)

## I. Prerequisites

This is the second role of the ansible roles for logs. It relies on predefined
 - (optional) a list of external rsyslog servers (unmanaged by our roles) defined
   in group variables f.e. inside `group_vars/{{ stack_name }}/vars.yml`, for example
   ```
    logs_ca_name: 'development'
    stacks_logs_servers:    # selected servers from the 'logs_library' static inventory
       - name: 'earl1'
         external_network: 'vlan16' # to retrieve public IP from
       - name: 'earl2'
         external_network: 'logs_external_network'
   ```
   The `logs_ca_name` defines the group of rsyslog server to be used. The group must be already
   created and CA key and certificate exist in the `files/logs_library/` folder.
   Currently there are following groups planned: `development`, `research` and `diagnostics`.
   The `stacks_logs_servers` defines the log server. They must be already created by a
   `logs_server` role and exist in they `group_vars/logs_library/ip_address.yml` - this defines
   the specific servers that the logs will be sent to.
 - The `additional_etc_hosts` variable must include the apropriate logs servers. This is defined
   in the `group_vars/{{ stack_name }}/vars.yml`
   ```
    additional_etc_hosts:
    ...
      - group: logs_library
        nodes:
          - name: earl2
        network: logs_external_network
      - group: logs_library
        nodes:
          - name: earl3
            network: logs_external_network
    ...
 - The `yum_repos` role must be deployed on the client and server machines.
 - The `iptables` role must be deployed on the client and server machines.
   ```

## II. Playbook procedure

1. The playbook parses the group vars for the list of (unmanaged) **external** rsyslog servers
   (not managed with Ansible roles from this repo) - the variable defining those
   servers can be defined in `group_vars/{{ stack_name}}/vars.yml` f.e.
   ```
   rsyslog_external_servers:
    - hostname: 172.1.2.123
      port: 514
   ```
   Playbook configures this list of external servers inside `rsyslog.conf` on each
   of the client machine.
   Note: port is optional and, if not defined, default rsyslog port 514 is used.

2. Managed log servers

    - types: there can be several types of log servers. Currently we envisoned the three types:
      - `development` (default) for testing purposes
      - `research`, for the research clusters, and
      - `diagnostics` for the production machines
    - type can be defined by assigning an appropriate value to the `logs_ca_name` variable (f.e.
      `research`) in a `groups_vars/[stack]/vars.yml` (for group of computers) or
      `static_inventory/[stack].yml` (to the individual instance).`

   If a list of managed logs servers (managed by Ansible roles from this repo) was
   defined in the inventory, then the playbook configures on each of the client machines:
   (if certificate and key are missing or are not compatible signed with CA)

    - private key (with 4096 bits)
    - copies the template, based on which the certificate request will be created
    - generates certificate sign request for clients machine name, based on the
      clients template and private key
    - both signing request and clients template (!) are copied to CA server
    - the server creates certificate from CSR and template
    - both client's and CA's certificate are copied from server to client
   The clients IP and port are injected in the servers `/etc/iptables_extras.d/[stack].allow`
   file and /etc/sysconfig/iptables-init.bash` script is rerun. This adds the exception for
   clients public IP for the predefined rsyslog port.

3. Steps creating and deploying `rsyslog.conf`
   At the end, the `/etc/rsyslog.conf` file is deployed based on the template from
   this playbook. It combines all the external (non-managed) rsyslog servers from
   step 1 as well as the (managed) rsyslog servers from step 2
    - adds all servers from group rsyslog (rsyslog severs managed by this repo)
    - adds to configuration
      - the use the client's private key and certificate
      - CA certificate
      - configures to access the remote rsyslog server over SSL

! Note: CA and client certificates are generated with `gnutls`, while the communication has
been later switched to `openssl`.

## III. Redeploying individual client

By default, the playbook always check that the correct CA certificate (one from the
repo) is deployed. If client is missing or an outdated one, it overwrites it. Then
playbook checks if existing client's certificate is valid against the CA certificate.
If it is not, it triggers the process of recreating one.

To recreate the client certificate:

(on the client machine) remove the files

```
   {{ rsyslog_remote_key_dir }}/{{ inventory_hostname }}.key
   {{ rsyslog_remote_cert_dir }}/{{ inventory_hostname }}.pem
   {{ rsyslog_remote_cert_dir }}/{{ rsyslog_ca_cert_file }}
```

By default they should be

```
   /etc/pki/tls/private/[machinename].key
   /etc/pki/tls/certs/[machinename].pem
   /etc/pki/tls/certs/logs_[type].pem
```

then rerun the `single_group_playbooks/logs.yml` or `single_role_playbooks/logs_client.yml`
playbook.

## Client to server connection

Clients connect to servers via `ssh` protocol during the deployment stage. The connection is
established via clients stacks jumphosts, as those machines are the only ones allowed to connect
to the logs servers. After the `ssh` connection was established, the client will drop it's own
public IP address in the (default) directory `/etc/iptables_extras.d/[stack].allow` file. Then it
will restart the `iptables.service` and this will add an exception on the server's apropriate
rsyslog port for the clients public IP.
After that, the client can simply directly communicate with the log server.

## V. Client debugging

Run:

- check that the `rsyslog.conf` is in correct format: `rsyslogd -N1 -f /etc/rsyslog.conf`
- see if rsyslog service is running correctly, and if there are any errors: `systemctl status rsyslog`
- confirm that all the paths are correctly set in the `/etc/rsyslog.conf` and `/etc/rsyslog.d/managed.conf`
- check the CA certificate and client certificate are stored at `/etc/pki/tls/certs/logs_[type].pem` and `/etc/pki/tls/certs/[hostname].pem`
- check if the client key exists in the `/etc/pki/tls/private/[hostname].key`
- validate that the client certificate was signed with the CA certificate `openssl verify -verbose -CAfile /etc/pki/tls/certs/logs_[type].pem /etc/pki/tls/certs/[hostname].pem`

Sometimes it happens that after several days the logs are lost in `/var/log/messages` and rsyslog gets in the `HUPed` state (checking with `systemctl status rsyslog`). This can happen when logrotate starts. The files `/etc/logrorate.d/syslog` has been updated, so that on every `logrorate` event, the `rsyslog` service will be restarted.

Manually execute the syslog logrotate file itself
    `logrotate -vf /etc/logrotate.d/syslog`

or alternatively run main `logrotate.conf` file (that should call also all the /etc/logrotate.d/* files) with
    `logrotate -vf /etc/logrotate.conf`

if logrotate does not work, change the last triggered date in the
    `vi /var/lib/logrotate/logrotate.status`

Networking, check that

 - the firewall is not blocking client outgoing communication
 - the firewall is not blocking server incoming communication
 - connections are established with `ss -tan | grep 41514` (or whatever port is used)
 - check that additional hosts are correctly defined (and deployed)
