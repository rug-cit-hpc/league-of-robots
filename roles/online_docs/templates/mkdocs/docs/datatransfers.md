#jinja2: trim_blocks:False
# Data transfers - How to move data to / from {{ slurm_cluster_name | capitalize }}

Firstly and independent of technical options: make sure you are familiar with the _code of conduct_ / _terms and conditions_ / _license_ or whatever it is called and that you are allowed to upload/download a data set!
When in doubt contact your supervisor / principal investigator and the group/institute that created the data set.

![data-transfers](img/data-transfers.svg)

Your options to move data to/from the {{ slurm_cluster_name | capitalize }} HPC cluster depend on the protocol you want to use for the upload/download: 

1. Push data from an external machine to the cluster UI via the jumphost or  
   Pull data on an external machine from the cluster UI via the jumphost.  
   Supported protocol:
    * SSH
2. Push data from the cluster UI to an external server or  
   Pull data on the cluster UI from an external server.  
   Supported protocols:
    * SSH
    * HTTP(S)
{# jinja2 comment: firewall requires improvements for aspera.
    * Aspera
#}

## 1. Push to or pull from cluster UI via jumphost

  * via [GUI on Windows](../datatransfers-windows/)
  * via [GUI on macOS](../datatransfers-macos/)
  * via the commandline: see below for _rsync_ over SSH

#### Using rsync over SSH

* You can transfer data with ```rsync``` over _SSH_ to copy files to for example your home dir on the cluster with something like the command below.

        $your_client> rsync -av some_directory {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}:

    _**Note the colon**_ at the end of the ```rsync``` command:

      1. Without the colon you would copy to a local file named ```{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}``` instead.
      1. If you do not specify a path after the colon you'll transfer data to the default location, which is your home dir.

* If you want the data to go elsewhere you'll have to specify where. E.g.:

        $your_client> rsync -av some_directory {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}:/path/to/somewhere/else/

* Swap source and destination to pull data from the cluster as opposed to pushing data to the cluster.

## 2. Push to or pull from another (SSH) server

#### Using rsync over SSH

When you login from your local computer (via a jumphost) to a server of the {{ slurm_cluster_name | capitalize }} HPC cluster 
and next need to transfer data from {{ slurm_cluster_name | capitalize }} to another SSH server or vice versa, 
you will need:

 1. A private key on {{ slurm_cluster_name | capitalize }} and
 2. A corresponding public key on the other server.

To get a private key on {{ slurm_cluster_name | capitalize }} you can  

* either create a new key pair on {{ slurm_cluster_name | capitalize }}  
* or temporarily forward your private key with _SSH agent forwarding_ to {{ slurm_cluster_name | capitalize }}

###### SSH agent forwarding with MobaXterm on Windows

SSH agent forwarding can be accomplished with MobaXterm as follows:

* Select the _Configuration_ menu item from the _Settings_ menu  
  ![MobaXterm Configuration](img/MobaXterm10.png)
* Select the _SSH_ tab  
  ![MobaXterm Configuration](img/MobaXterm11.png)  
  1. Enable _**Use internal SSH agent "MobAgent"**_  
  2. Enable _**Forward SSH agents**_  
  3. Click the _**+**_ button to select and load your private key.
* Create a session and login to {{ slurm_cluster_name | capitalize }} via the jumphost as usual.

###### SSH agent forwarding with OpenSSH on macOS / Linux / Unix

* Check if your private key was added to the SSH agent on your local _**client**_ by issuing the command  
  ```$your_client> ssh-add -l```  
* You should get a response with the key fingerprint of the private key you want to use.
* If instead you get the message ```The agent has no identities``` or ```Could not open a connection to your authentication agent```,  
  then you will need to add your private key:  
    * If your private key is located in the default path (```${HOME}/.ssh/id_ed25519```) you can use the following command:  
      ```$your_client> ssh-add```  
    * If your key is not located in the default path, you will have to specify which private key file to add:  
      ```$your_client> ssh-add /path/to/my/private.key```
* Login to {{ slurm_cluster_name | capitalize }} with SSH _agent forwarding_ enabled 
  can now be accomplished with the ```-A``` argument on the commandline like this:  
  ```$your_client> ssh -A {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}```

_**Note**_: You **cannot** accomplish this by configuring a ```ProxyCommand``` directive in a  ```${HOME}/.ssh/conf.d/*``` config file on your local computer.

###### Verify that SSH agent forwarding worked

After login to {{ slurm_cluster_name | capitalize }}, 
execute the following command to verify that _agent forwarding_ worked 
and to list the identities (private keys) available to the SSH agent:
```
${{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}> ssh-add -l
```

* You should get a response with at least one key fingerprint, which means you can now transfer data with ```rsync``` to/from the other server 
  assuming you are allowed to access the other server, are allowed to transfer the data and that no firewalls are blocking the connection.
* If instead you get ```The agent has no identities``` or ```Could not open a connection to your authentication agent```, 
  then the key forwarding failed. 
  This may happen when you were already logged in to the same server without _agent forwarding_ in another active SSH session;
  make sure you logout from all {{ slurm_cluster_name | capitalize }} servers in all terminals and try login with _agent forwarding_ again.  

###### Transfer data with rsync

Once you have a private key on {{ slurm_cluster_name | capitalize }} and can login to the other server using ssh, 
you can use rsync (over ssh) to pull data from the other server like this:
```
${{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}> rsync -av your-account@other-server.some.domain:/path/to/source_folder   /path/to/destination_folder/
```
Swap source and destination to push data to the other server as opposed to pulling data from the other sever.

#### Using http(s)

For downloads on / uploads from {{ slurm_cluster_name | capitalize }} over _http(s)_ you can use the commandline tools ```curl``` or ```wget```. 
In case you want to pull from / push to a git repository you can use https URLs with the ```git``` command.

{# jinja2 comment: firewall requires improvements for sftp/aspera.

#### Using aspera

For downloads on {{ slurm_cluster_name | capitalize }} or uploads from over _**sftp**_ (ftp tunnelled over ssh) or **aspera**:

* This is already configured in the firewalls for a limited list of bioinformatics institutes (EBI, Sanger, NCBI, Broad, etc.).
* We can configure this for servers of other institutes too. 
  If you hit a firewall when trying to use _sftp_, _rsync_ or _aspera_ [contact the helpdesk via email](../contact/) to request an update of the firewall config
  and mention the protocol used, the name / address of the server and any non-standard ports used by that server if relevant.

#### Using ftp

For downloads on {{ slurm_cluster_name | capitalize }} over _ftp_ you are mostly out of luck as we don't support ftp, not even only for outgoing connections (except to/from a very limited list of bioinformatics institutes). 
The _ftp_ protocol is very messy requiring various open ports on firewalls; it was simply never designed for anything else than public data and is a serious security risk.

#}
{# jinja2 comment: we don't have dedicated sftp servers for the new clusters yet.

## Debugging and Frequent Asked Question (FAQs)

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

#}