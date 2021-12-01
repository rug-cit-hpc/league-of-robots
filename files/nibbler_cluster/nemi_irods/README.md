## To-do until next meeting:
- [ ] change the password
- [x] make davrods working
  - [x] add to playbook yum install irods-resource-plugin-s3
- [x] test the current irods test environment
  - [x] add users
  - [x] copy the files
- [x] test alternative clients to connect to irods and davrods
  - [x] cyberduck,
  - [x] linux dav:// client
  - [x] Windows 10 default client 4GB limitation?
- [x] update playbook
- [x] update documentation
- [ ] permanently set firewall
  - [ ] limit 1247 port incoming connection (on the surf IP and specific client list only?)
  - [ ] open ports 80 and 443 to docker davrods implementation
  - [ ] check if 80 can be disabled, and if then the davrods clients can still use it webdav
  - [ ] limit port 22 to jumphost
- [x] remove demoResc resource and add the rootResc

Extra
- [ ] think about the implemenation of the authentication - sRAM
  - [ ] use of the sram-sync?
- [ ] look at the tiering plugin (link below)
	- [ ] change the irods password
	- [ ] test the current irods test environment

Links to check:
- [ ] https://github.com/irods/irods_capability_storage_tiering
- [x] https://cyberduck.io
- [ ] https://github.com/MaastrichtUniversity/sram-sync
- [ ] https://hub.docker.com/r/jboss/keycloak/

Clients to add:
- We'll start with two data processing workstations from microscopy dept.:
  - [ ] 129.125.130.209 (3215.-174.T65)
  - [ ] 192.168.20.37 (3215.-174.D84)

## For the iRODS scale-out service SURFsara needs the following from us:

1. irods account with rods admin privileges in our iCAT.
   Name preferably: service_surfsara
   If it has to be something else due to existing naming schemes that is also possible.

2. Three keys
   They are configured in /etc/irods/server_config.json
		1. one_key
		2. 32byte_negotiation_key
		3. 32byte_ctrl_plane_key
   Can be shared using www.onetimesecret.com with colleagues from SURFsara.

3. Name and IP address of every irods machine involved.
   Each machine will need an SSL certificate to encrypt the traffic.
   (See below for certificates.)
   Reason is optimization of data transfers:
   Machines can create dedicated direct connections for transferring large files.
   A machine that uses for example the iRODS icommands to pull/push data to/from the iCAT,
   will create a dedicated connection to the storage resources holding that data if the size is over X MB,
   so it can access the storage resource bypassing the iCAT.
   
   icommands client <--port:1247--> iCAT (RUG/Groningen) <--port:1247--> (tape) storage resource (SURFsara/Amsterdam+Almere)
               ^                                                                ^
               |________________________port_range:20000-20199__________________|

## Good to know:

A file added to the tape archive triggers the PEP_RESOURCE_OPEN_PRE hook from the iRODS rule engine.
This may conflict if we want to use the same hook: need to get in touch with SURFsara if we want to use the same hook/trigger.

Rules run first where the command that triggerd the rule was executed (for example on our iCAT)
and then on any machine that holds relevant data (e.g. SURF tape archive).
This rule order prevents race conditions, but it is important to understand to order in which rules are run.

Great resource for the tutorials and training material: https://www.slides.com/irods

SURFsara adds 3 pieces of metadata automatically to every file in the archive:
 * surf_status last known status: online (on disk), offline (on tape) or both.
 * surf_time when status was last checked.
 * surf_bfid block file identifier. Can be used to salvage data if the archive implodes.

## Encrypting iRODS traffic using SSL certificates.

Info from Ger @ RUG CIT. Below is an example how they do it @ RUG CIT for their iRDOS a.k.a RUG RDMS.

You must create a cert-and-chain:

	cat ./rdms-dev-icat_data_rug_nl_cert.cer ./rdms-dev-icat_data_rug_nl_interm.cer > localhost_and_chain.crt

Next, we rename all files for deployment on a machine:

	mv ./rdms-dev-icat_data_rug_nl.key ./localhost.key

In addition to the *.crt and the corresponding (private) *.key,
you need a parameter file, which can be created on the machine with:

	openssl dhparam -2 -out dhparams.pem 2048

The 3 files *.crt, *.key and *.pem must be stored in /etc/irods/ with the proper permissions.
E.g. on the rdms-dev-icat:
```
	[rdms-dev-icat ~]$ cd /etc/irods/
	[rdms-dev-icat irods]$ ls -ltr
	total 300
	-rw-r--r-- 1 irods irods  8829 18 feb 20:10 localhost_and_chain.crt
	-rw------- 1 irods irods  3272 18 feb 20:11 localhost.key
	-rw-r--r-- 1 irods irods   424 18 feb 20:11 dhparams.pem
```

The iRODS SSL config for user "irods":
```
	[irods@rdms-dev-icat ~]$ cat /var/lib/irods/.irods/irods_environment.json
	{
	    "irods_ssl_certificate_chain_file": "/etc/irods/localhost_and_chain.crt", 
	    "irods_ssl_certificate_key_file": "/etc/irods/localhost.key", 
	    "irods_ssl_dh_params_file": "/etc/irods/dhparams.pem", 
	    "irods_ssl_verify_server": "cert", 
	    "schema_version": "v3"
	}
```

Important note:
 * The certificate we initially got was created based on an ECDSA key pair and Ger could not get ECDSA based certificates to work with iRODS.
   We now use a certificate based on an RSA key pair.
 * The certificate files in this dir are encrypted with Ansible Vault and the vault password for Nibbler.

## TO-DO: Stuff to check / configure on our iCAT

* To prevent time-outs for large data transfers add `/etc/sysctl.d/irodsFix.conf` which contains:
```
#
# Kernel sysctl configuration
#
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_keepalive_intvl = 300
net.ipv4.tcp_keepalive_probes = 6
```

* Make sure FQDN is in `/etc/hostname`
* Update firewall config with ansible
* Limit incoming client traffic to surfsara server IP only
* Check startup order
    - networking services could be needded before database is turned on
    - database needs to be turned on for irods to turn on
* webdav working
* in `/etc/irods/core.re`: set number of threads to 4
  ```
  acSetNumThreads {msiSetNumThreads("default","4","default"); }
  ```
  Default may otherwise be to high causing issues with S3 bucket.
* Enable SSL by changing  `CS_NEG_DONT_CARE` to `CS_NEG_REQUIRE`  
  In `/home/irods/.irods/irods_environment.json`:
  
  `"irods_client_server_policy": "CS_NEG_REQUIRE",`
  
  In `/etc/irods/core.re`
  ```
  #acPreConnect(*OUT) { *OUT="CS_NEG_DONT_CARE"; }
  acPreConnect(*OUT) { *OUT="CS_NEG_REQUIRE"; }
  ```
* For all users in `~/.irods/irods_environment.json`:
  ```
  {
      "irods_client_server_negotiation": "request_server_negotiation", 
      "irods_client_server_policy": "CS_NEG_REQUIRE", 
      "irods_connection_pool_refresh_time_in_seconds": 300, 
      "irods_default_hash_scheme": "SHA256", 
      "irods_default_number_of_transfer_threads": 4, 
      "irods_encryption_algorithm": "AES-256-CBC", 
      "irods_encryption_key_size": 32, 
      "irods_encryption_num_hash_rounds": 16, 
      "irods_encryption_salt_size": 8, 
      "irods_host": "umcg-icat01.hpc.rug.nl", 
      "irods_match_hash_policy": "compatible", 
      "irods_maximum_size_for_single_buffer_in_megabytes": 32, 
      "irods_port": 1247, 
      "irods_user_name": "rods", 
      "irods_zone_name": "nlumcg",
      "irods_ssl_verify_server" : "cert"
  }
  ```

* Need to install yum install irods-resource-plugin-s3 in addition to base irods package.
```
yum install irods-resource-plugin-s3-4.2.10-1.x86_64
```

For later
*  We should add this template to `/etc/skel` using Ansible.
*  We should check if `iinit` will ask for the `irods_user_name` if we leave it out from the this template.  
* Test with S3
* Copy microscopy data from S3 to tape and remove from S3

### Davrods client

https://github.com/MaastrichtUniversity/rit-davrods

Note Docker container does not yet have SSL enabled iRODS
Needs to be enabled by changing  `CS_NEG_DONT_CARE` to `CS_NEG_REQUIRE` in `config/irods_environment.json`

For `config/davrods-vhost.conf`:
 * umcg-icat01.hpc.rug.nl cannot be resolved in docker container -> change to internal IP address of host VM inside the docker container
   ```DavRodsServer 10.10.1.121 1247```
 * By default the container allows read-only access to the iRODS data.
   To allow write access, delete or comment this section:
   ```
        <LimitExcept GET HEAD OPTIONS PROPFIND> 
          deny from all 
        </LimitExcept> 
   ```

Additionally we added (when testing) in  `/etc/hosts` the line
	`10.10.1.121	umcg-icat01.hpc.rug.nl`

### HOW TO
#### Some basics
* `irods` is a normal linux user under which the stuff is running, and files are owned
* `rods` is admin username within irods environment
* `.re` are engine irods rule file, and are used immediatly (no service restart needed)
* `.r` are user rules file
* even if you are administrator inside the irods, you don't have access to the data, BUT you can forcefully add yourself the permission of the data
* the rules are inside `/var/lib/irods/msiExecCmd_bin`
* rods installation scripts are in folder `/var/lib/irods/scripts/`
* `/etc/irods/server_config.json` is server configuration file
* `/var/lib/irods/log/rodsServerLog*` location of server logs
* `/var/lib/irods/log/rods.Log.2021*` contains normal logs


#### Use irods

* uploading the test file on the umcg side
`iput -R demoResc test.txt`


* Listing files
`ils -l                   # simple list files`

* Check the file on the physical location itself (if local)
```
ils -L                  # show phsical path of the system that is located
sudo su- irods
ls -l /the/path/to/the/shown/above
```

* example: Pieter accessing and dowloading the rules files
```
ils -A test4
icd ../public
iget dmattr.r
iget dmget.r
iget dmput.r
```

* How to (re)run the irods installation script on the server
```
cd /var/lib/irods/scripts/
python ./setup_irods.py
```

* change password of rods as regular user
```
$ iadmin moduser rods password "passwordhere"
$ ils               # < this returns error
$ init
(input new passwords)
$ ils               # < now it works
```

* change name of the zone
```
iadmin modzon tempZone name nlumcg
vi /etc/irods/server_config.json
    # ^ change the value of something like "zone_name" )
vi .iros/irods_environment.json
    "irods_zone_name":
    "irods_host":
    "irods_cwd":
    "irods_home":
# do iinit and retry ils 
grep tempZone /etc/irods/*
```

# to list and then delete the resource
```
ilsresc
iadmin rmresc [nameoftheresource]
```

* Turn the certificate usage on/off
```
vi /etc/irods/cert.re
     # and in the line acOreConnect(*OUT) change "don't care" into "required")
vi .irods/irods_environment.json
     # change from neg to requiredx509 )
```

* Check if certificate is valid and file permission correct  

  `openssl x509 -in /etc/irods/localhost_and_chan_umcg-icat01.crt -noout -text`

Also make sure that the `/etc/irods/localhost_and_chan_umcg-icat01.crt` and `/etc/irods/localhost_umcg01.key` are correct and not vaulted and correct permissions

* generation of DH parameter
```
openssl dhparam -2 -out dhparams.pem 2048
```

#### DEBUGGING

* irods service
  to start/restart/stop irods service, use  
  `service irods restart`  
  **! use system init V `service` calls** and not systemd ``systemctl``

* after nfs or certs change, you need to restart irods
* large data transfer can take for too long and timeout if you don't increase the ``keepalive`` value in ``sysctl``. Example from ``umcg-resc1.irods.surfsara.nl:/etc/sysctl.d/irodsFix.conf``:
```
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_keepalive_intvl = 300
net.ipv4.tcp_keepalive_probes = 6
```

* make sure you have the correct hostname in the
```
/etc/irods/server_config.json
```

* check logs
```
tail -50 /var/lib/irods/log/rods.Log.2021...
```

* restart service
```
service irods restart
```

* check irods_environment.json
```
cat ~irods/.irods/irods_environment.json
```
and check ssl lines that are corrected and then
```
service irods restart
```
additionally
```
sudo su - irods
   ils
```
and check as normal user

* debug server side
check the values in `/etc/irods/irods_environment.json`
look into the logs in the file `/var/lib/irods/log/rodsServerLog*`

* change the irods_hosts to external one, to get more descriptive errors
  If you suspect that you have wrong settings in the file `.irods/irods_environment.json`, but the output does not describe anything, try and change the `irods_hosts` to external one, then error will be more descriptive.
  ```
  iadmin lr demoResc
  iadmin modresc demoResc host umcg-icat.hpc.rug.nl
  ```

* networking issues
  ```
  tcpdump -nnpi any port 1247
  tcpdump -X
  ```
  or for specific IP address
  ```
  tcpdump -nnpi any net 145.38 and port 1247 
  ```

* when updating irods
  ```
  yum upgrade irods
  service irods restart
  ```

** ! Whenever you make an update, the acPreConnect in might change, so you need to change it back into ssl require ! **

#### Rules

Surf personel added the rules on the server, so we can use it. One of such are testing the staging and unstaging the file
```
$ iput -R surfArchive localFileName.txt
$ ils -L
```

on the irods server in the
    /var/lib/irods/msiExecCmd_bin
are the rules defined. THOSE are the rules we can use.


irule -F dmput.r

iquest "select DATA_NAME,COLL_NAME," "test4"


##### Small notes on what was done on Surf side for the archiving
* adding rule for the archive
 on the resource side the archive is exported over nfs
mkresc surfArchive unixfilesystem umcg-resc1.irods.surfsara.nl:/nfs/archivelinks/irumcg/surfArchive


SURF added S3 (hackaton #2)
```
iadmin modresc surfObjStore context "SE_DEFAULT_HOSTNAME=proxy.swift.surfsara.nl;S3_AUTH_FILE=/etc/irods/.s3auth;S3_RETRY_COUNT=1;S3_WAIT_TIME=3;S3_PROTO=HTTPS;S3_REGIONNAME=NL;ARCHIVE_NAMING_POLICIY=consistent;S3_CACHE_DIR=/data/S3Cache;HOST_MODE=cacheless_attached"
```

## Appendix: extra notes from hackaton #2 (15. September 2021)

#### working on the docker image for davrods
Build the image, and spin it up
```
cd rit-davrods312/
docker-compose build
docker-compose up
```

Go into the docker instance

```
docker exec -it ritdavrods312_davrods_1 /bin/bash
```

Tricks to restart the apache service:
first list all the apache processes
```
$ ps auxf
	process			pid
	bash			33
	apachectl 		1
	/usr/sbin/httpd		10
	apache 1 ... ... httpd	11
	apache 1 ... ... httpd	12
	apache 1 ... ... httpd	13
	apache 1 ... ... httpd	14
```

then find the first apache process that is after bash (don't be distracted by httpd ones) and then kill it
```
	kill -HUP [pid]
```
