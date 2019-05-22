# Data transfers - How to move data to / from {{ slurm_cluster_name | capitalize }}

Firstly and independent of technical options: make sure you are familiar with the _code of conduct_ / _terms and conditions_ / _license_ or whatever it is called and that you are allowed to upload/download a data set!
When in doubt contact your supervisor / principal investigator and the group/institute that created the data set.

Your options to move data to/from the {{ slurm_cluster_name | capitalize }} HPC cluster depend on the protocol you want to use for the upload/download: 

1. For downloads on {{ slurm_cluster_name | capitalize }} over _**http(s)**_:  
   You can use the commandline tools ```curl``` or ```wget```.
1. For uploads to {{ slurm_cluster_name | capitalize }} or downloads from {{ slurm_cluster_name | capitalize }} we only support _**rsync**_ tunnelled over ssh.
{# jinja2 comment: firewall requires improvements for ssh/rsync/aspera.
1. For downloads on {{ slurm_cluster_name | capitalize }} or uploads from over _**sftp**_ (ftp tunnelled over ssh), _**rsync**_ tunnelled over ssh or **aspera**:  
    * This is already configured in the firewalls for a limited list of bioinformatics institutes (EBI, Sanger, NCBI, Broad, etc.).
    * We can configure this for servers of other institutes too. 
      If you hit a firewall when trying to use _sftp_, _rsync_ or _aspera_ [contact the helpdesk via email](../contact/) to request an update of the firewall config
      and mention the protocol used, the name / address of the server and any non-standard ports used by that server if relevant.
#}
1. For downloads on {{ slurm_cluster_name | capitalize }} over _**ftp**_:  
   You are mostly out of luck as we don't support ftp, not even only for outgoing connections (except to/from a very limited list of bioinformatics institutes).
   The ftp protocol is very messy requiring various open ports on firewalls; 
   it was simply never designed for anything else than public data and is a serious security risk.

## Data transfers with rsync over ssh

Login on the cluster UI using SSH with key forwarding enabled (-A) and then use rsync:

* Login on for example the ''calculon'' fat UI.
  ```
  $your_client> ssh -A your-account@calculon.hpc.rug.nl
  ```
  In case you are outside the UMCG/RUG network you have to [wiki:TransparentMultiHopSSH login via the proxy using Transparent Multi-Hop SSH]. Assuming you created an alias named ''lobby+calculon'' you would login like this:
  ```
  $your_client> ssh -A your-account@lobby+calculon
  ```
* You can check if key forwarding worked by issuing the command:
   ```
   $remote_server> ssh-add -l
   ```
   You should get at least one entry. If you get instead the message "Could not open a connection to your authentication agent.", 
   the key forwarding failed and your private key is not temporarily available/cached on the remote server. This is essential to login from one of our servers to another one: See [#DebuggingKeyForwarding debugging key forwarding] for help.
* Use rsync to pull data from the other cluster.
  ```
  $remote_server> rsync -av your-account@other-cluster.hpc.rug.nl:/groups/${your_group}/source_folder   /groups/${your_group}/destination_folder/
  ```

## Debugging and Frequent Asked Question (FAQs)

#### Q: How can I debug key forwarding when it fails?

A: There are multiple scenarios that can lead to failure to forward a key. To debug:  

* login on the remote server with
  ```
  $your_client> ssh -A youraccount@someserver
  ```
* Now use the ''ssh-add'' command with the list option to list all available keys:
  ```
  $remote_server> ssh-add -l
  ```
  You should get at least one entry. If instead you get the message ''Could not open a connection to your authentication agent'', the key forwarding failed and your private key is not temporarily available/cached on this server.
    1. Check if you have any other terminal sessions open where you are logged in on the same server. Any previously started sessions (without key forwarding) on the same server may cause key forwarding to fail silently: hence the login will work, but without forwarded key. Note this includes any screen/tmux sessions running in the background. Try to logout and stop all sessions, start over with a clean environment and check again with ```ssh-add -l``` if key forwarding worked.[[BR]][[BR]]
    1. If that did not help,  The next step depends on the OS of the machine where you are running your SSH client and/or the SSH client itself.
       * MacOS/Linux/Unix (and !MobaXterm on Windows): Use the ```ssh-add -l``` command on your ''**client**''
         When you also get the message ''Could not open a connection to your authentication agent'' on your SSH client, you need to add your private key. If your private key is located in the default path (~/.ssh/id_rsa) you can use the following command:
         ```
         $your_client> ssh-add
         ```
         If your key is not located in the default path, you will have to specify which private key file to add:
         ```
         $your_client> ssh-add /path/to/my/private.key
         ```
       * PuTTY on Windows: Check if ''Pageant'' (part of the PuTTY Suite) is running and if your private key was loaded in ''Pageant''. When ''Pageant'' is running, the app will have an icon in the system tray on the bottom right corner of your screen. Double click the ''Pageant'' icon in the system try to open a window with the list of loaded keys; load your private key when it is not yet in the list.

#### Q: How do I share large data sets stored on a cluster with an external collaborator?

A: We don't expose our large shared file systems to the outside world directly via cluster User Interface (UI) servers.
   Instead we use a ''stand-alone'' SFTP server with ''local'' storage as intermediate. 
   Hence in order to upload/download we have a 2-step procedure:
   ```
   [Server of Collaborator] <-> [SFTP server] <-> [UI server]
   ```
   In the example below ''cher-ami.hpc.rug.nl'' is the SFTP server and ''calculon.hpc.rug.nl'' the cluster UI:
   ```
   [Server of Collaborator] <-> cher-ami.hpc.rug.nl <-> calculon.hpc.rug.nl
   ```
   The SOP for downloading (uploading is similar, but the data flows in reverse - you get the idea):

1. You send [wiki:RequestAccount instructions to request a guest account] to your collaborator:
1. Your collaborator creates public-private key pair and e-mails public key to the GCC helpdesk with you on CC.
1. We create a temporary guest account and link both your public key and the one for your collaborator to the same guest account
1. You login with key forwarding enabled on ''calculon.hpc.rug.nl''
   ```
   $your_client> ssh -A umcg-youraccount@calculon.hpc.rug.nl
   ```
1. You can check if key forwarding worked by issuing the command:
   ```
   $calculon> ssh-add -l
   ```
   You should get at least one entry. If you get instead the message "Could not open a connection to your authentication agent.", 
   the key forwarding failed and your private key is not temporarily available/cached on ''calculon.hpc.rug.nl''. This is essential to login from one of our UI servers to one of our SFTP servers: See [#DebuggingKeyForwarding debugging key forwarding] for help.
1. You use commandline SFTP to copy the file(s) to the guest account on local storage of the SFTP server.
   Note you must use the SFTP protocol as the guest accounts are restricted to sftp-only shells: there is no ssh, nor scp, nor rsync.
   Detailed [wiki:DataSharing#SFTP_CL instructions for commandline SFTP are here]. The exec summary would be something like this:
   ```
   $calculon> lftp
   lftp :~>   open -u umcg-guest[0-9],none -p 22 sftp://cher-ami.hpc.rug.nl
   lftp :~>   cd destination_folder_on_remote_server
   lftp :~>   mirror -R folder_on_local_server
   ```
   In the example above
    * remote_server = SFTP server like for example ''cher-ami.hpc.rug.nl''
    * local_server  = cluster UI like for example ''calculon.hpc.rug.nl''
1. You notify your collaborator he/she can download the data via SFTP from our server using the guest account...
1. By default guest accounts expire after one month.
