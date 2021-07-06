SSL met irods is ook een beetje een dingetje. Hieronder een werkend voorbeeld hoe wij het doen.

je moet een cert-and-chain maken:

  cat ./rdms-dev-icat_data_rug_nl_cert.cer ./rdms-dev-icat_data_rug_nl_interm.cer > localhost_and_chain.crt

wij renamen alles qua uitrol:

  mv ./rdms-dev-icat_data_rug_nl.key ./localhost.key

en je moet een parameter-file aanmaken:

  openssl dhparam -2 -out dhparams.pem 2048
  
dit alles in /etc/irods/ plempen met de juiste persmissies:

[rdms-dev-icat ~]$ cd /etc/irods/

[rdms-dev-icat irods]$ ls -ltr
total 300
-rw-r--r-- 1 irods irods  8829 18 feb 20:10 localhost_and_chain.crt
-rw------- 1 irods irods  3272 18 feb 20:11 localhost.key
-rw-r--r-- 1 irods irods   424 18 feb 20:11 dhparams.pem

en de SSL config ziet er dan zo uit (irods config van de user irods):
  
[irods@rdms-dev-icat ~]$ cat /var/lib/irods/.irods/irods_environment.json
{
    "irods_ssl_certificate_chain_file": "/etc/irods/localhost_and_chain.crt", 
    "irods_ssl_certificate_key_file": "/etc/irods/localhost.key", 
    "irods_ssl_dh_params_file": "/etc/irods/dhparams.pem", 
    "irods_ssl_verify_server": "cert", 
    "schema_version": "v3"
}
