# Rsyslog CLIENT ansible role

## I. Prerequisites

This role is the second of the rsyslog ansible playbooks. It expects predefined
 - (optional) a list of external rsyslog servers defined in group variables f.e.
   inside ```group_vars/{{ stack_name }}/vars.yml```
   ```
   rsyslog_external_servers:
    - hostname: 123.45.67.89
      port: 514
   ```
 - (optional) servers defined in the inventory group named ```rsyslog``` inside
   ```static_inventories/{{ cluster_name }}.yml```. Those _rsyslog_ servers should 
   have previously deployed with rsyslog_server playbook. And each of them should
   already have configured CA key and certificates.

## II. Playbook procedure

1. The playbook parses the group vars for the list of external rsyslog servers
   (not managed with Ansible roles from this repo) - the variable defining those
   servers can be defined in ```group_vars/{{ stack_name}}/vars.yml``` f.e.
   ```
   rsyslog_external_servers:
    - hostname: 172.1.2.123
      port: 514
   ```
   Playbook configures this list of external servers inside `rsyslog.conf` on each
   of the client machine.
   Note: port is optional and, if not defined, 514 as default value is used.

2. If a list of rsyslog servers (managed by Ansible roles from this repo) was defined in the inventory, then the playbook configures on each
   of the client machines:
   (if certificate and key are missing or are not compatible signed with CA)
    - private key (with 4096 bits)
    - copies the template, based on which the certificate request will be created
    - generates certificate sign request for clients machine name, based on the
      clients template and private key
    - both signing request and clients template (!) are copied to CA server
    - the server creates certificate from CSR and template
    - both client's and CA's certificate are copied from server to client
3. Steps creating and deploying `rsyslog.conf`
   At the end, the `/etc/rsyslog.conf` file is deployed based on the template from
   this playbook. It combines all the external (non-managed) rsyslog servers from 
   step 1 as well as the (managed) rsyslog servers from step 2
    - adds all servers from group rsyslog (rsyslog severs managed by this repo)
    - adds to configuration
      - the use the client's private key and certificate
      - CA certificate
      - configures to access the remote rsyslog server over SSL

## III. Redeploying individual client

By default, the playbook always check that the correct ca certificate (one from the
repo) is deployed. If client is missing or an outdated one, it overwrites it. Then
playbook checks if existing client's certificate is valid against the ca certificate.
If it is not, it triggers the process of recreating one.

(On the client machine) remove the files
```
   {{ rsyslog_remote_key_dir }}/{{ inventory_hostname }}.key
   {{ rsyslog_remote_cert_dir }}/{{ inventory_hostname }}.pem
   {{ rsyslog_remote_cert_dir }}/{{ rsyslog_ca_cert_file }}
```
By default they should be
```
   /etc/pki/tls/private/[machinename].key
   /etc/pki/tls/certs/[machinename].pem
   /etc/pki/tls/certs/rsyslog-ca.pem
```
then rerun the `single_group_playbooks/rsyslog.yml` or `single_role_playbooks/ryslog_client.yml`
playbook.
