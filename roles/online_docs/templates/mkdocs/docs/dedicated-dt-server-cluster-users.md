#jinja2: trim_blocks:False
# Data transfers - How to move data to / from {{ first_dt_server_address }}

Firstly and independent of technical options: make sure you are familiar with the _code of conduct_ / _terms and conditions_ / _license_ or whatever it is called and that you are allowed to upload/download a data set!
When in doubt contact your supervisor / principal investigator and the group/institute that created the data set.

![data-transfers](img/dedicated-dt-server.svg)

## Instructions for cluster users

#### Configure SSH agent forwarding

First, you will need to temporarily forward your private key with _SSH agent forwarding_ to {{ slurm_cluster_name | capitalize }} using one of:

* [Instructions for MobaXterm on Windows](../ssh-agent-forwarding-mobaxterm/)
* [Instructions for OpenSSH on macOS / Linux / Unix](../ssh-agent-forwarding-openssh/)

Next, login via the jumphost on {{ slurm_cluster_name | capitalize }} using your personal, _regular_ account and with SSH _agent forwarding_ enabled.
Verify that _agent forwarding_ worked by executing the following command to list the identities (private keys) available to your _SSH agent_:
```
${{ groups['user_interface'] | first }}> ssh-add -l
```

* You should get a response with at least one key fingerprint, which means you can now transfer data with ```rsync``` to/from the dedicated data transfer server.
* If instead you get ```The agent has no identities``` or ```Could not open a connection to your authentication agent```, 
  then the key forwarding failed. 
  This may happen when you were already logged in to the same server without _agent forwarding_ in another active SSH session;
  make sure you logout from all {{ slurm_cluster_name | capitalize }} servers in all terminals and try login to with _agent forwarding_ enabled again.

#### Transfer data with rsync

Once you have your private key temporarily forwarded to _{{ groups['user_interface'] | first }}_
you can use _rsync_ (over ssh) with the _guest_ account to transfer data to/from _{{ first_dt_server_address }}_.
See below for some syntax examples.
Note:

 * The data transfer server uses named _rsync modules_ to expose only a subset of its filesystems.
   This means you must use _double colon syntax_ (::) to separate the name/address of the server from the named module and path on the server.
 * You must use port 443 for rsync over SSH. The data transfer server does not support rsync over SSH on the default port 22 for SSH.

```
#
##
### Specify only source and leave a destination out to get a listing of modules, files and folders available on the source side.
##
#
# Request a list of rsync modules available for user some-guest-account.
#
rsync -v --rsh='ssh -p 443 -l some-guest-account' {{ first_dt_server_address }}::
#
# List contents in the "home" module.
#
rsync -v --rsh='ssh -p 443 -l some-guest-account' {{ first_dt_server_address }}::home/
#
##
### Specify both a source as well as a destination to transfer data.
##
#
#
# Push a file from user interface to data transfer server.
#
rsync -av --rsh='ssh -p 443 -l some-guest-account' path/to/file_on_{{ groups['user_interface'] | first }} {{ first_dt_server_address }}::home/
#
# Reverse source and destination to pull a file from data transfer server onto user interface server.
#
rsync -av --rsh='ssh -p 443 -l some-guest-account' {{ first_dt_server_address }}::home/data_on_transfer_server path/to/dir_on_{{ groups['user_interface'] | first }}/
```

-----

Back to [overview for dedicated data transfer server](../dedicated-dt-server-overview/)