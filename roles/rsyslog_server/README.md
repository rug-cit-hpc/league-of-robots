Overview
   1. any "cluster" or "library" can have a rsyslog server.
   
Playbook steps:
1. when playbook is deployed on the server, it will check if the CA key exists in files/[cluster]/rsyslog-CA.key
  * if it does not, it will create one, by
    - install rsyslog server and gnutls
    -  create a CA key on the remote system (where tools are installed)
       * creates the users
       * transfer CA key to users computer, encrypts it
       * copy CA certificate to users system
       * removes CA key on remote system
    - configures the rsyslog /etc/rsyslog.conf
       - add the rules for the accepting port and machines IP's
       - point to the certificate and key on the local machine folders




# Filtering
:msg, contains, "testing"         @@192.168.1.100:514

# Enable and start the rsyslog.service






Assumes folder structure:
   /etc/pki/CA/certs      0755  for CA certificates
   /etc/pki/CA/private    0700  for CA keys
   /etc/pki/tls/certs     0755  to store your certificates
   /etc/pki/tls/private   0700  to store your private keys to

Protect keys:
   chown root:root /etc/pki/tls/private/example.com.key
   chmod 0600 /etc/pki/tls/private/example.com.key
Expose certs:
   chown root:root /etc/pki/tls/certs/example.com.cert
   chmod 0644 /etc/pki/tls/certs/example.com.cert

For system wide openssl, folders are used
   /etc/ssl/certs         0755
   /etc/ssl/private       0700 (root:root)
