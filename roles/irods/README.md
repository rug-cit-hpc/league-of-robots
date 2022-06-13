# Prerequisites
 - a Centos 7 server with preinstalled epel-release
 - preconfigured irods repository
 - and administrative privileges on the machine

# About the iRODS and PostgreSQL database

Role sets up the iRODS iCAT server and (optionally) a local PostgreSQL database.
The iCAT server can also access a PostgreSQL database on a remote server. This
can be selected, by assigning `pgsql_server` variable to values `local` or
 `remote`.

The iCAT is installed with use of an `unattended_install.json.j2` file.
This file can either be created by setting role variables,
or by copying a custom file to `templates/unattended_install.json.j2`.
The `unattended_install.json.j2` file can be created from an existing iCAT server using the following procedure:
 - Login to the existing iCAT server,
 - Switch to the `irods` _service account_ and run
 - `izonereport > unattended_install.json`
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

## PostgreSQL server 

### Local server installation

Is done with the task `tasks/pgsql_local.yml`.

### Remote PostgreSQL server over ssl

Is configured with task `pgsql_remote.yml`.

For detailed variable explanation, check the [PostgreSQL instructions](https://www.postgresql.org/docs/current/libpq-ssl.html)

`To allow server certificate verification, one or more root certificates must be
placed in the file ~/.postgresql/root.crt in the user's home directory.`

The role configures following files on the iCAT server:
  - `~irods/.postgresql` folder
    - `root.crt` remote server's root certificate
    - `root.crl` remote server's certificate revocation list
    - `postgresql.crt` is the client's certificate (same as `{{ ir_ssl_certificate_chain_file }}` certificate
    - `postgresql.key` matching private key of `postgresql.crt` - make sure it is protected `chmod 0600`
  - /etc/irods/{{ remote_psql_server_ca | basename }}
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

# Tiering plugin

Is defined if the variable `tiering_install` is set to `True`. 

The tiering settings are defined in the static_inventories/[cluster_name].ini
under the machine variables:

```
   tiering_install: True                      # True / False
   ir_local_stage_res: 'demoRescStage'        # Staging resource, before data moved to permanent resource
   ir_local_stage_res_fol: '/tmp/irods/{{ ir_local_stage_res }}'
   ir_local_perm_res: 'demoRescPerm'          # Permanent resource, where it will keep data indefinitely
   ir_local_perm_res_fol: '/tmp/irods/{{ ir_local_perm_res }}'
```
