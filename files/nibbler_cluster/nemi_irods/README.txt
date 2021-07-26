##################################################################################################
For the iRODS scale-out service SURFsara needs the following from us:
##################################################################################################

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

##################################################################################################
Good to know:
##################################################################################################

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

##################################################################################################
Encrypting iRODS traffic using SSL certificates.
##################################################################################################

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

	[rdms-dev-icat ~]$ cd /etc/irods/
	[rdms-dev-icat irods]$ ls -ltr
	total 300
	-rw-r--r-- 1 irods irods  8829 18 feb 20:10 localhost_and_chain.crt
	-rw------- 1 irods irods  3272 18 feb 20:11 localhost.key
	-rw-r--r-- 1 irods irods   424 18 feb 20:11 dhparams.pem

The iRODS SSL config for user "irods":
  
	[irods@rdms-dev-icat ~]$ cat /var/lib/irods/.irods/irods_environment.json
	{
	    "irods_ssl_certificate_chain_file": "/etc/irods/localhost_and_chain.crt", 
	    "irods_ssl_certificate_key_file": "/etc/irods/localhost.key", 
	    "irods_ssl_dh_params_file": "/etc/irods/dhparams.pem", 
	    "irods_ssl_verify_server": "cert", 
	    "schema_version": "v3"
	}

Important note:
 * The certificate we initially got was created based on an ECDSA key pair and Ger could not get ECDSA based certificates to work with iRODS.
   We now use a certificate based on an RSA key pair.
 * The certificate files in this dir are encrypted with Ansible Vault and the vault password for Nibbler.
