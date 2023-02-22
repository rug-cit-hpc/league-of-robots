# Rsyslog SERVER ansible role

## I. Overview
This playbook is a (first) half of ansible rsyslog server role. It is independant
of a second half (the client) role.

## II. Prerequisites
The playbook expects that there are one or more servers defined in static 
inventory list, under group called `rsyslog`. It will configure CA and deploy
`/etc/rsyslog.conf` file.
It expects
 - preconfigured (for now only) Centos 7 server
 - preinstalled firewall service (or installs if run via `single_group_playbook`)
 - admin permissions
 - working network connection between the server and the clients
 - selinux in `permissive` or `disabled` mode

Playbook
 - installs rsyslog software package
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
   rsyslog_port value or `41514` by default

## IV. Recreating rsyslog's CA

Remove the ca key and ca certificate inside repository folder and on the managed
rsyslog server and then rerun
`single_group_playbooks/rsyslog.yml` (or for just the syslog server's part
`rsyslog_server.yml` playbook).

By default on remote they are at the

   `/etc/pki/tls/certs/rsyslog-ca.pem`

   `/etc/pki/tls/private/rsyslog-ca.key`

and on the repository at the
   `files/{{stack or library name}}/rsyslog-ca.[key and pem]`
