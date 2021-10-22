#jinja2: trim_blocks:False
# Data transfers - How to move data to / from {{ groups['data_transfer'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}

Firstly and independent of technical options: make sure you are familiar with the _code of conduct_ / _terms and conditions_ / _license_ or whatever it is called and that you are allowed to upload/download a data set!
When in doubt contact your supervisor / principal investigator and the group/institute that created the data set.

The {{ slurm_cluster_name | capitalize }} HPC cluster features a dedicated data transfer server _{{ groups['data_transfer'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_,
which can be used to exchange data with external collaborators,
that do not have a _regular_ cluster account with full shell access.
This dedicated data transfer server can only be used with _guest_ accounts, which can transfer data using

 * SFTP protocol on port 22
 * rsync protocol on port 443

![data-transfers](img/dedicated-dt-server.svg)

 1. Cluster user uses their _regular_ account with SSH key forwarding enabled to login
    to user interface server _{{ groups['user_interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_
    via jumphost _{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_
 2. Cluster user uses _guest_ account to transfer data from _{{ groups['user_interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_
    to _{{ groups['data_transfer'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_ or vice versa.
 3. External collaborator uses _guest_ account to transfer data to/from
    _{{ groups['data_transfer'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_.

## Arranging a guest account for data transfers

#### Procedure for cluster users who already have a regular account

 * Ask your external collaborator(s) to create a public-private key pair using these instructions
   for [Windows clients](../generate-key-pair-mobaxterm/) or for [macOS/Linux/Unix clients](../generate-key-pair-openssh/).
 * Ask your external collaborator(s) to send **only** their **public** key to our helpdesk.
 * [Contact our helpdesk](../contact/) and request a temporary _guest_ account for you and your external collaborator.
   * You do not need to include your own public key(s) as we already have those.
   * Motivate your request and specify
      * the name and affiliation of your collaborator, 
      * the name of the project for which data will be exchanged and 
      * for how long you will need the _guest_ account.
 * We will assign a temporary _guest_ account for your data transfer and link both your public key(s) as well as the public key(s) of your collaborator(s) to the same _guest_ account.
 * You can now transfer data from/to {{ groups['data_transfer'] | first | regex_replace('^' + ai_jumphost + '\\+','') }} using the _guest_ account and your _private key_.

#### Procedure for external collaborators

 * Your contact (with a _regular_ cluster account) will request a _guest_ account from our helpdesk.
 * Your contact will ask you to create a public-private key pair using these instructions
   for [Windows clients](../generate-key-pair-mobaxterm/) or for [macOS/Linux/Unix clients](../generate-key-pair-openssh/).
 * You will send **only** your **public** key to our [helpdesk](../contact/).
 * We will link your public key to a _guest_ account and notify you when the _guest_ account is ready.
 * You can now transfer data from/to {{ groups['data_transfer'] | first | regex_replace('^' + ai_jumphost + '\\+','') }} using the _guest_ account and your _private key_.

## Using the guest account to transfer data to/from _{{ groups['data_transfer'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_

#### Instructions for cluster users

###### Configure SSH agent forwarding

First, you will need to temporarily forward your private key with _SSH agent forwarding_ to {{ slurm_cluster_name | capitalize }} using one of:

* [Instructions for MobaXterm on Windows](../ssh-agent-forwarding-mobaxterm/)
* [Instructions for OpenSSH on macOS / Linux / Unix](../ssh-agent-forwarding-openssh/)

Next, login via the jumphost on {{ slurm_cluster_name | capitalize }} using your _regular_ account and with SSH _agent forwarding_ enabled.
Verify that _agent forwarding_ worked by executing the following command to list the identities (private keys) available to your _SSH agent_:
```
${{ groups['user_interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}> ssh-add -l
```

* You should get a response with at least one key fingerprint, which means you can now transfer data with ```rsync``` to/from the dedicated data transfer server.
* If instead you get ```The agent has no identities``` or ```Could not open a connection to your authentication agent```, 
  then the key forwarding failed. 
  This may happen when you were already logged in to the same server without _agent forwarding_ in another active SSH session;
  make sure you logout from all {{ slurm_cluster_name | capitalize }} servers in all terminals and try login to with _agent forwarding_ enabled again.

###### Transfer data with rsync

Once you have your private key temporarily forwarded to _{{ groups['user_interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_
you can use rsync (over ssh) to transfer data to/from _{{ groups['data_transfer'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_.
Note that the data transfer server uses named _rsync modules_ to expose only a subset of its filesystems.
This means you will need to use _double colon syntax_ (::) to separate the name/address of the server from the named module and path on the server.
See below for some syntax examples.

```
#
##
### Specify only source and leave a destination out to get a listing of modules, files and folders available on the source side.
##
#
# Request a list of rsync modules available for user some-guest-account.
#
rsync -v --rsh='ssh -p 443 -l some-guest-account' {{ dt_server_address }}::
#
# List contents in the "home" module.
#
rsync -v --rsh='ssh -p 443 -l some-guest-account' {{ dt_server_address }}::home/
#
##
### Specify both a source as well as a destination to transfer data.
##
#
#
# Push a file from user interface to data transfer server.
#
rsync -av --rsh='ssh -p 443 -l some-guest-account' path/to/file_on_{{ groups['user_interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }} {{ dt_server_address }}::home/
#
# Reverse source and destination to pull a file from data transfer server onto user interface server.
#
rsync -av --rsh='ssh -p 443 -l some-guest-account' {{ dt_server_address }}::home/file_on_{{ groups['data_transfer'] | first | regex_replace('^' + ai_jumphost + '\\+','') }} path/to/dir_on_{{ groups['user_interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}/
```

#### Instructions for external collaborators

###### Transfer data with SFTP client app

For both macOS and Windows users we recommend [FileZila](https://filezilla-project.org/).
There are various other good and free SFTP clients, but note that not all SFTP clients support authentication with all types of SSH key pairs.
Use the following connection details:

 * server/host name or address: **{{ dt_server_address }}**
 * port: **22** (default)
 * account/username: the _guest_ account you received from the helpdesk
 * password: if this is a field for the password for the account, then leave empty, because the account is not secured with a password.  
   You should have secured your private key with a password though.  
   Usually you will get a pop-up to supply the password for the private key once you try to connect.


###### Transfer data with rsync on the commandline

You can use rsync (over ssh) to transfer data to/from _{{ groups['data_transfer'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_.
Note that the data transfer uses _rsync modules_, which uses double colon syntax (::) to separate the name/address of the server from the path on the server.
The rsync protocol is more efficient for large data sets and easier to automate, but unfortunately there are no free and good rsync client apps with a Graphical User Interface (GUI).
See below for some syntax examples.

```
#
# Request a list of rsync modules available for user some-guest-account.
#
rsync -v --rsh='ssh -p 443 -l some-guest-account' {{ dt_server_address }}::
#
# List contents in the home module.
#
rsync -v --rsh='ssh -p 443 -l some-guest-account' {{ dt_server_address }}::home/
#
# Push a file from user interface to data transfer server.
#
rsync -v --rsh='ssh -p 443 -l some-guest-account' path/to/file_on_local_computer {{ dt_server_address }}::home/
#
# Reverse source and destination to pull a file from data transfer server onto user interface server.
#
rsync -v --rsh='ssh -p 443 -l some-guest-account' {{ dt_server_address }}::home/file_on_{{ groups['data_transfer'] | first | regex_replace('^' + ai_jumphost + '\\+','') }} path/to/dir_on_local_computer/
```

