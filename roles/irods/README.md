Role set up the iRODS iCAT server and it's PostgreSQL database

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
