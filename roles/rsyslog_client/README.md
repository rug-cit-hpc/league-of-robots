# Rsyslog CLIENT ansible role

## I. Prerequisites

This role is the second half of rsyslog ansible roles. It expects
 - a list of remote rsyslog server(s) defined in group variables, f.e. from vars.yml:
     rsyslog_remote_servers:
      - hostname: 123.45.6.789
        port: 514
 - and/or more servers defined in static_inventory list, inside group named 'rsyslog',
   and that those servers have been alread already deployed with (first) playbook
   named 'rsyslog_server'.
   Each of those rsyslog servers have crated a CA key and certificates.

## II. Script procedure

1. The script parses the group vars and checks for the list of remote servers (that
   are not maintained by ansible), the variable defining the servers is:
     rsyslog_remote_servers
       - hostname: 172.1.2.123
         port: 514
   Script adds them to each of the clients /etc/rsyslog.conf file.
   Note: port is optional, and if not defined, 514 as default value is used

2. If the local rsyslog serves was already created, then this playbook also
   creates for each of the client
   (if certificate and key are missing or are not compatible signed with CA)
    - private key (with 4096 bits)
    - copies the template, based on which the certificate request will be created
    - with template and private key, it generates request for own machine name
    - request and template are copied to CA server
    - from template and request, the server creates the certificate
    - certificate and CA certificate are copied from server to client
   (configures the rsyslog servers)
    - /etc/rsyslog.conf file is deployed
      - adds all servers from group rsyslog 
      - adds to configuration
        - the use the client's private key and certificate
        - CA certificate
        - configures to access the remote rsyslog server over SSL

## III. Redeploying individual client

Remove the files
   {{ rsyslog_remote_key_dir }}/{{ inventory_hostname }}.key
   {{ rsyslog_remote_cert_dir }}/{{ inventory_hostname }}.pem
   {{ rsyslog_remote_cert_dir }}/{{ rsyslog_ca_cert_file }}
By default they should be
   /etc/pki/tls/private/machinename.key
   /etc/pki/tls/certs/machinename.pem
   /etc/pki/tls/certs/rsyslog-ca.pem
and rerun the ryslog_client.yml playbook.
