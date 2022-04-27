# Rsyslog SERVER ansible role

## I. Overview
This playbook is a (first) half of ansible rsyslog server role. It is independant
of a second half (the client) role.

## II. Prerequisites
The playbook expects that there are one or more servers defined in static 
inventory list, under group called 'rsyslog'. This role will configure CA and
deploy rsyslog.conf file.
In order that communication between the server works, it already expect that
That playbook expects 
 - preconfigured (for now only) Centos 7 server
 - preinstalled firewall service (or installs if run via single_group_playbook)
 - admin permissions
 - working network connection between the server and the clients
 - selinux in permissive or disabled mode

Playbook
 - installs rsyslog software
 - installs tools for key and certificate generation
 - deploys (or if needed creates) key and certificate for self signed ca
 - overwrites the /etc/rsyslog.conf based on own template
 - opens firewall port (if deployed through the single_group_playbooks)

## III. Playbook steps
1. Installing rsyslog server, gnutls and some of their plugins
2. Check if CA key exists
    - local inside {{ rsyslog_local_dir }}
    - and on remote system inside
      {{ rsyslog_remote_cert_dir }}/{{ rsyslog_ca_cert_file }}
      {{ rsyslog_remote_key_dir }}/{{ rsyslog_ca_key_file }}
3. If local key and certificate exist, but are note on server, then it will simply
   deploy them.
4. If local and remote key and certificate are missing, it will create them
    - create a CA key on the server
    - copy ca template to server
    - generate ca certficate based on the template
    - fetches ca key and certificate to users computer & stops for prompt to 
      encrypt the key file
5. Configures the rsyslog /etc/rsyslog.conf from the template, where
   - add the rules for the accepting port and machines IP's
   - point to the ca certificate, then to servers's key and certificate
6. Opens a port based on defined port under static inventory rsyslog server's
   rsyslog_port value or 514 by default

## III. Recreating rsyslog's CA

Remove the local and remote system's ca key and ca certificate file and rerun the
single_group_playbooks/rsyslog.yml (or just part for server rsyslog_server.yml
playbook).

By default on remote they are at the
   /etc/pki/tls/certs/rsyslog-ca.pem
   /etc/pki/tls/private/rsyslog-ca.key
and on the local machine at the
   files/[stack or library name]/rsyslog-ca.[key and pem]
