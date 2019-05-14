# Crunch - How to manage jobs on {{ slurm_cluster_name | capitalize }}

{{ slurm_cluster_name | capitalize }} uses the [Slurm Workload Manager](https://slurm.schedmd.com/)

* If you are completely new to computing on Linux clusters, we recommend
    * The online, free course designed by The Linux Foundation and promoted by Linus Torvalds himself:
      _**[Introduction to Linux](https://www.edx.org/course/introduction-to-linux)**_.
      It is available on edX, the online educational platform by MIT.
    * The interactive _**[Linux Survival](https://linuxsurvival.com/) **_ website.
* If you already have experience with the Portable Batch Scheduler (PBS) on another cluster, but are new to SLURM, the following site can help you to [migrate from PBS to SLURM](https://portal.pawsey.org.au/docs/Supercomputers/Migrating_from_PBS_Pro_to_SLURM).
* If you are already familiar with Slurm and all you need is a quick summary, then SLURM cheat sheet [http://www.schedmd.com/slurmdocs/rosetta.pdf]

== Getting an account ==

To connect to the User Interface (UI) servers, you will need to generate a public/private key pair, request an account and have your public key linked to that account. [[BR]]
For instructions: [wiki:RequestAccount Request an account for access to HPC infra]

== Login to a User Interface server == #UI

To submit jobs, check their status, test scripts, etc. you need to login on a user ''interface server'' like for example **''calculon.hpc.rug.nl''** using SSH.
 * Consult the [wiki:HPC_versions Overview of High Performance Computing (HPC) environments @ UMCG/RUG] to see which UI server to use for which cluster.
 * You will need a terminal application to create a terminal/shell.
 * To login **from inside certain RUG/UMCG subnets** you can connect to UIs directly
   * For users on Mac OS X, Linux and Unix:
     * Open a terminal (on Mac OS X the terminal app is located in **''Applications''** -> **''Utilities''** -> **''Terminal.app''**)
     * Type after the prompt
{{{
ssh [prefix]-[your_account]@[UI_server]
}}}
       Where the prefix is either ''lifelines'' (for LifeLines users) or ''umcg'' (for UMCG users). For example to login as UMCG user jjanssen on UI umcg.hpc.rug.nl type
{{{
ssh umcg-jjanssen@umcg.hpc.rug.nl
}}}
   * For users on Windows:
     * You will need to install a terminal application first and we suggest you give **''[http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html PuTTY]''** a try.
     * In a **''PuTTY Configuration''** window  
        * supply the hostname of the UI server, 
        * supply your account name (with ''umcg-'' or ''lifelines-'' prefix) and 
        * add your private key file in **''Connection''** -> **''SSH''** -> **''Auth''** -> **''Private key file for authentication''**.
 * To login **from outside** you need an automated double hop via our proxy, which is documented here: [wiki:TransparentMultiHopSSH TransparentMultiHopSSH]

{{{#!comment
TODO: document SFTP server when we have a dedicated one for the new clusters.
== Transferring large data sets == 

To transfer large amounts of data from and to the cluster you can use the SFTP servers as described in:  [wiki:DataSharing DataSharing]
}}}

== Jobs == 

For quick debugging/testing on small data sets you are allowed to execute scripts/commands directly on [wiki:HPC_versions#Serveroverview Fat UIs]. 
Please think twice though before you hit enter: if you crash the UI, others can no longer submit nor monitor their jobs, which is pretty annoying. 
On the other hand it's not a disaster as the schedulers and execution daemons run on physically different servers and hence already submitted jobs are not affected by a UI server crash. The better option is to start a job on compute node for which you request a certain amount of resources. Your job will then be restricted to the amount of requested resources and cannot run out of control and crash a machine by depleting all resources. There are 2 kind of jobs:
1. batch a.k.a. non-interactive jobs 
2. interactive jobs

=== 1. Batch jobs ===

For large data sets or long running commands you will need to create a (bash) job script, which can be submitted to the SLURM scheduler. 
When resources are available the scheduler will move the job at the top of the queue to an execution node where the job script will run. 
For efficient scheduling the scheduler needs to know how much resources (CPU cores, memory, time, disk space, etc.) your jobs need, 
so it can determine how many jobs can run in parallel. Therefore you have to specify how much resources your jobs need when submitting them to a scheduler. 
When you underestimate resource requirements, the job will be killed as soon as it exceeds the requested resource limits. 
When you overestimate the resource requirements, resources will get wasted and you cannot run the optimal number of jobs in parallel. 
In addition smaller jobs may be able to bypass larger ones in the queue due to backfill scheduling, 
which will start lower priority jobs if doing so does not delay the expected start time of any higher priority jobs. 
Hence you will need to profile your workload before scaling up.

To [#JobProfiling profile your jobs] you should submit one or two test jobs first with [#QoS Quality of Service (QoS)] level ''dev'' and monitor their resource usage with the ctop and sstat commands. 
The ''dev'' QoS runs on a dedicated set of nodes and if your test jobs misbehave and crash a node in a worst case scenario they won't affect jobs running on production nodes.
It is best to start with overestimating resource requirements and then adjust to more realistic values after some tests. 
Once you've profiled your job scripts and are sure they will behave nice & perform well, you can submit a larger batch in a production QoS level.

Please refer to the [http://slurm.schedmd.com/ SLURM documentation from SchedMD] for a complete overview of SLURM commands to manage jobs. Some examples:

==== Submitting batch jobs ====
Simple submit of job script with [http://slurm.schedmd.com/sbatch.html sbatch] and using default Quality of Service (QoS):
{{{
sbatch myScript.sh
}}}
By default the name of your job will be the filename of the submitted script. To submit a job with a different name
{{{
sbatch --job-name=myJobName myScript.sh
}}}
Submitting a job with a dependency on a previously submitted job.
This job will not start before the dependency has completed successfully:
{{{
sbatch --depend=afterok:[jobID] myScript.sh
}}}

Instead of providing arguments to [http://slurm.schedmd.com/sbatch.html sbatch] on the commandline, you can also add them using the ''#SBATCH'' syntax as a special type of comments to your bash job script like this:
{{{
#!/bin/bash
#SBATCH --job-name=jobName
#SBATCH --output=jobName.out
#SBATCH --error=jobName.err
#SBATCH --time=00:59:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4gb
#SBATCH --nodes=1
#SBATCH --open-mode=append
#SBATCH --export=NONE
#SBATCH --get-user-env=L

[Your actual work...]
}}}
The ''#SBATCH'' comment lines must start with ''#SBATCH''. Hence any white space in front of ''#SBATCH'' will prevent sbatch from interpreting the resource requests. [[BR]]
'''Commonly used options:'''
 * `--job-name=jobName`
   * Set the job name
 * `---nodes=X`
   * Requests X nodes
 * `--cpus-per-task=X` 
   * and X processors (CPU cores) per node. 
 * `--mem=Xgb`
   * Requests X GB RAM total per job
 * `--tmp=Xgb`
   * Requests X GB of local scratch disk space total per job
 * `--time=12:00:00`
   * Sets the walltime to the specified value (here 12hrs). This flag should be set.
 * `--constraint=tmp04`
   * Request a node with the specified feature label/tag; in this example a specific shared storage system.
 * `--output=outputLog.out`
   * Redirects the standard output to the desired file. Note that using '~' in the path for you home directory does not work.
   * Note that the standard output is first written on the local node and only copied once the job terminates (regardless of the reason of the job termination).
 * `--error=errorLog.err`
   * Redirects the error output to the desired file. Note that using '~' in the path for you home directory does not work.
   * Note that the error output is first written on the local node and only copied once the job terminates (regardless of the reason of the job termination).
 * `--get-user-env=L`
   * Replicate the login environment (and overrule whatever environment settings were present at job submission time).
 * `--export=NONE`
   * Do not export environment variables present at job submission time to the job's environment. (Use a clean environment with --get-user-env=L instead!)

==== The batch job's environment ====

We highly recommend using the two {{{sbatch}}} options
{{{
#SBATCH --export=NONE
#SBATCH --get-user-env=L
}}}
in combination with
{{{
module load someSoftware/someVersion
module load otherSoftware/otherVersion
module list
}}}
statements in your job script to ensure a clean job environment and reproducible scripts. Hence any manual changes to your shell's environment at job submission time (and which are not specified in the job script) should not impact your job's result.

==== Checking the status of running batch jobs ====
Getting a list of queued and running jobs of all users using [http://slurm.schedmd.com/squeue.html squeue] and with default output format:
{{{
squeue
}}}
Same with custom output format:
{{{ 
squeue -o "%i|%q|%j|%u|%C|%m|%d|%l|%T|%M|%R|%Q"  | column -t -s "|"
}}}
If you like the custom output format above, but cannot remember to format string, you can use the {{{cqueue}}} wrapper from the [https://github.com/molgenis/cluster-utils cluster utilities] module:
{{{
module load cluster-utils
module list
cqueue
}}}
Limit output to your own jobs:
{{{
squeue -u [your account]
}}}
Our {{{cqueue}}} with custom output format accepts the same commandline options, so this will also work:
{{{
module load cluster-utils
module list
cqueue -u [your account]
}}}
Get "full" output for a specific job (you probably don't want that for all jobs....):
{{{
squeue -j [jobID]
}}}
To get more detailed info about consumed resources for a running job you need the [http://slurm.schedmd.com/sstat.html sstat] command. NOTE: for {{{sstat}}} you must append a ''.batch'' suffix to your job IDs:
{{{
sstat -j [jobID].batch
}}}
We have a custom ''cluster top'' tool or ''ctop'' for short to get a complete picture of the status of your running jobs as well as the cluster as a whole. This tool integrates data from multiple SLURM tools and commands in single ncurses-based view on the commandline. {{{ctop}}} is part of a collection of custom [https://github.com/molgenis/cluster-utils cluster utilities].
{{{
module load cluster-utils
module list
ctop
}}}
[[Image(ctop-slurm.png)]]

==== Checking the status of finished jobs ====
The {{{squeue}}} and {{{sstat}}} commands do not list jobs that already finished. Stats for those jobs can be retrieved from the SLURM accounting database with the [http://slurm.schedmd.com/sacct.html sacct] command. 
To get job stats for your own jobs that for example started after 2015-09-14T11:00:00 and finished before 2015-09-14T11:59:59:
{{{
sacct -S 2015-09-14T11:00:00 -E 2015-09-14T11:59:59
}}}
Get job stats for a specific job:
{{{
sacct -j [jobID]
}}}
In addition to the default SLURM {{{sacct}}} command our [https://github.com/molgenis/cluster-utils cluster utilities] module provides more convenient output using the {{{sjeff}}} (Slurm Job EFFiciency) command:
{{{
sjeff -j [jobID]
}}}

==== Deleting jobs ====
The [http://slurm.schedmd.com/scancel.html scancel] command aborts a job removing it from the queue or killing the job's processes if it already started:
{{{
scancel [jobID]
}}}
Deleting all your jobs in one go:
{{{
scancel -u [your account]
}}}

=== 2. Interactive jobs ===

When you need to interact with a running job you can start an interactive session with the [http://slurm.schedmd.com/srun.html srun] command. Just like for the {{{sbatch}}} command you will need to request resources like amount of cores, amount of memory, work allocation time (walltime), etc. E.g.:
{{{
srun -cpus-per-task=1 --mem=1gb --nodes=1 --qos=dev --time=00:01:00 --pty bash -i
}}}
When the requested resources are available the interactive session will start immediately. When you exit the bash shell using either the {{{exit}}} command or by pressing ''CTRL+d'' the interactive job will be cancelled automagically and the corresponding resources released.

== Quality of Service (QoS) levels == #QoS

We use 6 Quality of Service (QoS) levels with 3 sub-QoS levels each. 
The sub-QoS levels are automagically determined by the system to differentiate between short vs. long running jobs 
and enforce limits on resources available to the latter to prevent long running jobs hogging the complete cluster.
The base QoS levels are determined by the users and these allow you to differentiate between:
 * jobs with lower versus higher priority
 * development versus production jobs
 * high performance computing versus data staging jobs

[[Image(SLURM_QOS.svg)]]

=== QoS levels ===
||= **dev/pro** =||= **QoS**   =||= **Priority** =||= **!UsageFactor**[[BR]](Impact on Fair Share) =||= **Available resources** =||= **Shared Storage** =||
|| production    || leftover    || 0              || none          || Lots, up to the whole cluster for short jobs. || tmp only             ||
|| production    || regular     || default        || default       || Quite some, but never the whole cluster.      || tmp only             ||
|| production    || priority    || default x 2    || default x 2   || Just a few, max ~ 25 percent of the cluster.  || tmp only             ||
|| production    || panic mode  || default x 2    || default x 2   || Occasionally: Just a few.                     || tmp only             ||
|| production    || ds          || default        || default       || Minimal: max 1 core + 1GB mem per job.        || tmp and prm          ||
|| development   || dev         || default        || default       || Just a few, max ~ 20 percent of the cluster.  || tmp only             ||

Please note that job prio is a combination of 
 * QoS weight, 
 * Fair Share (recent historic usage) weight and
 * Accrued queue time weight.
So if you recently consumed a massive amount of resources, your Fair Share based weight may be very low  [[BR]]
and - despite requesting ''priority'' QoS - jobs of other users may have higher combined prio than yours. [[BR]]
Hence your ''priority'' jobs will start before your own ''regular'' jobs, which will start before your own ''leftover'' jobs, [[BR]]
but not necessarily before jobs of other users...

=== 1. QoS **leftover** ===
You are a cheapskate and decided to go Dutch. [[BR]]
You'll consume whatever resources are "leftover" and will accept lowest priority for your jobs. [[BR]]
The !UsageFactor is zero, so any resources consumed using this Quality Of Service level will not impact your ''Fair Share'', 
which is used for calculating job prio. [[BR]]
It may take some time for this research project to complete, but hey you got it for free! [[BR]]

=== 2. QoS **regular** ===
No goofy exceptions; this is the default when no QoS is requested explicitly. [[BR]]
Running with this QoS level will process jobs with standard prio and count for your ''Fair Share'' accordingly.

=== 3. QoS **priority** ===
You are working on multiple projects simultaneously and have a lot of jobs in the queue already, 
but are eager to get the results for jobs submitted with this QoS level first. [[BR]]
The total amount of resources available to this QoS level is limited and your ''Fair Share'' factor is charged double the amount of (normalised) resources as compared to when using ''regular'' QoS,
so choose wisely what you submit with QoS level ''priority''. 

=== 4. QoS **panic mode** ===
You had to submit your PhD thesis or conference abstract yesterday, ooops. [[BR]]
We know how science works and planning can be hard when you expect the unexpected, [[BR]]
so we will try to accomodate your request for panic mode QoS, [[BR]]
but as this is kind of disruptive for others who try to schedule their "science as usual", [[BR]]
the following rules apply:
* You cannot submit jobs yourself with QoS ''panic mode'' [[BR]]
  Instead you submit your jobs with QoS ''priority'' and contact an admin, [[BR]]
  who will manually bump the prio of your jobs to move them to the front of the queues.
* Your ''Fair Share'' factor will be "charged" as if the jobs were submitted with ''priority'' QoS [[BR]]
  and to make sure ''panic mode'' does not become Standard Operating Procedure (SOP) [[BR]]
  you will have to buy the admins a round of drinks, pie, ice cream, or ... depending on season or whatever the next social event will be.
* If a next request for ''panic mode'' QoS comes too soon after a previous one (based on non-negotiable judgment by our boss), [[BR]]
  you will have to buy our entire department (~250 people) a round of drinks, pie, ice cream, or ...  depending on season or whatever the next social event will be.
* If the latter did not help to reduce the frequency of ''panic mode'' QoS requests, [[BR]]
  we will send your PI, alpha (fe)male or promotor a bill to buy additional cluster nodes, storage servers, network switches or whatever resource is in most demand.
  Using these additional resources we can then either increase the capacity to process jobs faster using ''regular'' QoS [[BR]] 
  or create a dedicated QoS level with increased Fair Share ratio depending on investment. (minimal investment 10K euro)

=== 5. QoS **ds** ===
QoS dedicated for data staging and the only one where jobs can access both ''tmp'' as well as ''prm'' shared storage systems.
To prevent abuse jobs can only use max a single core and 1 GB memory,
which should be plenty to copy or rsync data from one storage system to another,
but does not allow for high performance computing.

=== 6. QoS **dev** ===
For untested stuff that requires benchmarking and may behave badly. 
Runs on dedicated nodes not overlapping with any of the other QoS.

=== Sub-QoS ===

The 3 sub Quality of Service levels:
 * ''**short**'' for jobs that require < 06:00:00 walltime (6 hours)
 * ''**medium**'' for jobs that require < 1-00:00:00 walltime (1 day)
 * ''**long**'' for jobs that require < 7-00:00:00 walltime (7 days = max)

The sub-QoS level is automagically determined based on the requested walltime for a job. [[BR]]
You should not request a sub-QoS explicitly; If you do, the job will be reset to the corresponding QoS level and the sub-QoS will be re-assigned based on the requested walltime. [[BR]]
[[BR]]
The medium and long sub-QoS levels have less resources available to prevent long running jobs hogging the complete cluster. [[BR]]
Otherwise priority jobs could be sitting at the top of the queue for days waiting for a slot to become available. [[BR]]
Hence when it's not busy you can consume all resources available on all nodes with jobs in QoS level ''leftover-short'', [[BR]]
but you can consume only a very limited amount of resources in QoS-level ''priority-long''. [[BR]] 
So if you submitted a lot with QoS ''priority'' and a long walltime, those jobs may still be queued even if there are nodes sitting idle.

=== Requesting QoS ===

Request QoS on the commandline using the ''--qos=level'' argument like for example:
{{{
sbatch --qos=priority myScript.sh
}}}
or use an ''#SBATCH'' comment in the header of your script like for example:
{{{
#SBATCH --qos=leftover
}}}

=== QoS and sub-QoS details ===

For the complete picture and limits use:
{{{
sacctmgr show qos format=Name%15,Priority,UsageFactor,GrpTRES%30,GrpSubmit,MaxTRESPerUser%30,MaxSubmitJobsPerUser,Preempt%45,MaxWallDurationPerJob
}}}
Cannot remember the custom format string above? Try {{{cqos}}} from our [https://github.com/molgenis/cluster-utils cluster utilities] module:
{{{
module load cluster-utils
module list
cqos
}}}

== Nodes and Partitions==

Amount and types of resources (CPUs, Memory, storage, etc.) varies from one cluster to the next. See the [wiki:HPC_resources HPC Resources] page for an overview.
To get an overview of the nodes and see how they are doing, login to a cluster UI and execute:
{{{
sinfo -o "%P|%a|%D|%T|%z|%c|%B|%m|%d|%f|%g|%l|%s|%S|%N|%E" | column -t -s "|"
}}}
Cannot remember the custom format string above? Try {{{cnodes}}} from our [https://github.com/molgenis/cluster-utils cluster utilities] module:
{{{
module load cluster-utils
module list
cnodes
}}}
Partitions are used by SLURM and admins to group nodes with an identical config, but as a user you are on a need to know basis... and you don't need to know, so forget about partitions.
**DO NOT SPECIFY A PARTITION** for your jobs and they will be automagically routed to all available partitions and get a suitable node assigned based on the requested QoS. 
If you do specify a partition it will be removed from your job submission request before assigning the job to all available partitions.

== Storage == 

=== Shared storage ===

We use various shared storage systems with quota. Some are optimized for speed (high performance = HP) while others are optimized for availability (high availability = HA). To make optimal use of the available storage please consult: [wiki:HPC_storage Storage SOP Users]

To get the status of quota for groups and filesystems your account has access to:
{{{
module load cluster-utils
quota
}}}

Shared storage systems available on a node are listed as node ''features'', which can be requested as a resources of the type ''constraint'' when submitting jobs with {{{sbatch}}}
You can request a node with a specific shared storage system on the commandline using the ''--constraint=filesystem'' argument like for example:
{{{
sbatch --constraint=tmp04 myScript.sh
}}}
Alternatively you can use an ''#SBATCH'' comment in the header of your script and request a node with access to multiple file systems like for example:
{{{
#SBATCH --constraint="tmp02&prm02"
}}}
Note that when specifying multiple features they must joined with an ampersand and the list must be quoted.

For the complete picture and which tmp filesystems are available on which nodes look for the ''FEATURES'' column in:
{{{
module load cluster-utils
module list
cnodes
}}}

=== Local scratch space on a cluster node === #LocalStorage

If you want to use local disk space on a node instead of or in addition to the shared storage, you need to request local disk space either on the commandline when submitting your job like this:
{{{
sbatch --tmp=4gb myScript.sh
}}}
or in the header of your job script like this:
{{{
#!/bin/bash
#SBATCH --tmp=4gb
}}}
A private temporary folder will be created for your job, which will be removed instantly once your script has finished. You can access this folder in your job script using this environment variable:
{{{
${TMPDIR}
}}}
Please make sure you do not use more disk space then requested. Jobs consuming local scratch space outside their {{{${TMPDIR}}}} will be deleted without notice as they interfere with scheduling.

== Debugging and Frequent Asked Question (FAQs) ==

=== Q: How do I download large data sets to the cluster from another server? ===

A: Your options depend on the protocol you want to use for the upload/download: 

* For downloads over **http(s)**:[[BR]]
  You can use the commandline tools curl or wget.
* For downloads over **ftp**:[[BR]]
  You are mostly out of luck as we don't support ftp not even only for outgoing connections (except to/from a very limited list of bioinformatics institutes).
  The ftp protocol is very messy requiring various open ports on firewalls; 
  it was simply never designed for anything else than public data and is a serious security risk.
* For downloads over **sftp** (ftp tunnelled over ssh) or **aspera**:[[BR]]
  * This is already configured in the firewalls for a limited list of bioinformatics institutes (EBI, Sanger, NCBI, Broad, etc.).
  * We can request our admins to temporarily open op the required ports on our firewalls for servers of other institutes.
    It's a hassle, but for large up- or downloads the best option we have for now.

=== Q: How do I migrate data from one cluster to another one? ===

A: Login on the UI of one cluster using SSH with key forwarding enabled (-A) and then use scp or rsync:

* Login on for example the ''calculon'' fat UI.
  {{{
  $your_client> ssh -A your-account@calculon.hpc.rug.nl
  }}}
  In case you are outside the UMCG/RUG network you have to [wiki:TransparentMultiHopSSH login via the proxy using Transparent Multi-Hop SSH]. Assuming you created an alias named ''lobby+calculon'' you would login like this:
  {{{
  $your_client> ssh -A your-account@lobby+calculon
  }}}
* You can check if key forwarding worked by issuing the command:
   {{{
   $remote_server> ssh-add -l
   }}}
   You should get at least one entry. If you get instead the message "Could not open a connection to your authentication agent.", 
   the key forwarding failed and your private key is not temporarily available/cached on the remote server. This is essential to login from one of our servers to another one: See [#DebuggingKeyForwarding debugging key forwarding] for help.
* Use rsync to pull data from the other cluster.
  {{{
  $remote_server> rsync -av your-account@other-cluster.hpc.rug.nl:/groups/${your_group}/source_folder   /groups/${your_group}/destination_folder/
  }}}

=== Q: How do I share large data sets stored on a cluster with an external collaborator? ===

A: We don't expose our large shared file systems to the outside world directly via cluster User Interface (UI) servers.
   Instead we use a ''stand-alone'' SFTP server with ''local'' storage as intermediate. 
   Hence in order to upload/download we have a 2-step procedure:
   {{{
   [Server of Collaborator] <-> [SFTP server] <-> [UI server]
   }}}
   In the example below ''cher-ami.hpc.rug.nl'' is the SFTP server and ''calculon.hpc.rug.nl'' the cluster UI:
   {{{
   [Server of Collaborator] <-> cher-ami.hpc.rug.nl <-> calculon.hpc.rug.nl
   }}}
   The SOP for downloading (uploading is similar, but the data flows in reverse - you get the idea):

1. You send [wiki:RequestAccount instructions to request a guest account] to your collaborator:
1. Your collaborator creates public-private key pair and e-mails public key to the GCC helpdesk with you on CC.
1. We create a temporary guest account and link both your public key and the one for your collaborator to the same guest account
1. You login with key forwarding enabled on ''calculon.hpc.rug.nl''
   {{{
   $your_client> ssh -A umcg-youraccount@calculon.hpc.rug.nl
   }}}
1. You can check if key forwarding worked by issuing the command:
   {{{
   $calculon> ssh-add -l
   }}}
   You should get at least one entry. If you get instead the message "Could not open a connection to your authentication agent.", 
   the key forwarding failed and your private key is not temporarily available/cached on ''calculon.hpc.rug.nl''. This is essential to login from one of our UI servers to one of our SFTP servers: See [#DebuggingKeyForwarding debugging key forwarding] for help.
1. You use commandline SFTP to copy the file(s) to the guest account on local storage of the SFTP server.
   Note you must use the SFTP protocol as the guest accounts are restricted to sftp-only shells: there is no ssh, nor scp, nor rsync.
   Detailed [wiki:DataSharing#SFTP_CL instructions for commandline SFTP are here]. The exec summary would be something like this:
   {{{
   $calculon> lftp
   lftp :~>   open -u umcg-guest[0-9],none -p 22 sftp://cher-ami.hpc.rug.nl
   lftp :~>   cd destination_folder_on_remote_server
   lftp :~>   mirror -R folder_on_local_server
   }}}
   In the example above
    * remote_server = SFTP server like for example ''cher-ami.hpc.rug.nl''
    * local_server  = cluster UI like for example ''calculon.hpc.rug.nl''
1. You notify your collaborator he/she can download the data via SFTP from our server using the guest account...
1. By default guest accounts expire after one month.

=== Q: How can I debug key forwarding when it fails? === #DebuggingKeyForwarding

A: There are multiple scenarios that can lead to failure to forward a key. To debug:
   * login on the remote server with
     {{{
     $your_client> ssh -A youraccount@someserver
     }}}
     and use the ''ssh-add'' command with the list option to list all available keys:
     {{{
     $remote_server> ssh-add -l
     }}}
     You should get at least one entry. If instead you get the message ''Could not open a connection to your authentication agent'', the key forwarding failed and your private key is not temporarily available/cached on this server.
   1. Check if you have any other terminal sessions open where you are logged in on the same server. Any previously started sessions (without key forwarding) on the same server may cause key forwarding to fail silently: hence the login will work, but without forwarded key. Note this includes any screen/tmux sessions running in the background. Try to logout and stop all sessions, start over with a clean environment and check again with {{{ssh-add -l}}} if key forwarding worked.[[BR]][[BR]]
   1. If that did not help,  The next step depends on the OS of the machine where you are running your SSH client and/or the SSH client itself.
       * MacOS/Linux/Unix (and !MobaXterm on Windows): Use the {{{ssh-add -l}}} command on your ''**client**''
         When you also get the message ''Could not open a connection to your authentication agent'' on your SSH client, you need to add your private key. If your private key is located in the default path (~/.ssh/id_rsa) you can use the following command:
         {{{
         $your_client> ssh-add
         }}}
         If your key is not located in the default path, you will have to specify which private key file to add:
         {{{
         $your_client> ssh-add /path/to/my/private.key
         }}}
       * PuTTY on Windows: Check if ''Pageant'' (part of the PuTTY Suite) is running and if your private key was loaded in ''Pageant''. When ''Pageant'' is running, the app will have an icon in the system tray on the bottom right corner of your screen. Double click the ''Pageant'' icon in the system try to open a window with the list of loaded keys; load your private key when it is not yet in the list.

=== Q: How do I know what environment is available to my job on an execution host? ===

A: The environment available to your jobs on execution hosts is similar but not necessarily exactly identical to the one you see on a user interface (UI) host like for example calculon.hpc.rug.nl. In order to see what your environment looks like for your jobs you can submit a {{{CheckEnvironment.sh}}} job script like this one:

{{{
#!/bin/bash
#SBATCH --job-name=checkENV
#SBATCH --output=checkENV-%N-%u-%j.out
#SBATCH --error=checkENV-%N-%u-%j.err
#SBATCH --time=00:05:01
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1gb
#SBATCH --nodes=1
#SBATCH --open-mode=truncate
#SBATCH --export=NONE
#SBATCH --get-user-env=30L

set -e
set -u

echo 'Complete job environment:'
echo '=========================================================================='
printenv
echo '=========================================================================='
module --version 2>&1
echo '=========================================================================='
module av
echo '=========================================================================='
module list 2>&1
echo '=========================================================================='
module load cluster-utils
echo '=========================================================================='
module list
echo '=========================================================================='

cd ${TMPDIR:-}
echo -n "Working directory: "; pwd
echo "Contains: "
ls -ahl

#
# Let's produce some CPU load, so it will popup in job stats.
#
seconds=10
endtime=$(($(date +%s) + ${seconds}))
while [ $(date +%s) -lt ${endtime} ]; do
    head -10000000 /dev/urandom | md5sum > /dev/null
done

touch ${SLURM_SUBMIT_DIR}/checkENV-${SLURMD_NODENAME}-${SLURM_JOB_USER}-${SLURM_JOB_ID}.finished
}}}

To submit this script to a specific node like for example umcg-node001 and with high prio for quick debugging:

{{{
sbatch --nodelist=umcg-node001 --qos=priority CheckEnvironment.sh
}}}

This script can be supplemented with for example {{{ls}}} and {{{df}}} commands to see if certain paths exist, what their permissions are and which filesystems are mounted. The output is logged to a file ${SLURM_SUBMIT_DIR}/jobName.out, which is in your home. This is convenient for debugging as home dirs are available on all hosts, but never use this for production work with many jobs or large log files: the filesystem hosting the home dirs is not designed for high performance, so massive load on the homes will make all users suffer from sluggish homes.

=== Q: I don't get any output; What is wrong? ===

A: If you not even get any *.out nor *.err files with the standard output or standard error streams of your jobs, there is something wrong with the path in which you try to save these files. Possible causes:
 * **Wrong permissions**: You don't have permission to write in the location where you try to save these files.
 * **Wrong path**: You have a typo in the path for the location where you try to save these files.
 * **Disk quota exceeded**: You or the group you are a member of ran out of disk space and you cannot write anymore: [wiki:HPC_storage#Quota Check your quota status].
 * **Filesystem not available**: The filesystem on which you try to save these files does not exist. This can either be by design of because of technical problems/downtime.
Submit a job to check the environment on execution hosts (see example above), so you can see exactly what resources are available to your jobs.

=== Q: How can I profile my jobs? === #JobProfiling

A: Please use a the following 3 step procedure:
 1. Analyse a small subset of the data by running a script directly on the [#UI user interface (UI) server] to monitor CPU and memory usage for example using {{{htop}}} from the {{{cluster-utils}}} module. Please start with a small job first to prevent overloading the UI.
 2. If you have rough estimates of the resources your jobs will need you can submit a few test jobs for a larger data set in QoS level ''dev'' using {{{sbatch}}} and monitor resource usage while your job is running or after it completed using the tools mentioned below.
 3. Scale up and submit your final workload to one of the production [#QoS QoS] levels.

==== Monitoring jobs ====

For resource usage of 
 * Running scripts on localhost: use the improved {{{htop}}} from the cluster-utils module.
   {{{
   module load cluster-utils
   module list
   htop
   }}}
 * Running Slurm jobs that are running on a cluster node: use the SLURM {{{sstat}}} command or our custom cluster top a.k.a. {{{ctop}}} using
   {{{
   module load cluster-utils
   module list
   ctop
   }}}
 * Finished Slurm jobs that ran on a cluster node: query the SLURM accounting database using the {{{sacct}}} command.

=== Q: Why are my Java jobs misbehaving and using more cores than specified? === #JavaJobsGC

A: Tools written in Java can sometimes use multiple cores. Usually they will allow you to specify how many threads/cores to use. To your surprise you may see your jobs use more cores than you specified. This happens because your Java application runs in a Java Virtual Machine (JVM) and the JVM itself also consumes resources. Recent versions of Java use an efficient garbage collection (GC) strategy that will detect how many cores are available on a computer and perform the cleanup using multiple threads in parallel. Hence if you specified your Java tool to use 4 cores on a node with 48 cores it is not uncommon to see spikes in CPU usage of 32+ cores when the garbage collector kicks in. When multiple of such Java jobs run on the same node this may result in overloading the node making it very slow and eventually crashing it. To limit the amount of threads Java should use for GC you can specify ''-XX:ParallelGCThreads=[integer]''. For example:
{{{
java -XX:ParallelGCThreads=4  -Xmx4g -jar ${EBROOTMYJAVATOOL}/MyJavaTool.jar
}}}

=== Q: Why are my Java jobs complaining there is ''no space left on device'' when there is plenty of space === #JavaJobsTmp

A: Some Java tools use a default Java tmp dir in addition to output files/folders you specified explicitly. This default tmp dir is often on a small, local disk where the OS was installed and hence you may run out of space there while there is plenty of space left on the disk you explicitly specified to store your outputs. You can change the location of the default tmp dir using ''-Djava.io.tmpdir=[folder]''. For example:
{{{
java -Djava.io.tmpdir="/path/to/my/tmp/folder" -jar myJavaTool.jar -i myInputFile -o someOutputFolder
}}}
For jobs that generate random IO (as opposed to streaming IO) it is usually a lot more efficient to use the local scratch space on a node as opposed to using a large shared storage system. For example:
{{{
java -Djava.io.tmpdir="${TMPDIR}" -jar myJavaTool.jar -i myInputFile -o someOutputFolder
}}}
See how to use [#LocalStorage Local scratch space on a cluster node] for details. 

=== Q: Why does Git fail with "The requested URL returned error: 403" === #JavaJobsTmp

A: When you want to use Git and experience an error like this
{{{
error: The requested URL returned error: 403 while accessing https://github.com/....
fatal: HTTP request failed
}}}
your Git version is too old. In order to use the most recent version of Git installed on the cluster use
{{{
module load git
module list
}}}

=== Q: Why do I get "sbatch: error: Batch job submission failed: Invalid account or account/partition combination specified" ===

A: Either you don't have a SLURM account or you do have SLURM account, but are not allowed to submit jobs to the specified Quality of Service (QoS) level. [[BR]]
The first time you login, your SLURM account should have been created automatically. You can check this by executing:
{{{
sacctmgr show assoc tree format=Cluster,Account,User%-30,Share,QOS%-160,DefaultQOS%-16
}}}
If you do not see your account in the list of SLURM users, please [wiki:Contact contact the helpdesk]. [[BR]]
If your SLURM account does exist you most likely tried to submit a job to a QoS level you don't have access to or that does not exist at all. Check the list of [#QoS available QoS levels].

=== Q: Why are my jobs not starting with state ''pending'' (PD) and reason ''QOSMax[some_resource]!PerUser'' or ''QOSGrp[some_resource]Limit''? ===

A: You've reached the maximum number of resources running jobs can consume simultaneously in this QoS level:
   {{{QOSMax[some_resource]PerUser}}}: limit for all jobs of a single user. [[BR]]
   {{{QOSGrp[some_resource]Limit}}}: limit for all jobs of all users. [[BR]]
   You may be able to allocate additional resources in another QoS.
