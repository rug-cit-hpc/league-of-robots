# Prerequisites
 - a Centos 7 server with preinstalled epel-release
 - admin access to this machine, for installing packages
 - 

# About the iRODS and PostgreSQL database

Role sets up the iRODS iCAT server and (optionally) a local PostgreSQL database.
The iCAT server can also access to the remote PostgreSQL server. The selection 
of local or remote PostgreSQL server is definder with the `pgsql_server` variable.

The installation file can be either assebmled from the set role variables, or
by copying the new installation file onto the
templates/unattended_install.json.j2. The new `unattended_install.json.j2` can
be created from existing iCAT server, by
- login to the existing iCAT server, under irods service account and run
   `izonereport > unattended_install.json`
- the unattended_install.json.j2 will contain two json groups: "icat_server" and
the "servers"
- keep only the icat_server part and remove everything from within except the
   "host_access_control_config"
   "server_config"
   "service_account_environment"
   "hosts_config"
- at the end, the final installation script needs to have the same structure as
  the file `unattended_installation.json` template, that is avaiable at the
  https://github.com/irods/irods/blob/32cc2bd18e43aaaa42f002d07996343a05066646/configuration_schemas/v3/unattended_installation.json

This role also sets
* increased systl TCP timeout limits for large file transfers
* fixed: when using s3 on remote server and local .s3auth file missing 
* increase password to 40 char random A-Za-z0-9

## Server hosting local PostgreSQL server

Configured with task `tasks/pgsql_local.yml`

## Configuring remote PostgreSQL server over ssl

Configured with task `pgsql_remote.yml`

Check the [PostgreSQL instructions](https://www.postgresql.org/docs/current/libpq-ssl.html)

`To allow server certificate verification, one or more root certificates must be placed in the file ~/.postgresql/root.crt in the user's home directory.`

Files needed:
  - `~/.postgresql` folder with files
    - `root.crt` remote server's root certificate
    - `root.crl` remote server's certificate revocation list
    - `postgresql.crt` is the client's certificate (same as `{{ irods_ssl_certificate_chain_file }}` certificate
    - `postgresql.key` matching private key of `postgresql.crt` - make sure it is protected `chmod 0600`
  - /etc/irods/{{ remote_psql_server_ca }}
    - if remote server certificate is signed by trusted CA that has not been yet trusted by iCAT server
    - (optional) if file is missing, just remove the variable



More information about [PostgreSQL variables](https://jdbc.postgresql.org/documentation/head/ssl-client.html)
used in the playbooks.

# Important folders on the iCAT server

```
/etc/irods/               # all iCAT settings & certificates
/home/irods/              # home folder of irods admin user
            .irods/       # configuration and password of irods admin user
            .postgresql/  # root.[crt,crl], postgresql.[crt,key]
                          # for remote postgresql ssl connection
/var/lib/
         irods/           # irods main installation directory
               Vault      # local unix resource directory for uploaded files
         pgsql/           # installation directory of local PostgreSQL server,
                          # local database storage folder and PSQL home folder
```
