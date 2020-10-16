#jinja2: trim_blocks:False
# How to start a session and connect to a User Interface server

## User Interface (UI) and Jumphost servers

To submit jobs, check their status, test scripts, etc. you need to login on a _**User Interface (UI)**_ server using SSH.
Each cluster has its own _**UI**_ and the one for the {{ slurm_cluster_name | capitalize }} HPC cluster is named _**{{ groups['user_interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}**_.
The UI and various other servers that make up the cluster receive updates during scheduled maintenance, 
but as this disrupts the processing of jobs, scheduled maintenance is planned only ~twice a year.

Not applying updates for several months could become a serious security risk for machines that are directly accessible via the internet.
Therefore the servers of the {{ slurm_cluster_name | capitalize }} cluster are on an internal network that is not directly accessible from the internet.
In order to access the UI you will need to hop via a _**Jumphost**_, 
which is a security hardened machine that is not in any way involved in the processing of jobs nor in storing data and does receive daily (security) updates.
In order to apply/activate security patches the _Jumphost_ may be temporarily unavailable, which means you cannot login to the _UI_ and hence cannot manage jobs nor create new ones, 
but existing jobs (running or queued) won't be affected and the cluster will continue to process those.
The _**Jumphost**_ for the {{ slurm_cluster_name | capitalize }} HPC cluster is named _**{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}{% if slurm_cluster_domain | length %}.{{ slurm_cluster_domain }}{% endif %}**_

## Request an account

First make sure you have an account. If you are new, please [follow these instructions to request an account](../accounts/).

## SSH client config and log in to UI via Jumphost

Configure your SSH client with the instructions for your operating system:

 * Instructions for [Windows clients](../logins-windows/).
 * Instructions for [macOS clients](../logins-macos/).
 * Instructions for [Linux/Unix clients](../logins-linux/).

## Customize your environment

Once logged in you can customize your environment by editing your ```${HOME}/.bashrc``` file on the cluster.
The first few lines that are already present should not be changed unless you want to break your environment,
so please append your custom stuff at the bottom of this file. In case you did corrupt your ```${HOME}/.bashrc```, 
you can get a fresh copy from the template located in ```/etc/skel/.bashrc```.

#### Time Zone

The cluster runs in the Coordinated Universal Time (or UTC) time zone, which is not adjusted for daylight saving time. 
The latter could confuse software when switching from winter to summer time or back resulting in newer files having older time stamps.
If you prefer to see time stamps in your local time zone, you can set your preferred time zone by configuring the TZ environment variable. 
E.g. for the Netherlands:
```
export TZ=Europe/Amsterdam
```
If you add this command to your ```${HOME}/.bashrc``` file you can make it the default when you login.
See the [list of time zones on WikiPedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for other countries.

