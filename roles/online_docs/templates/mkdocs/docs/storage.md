#jinja2: trim_blocks:False
# Keep - What is stored where on {{ slurm_cluster_name | capitalize }}

## Introduction

We work with multiple storage systems ranging from large, parallel, shared storage available on multiple servers to small local storage available on a single server. 
Some of these storage systems are optimized for _high performance_ (HP), others for _high availability_ (HA) and yet others for slow, but cheap long term archiving of data. 
The exec summary:
```
 #
 # Centrally installed software and reference data:
 #
 /apps/software/:          Applications centrally deployed with EasyBuild
 /apps/modules/:           Lmod module files for the centrally deployed applications
 /apps/sources/:           Source code for the centrally deployed applications
 /apps/data/:              Centrally deployed reference data sets like the human genome
 #
 # Users:
 #
 /home/${user}/:           Your small home dir for personal settings/configs only
 #
 # Groups:
 #
 /groups/${group}/prm*/:   PeRManent dirs: Your group's large, fast dirs for rawdata and final results
 /groups/${group}/tmp*/:   TeMPorary dirs: Your group's large, fastest dirs for shared temporary data
 /groups/${group}/scr*/:   SCRatch   dirs: Your group's fast dirs for local temporary data
```

Please consult the info below and make sure you know what to store where!

#### Top 4 of blunders, that will result in disaster rather sooner than later
1. Use many jobs to create massive IO load on your home dir making everybody's home dir very slow or worse...
1. Use a sub optimal data structure or experimental design resulting in many thousands of files in a directory either by using small files instead of a relatively small number of large files or by never creating sub dirs. 
   As (our) large parallel file system are optimized for large files, creating many many small files will result in high load on the meta-data servers killing performance or worse...
1. Never cleanup and run out of space crashing both your own jobs as well as those of all other users from the same group.
1. Never finish an experiment and postpone the task of moving the _final_ results from the HP _tmp_ or _scr_ file systems to the HA _prm_ file systems forever. 
   As the **HP tmp/scr filesystems have no backups and old files are deleted automatically**, you will loose your results automagically.
   A four year PhD project is not a single experiment! Split your work in batches / experiments that can be completed in a reasonable amount of time: weeks rather than months. 
   Completed means the results were QC-ed and documented, the data that needs to be kept for the long term was migrated to _prm_ storage and the rest was deleted from _tmp_ or _scr_ to make room for new batches / experiments.

## Details

### Centrally installed software

We deploy software with [EasyBuild](https://github.com/easybuilders/easybuild) in a central place on a Deploy Admin Interface (DAI) server. 
From there the software is synced to various storage devices that are mounted read-only on User Interface (UI) servers and compute nodes. 
Do not use hard-coded paths to software in your scripts: these will vary per cluster node and may change without notice in case we need to switch from one _tmp_ storage system to another due to (un)scheduled downtime. 
Instead use the [Lua based module system \(Lmod\)](https://github.com/TACC/Lmod) to transparently load software in your environment on any of the cluster components / servers.

* To get a list of available apps:

        module avail

* To load an app in your environment if you don't care about the version:

        module load ModuleName

* To load a specific version of an app:

        module load ModuleName/ModuleVersion

* To see which modules are currently active in your environment

        module list

    * Note that some modules may have dependencies on others.  
      In that case the dependencies are automatically loaded.  
      Hence ```module list``` may report more loaded modules than you loaded explicitly with ```module load```.
    * Suggested good practice: always use ```module list``` after ```module load``` in your scripts and write the output to a log file.
      This ensures you can always trace back which versions of which software and their dependencies were used.

* If you need multiple conflicting versions of apps for different parts of your analysis you can also remove a module and load another version:

        module load ModuleName/SomeVersion
        module list
        [analyse some data...]
        module unload ModuleName
        module load ModuleName/AnotherVersion
        module list
        [analyse more data...]

#### Example for the Genome Analysis Toolkit (GATK).

* List available [Genome Analysis Toolkit \(GATK\)](http://www.broadinstitute.org/gatk/) versions:

        module avail GATK
        ----------------------------------- /apps/modules/bio -----------------------------------
        GATK/3.3-0-Java-1.7.0_80    GATK/3.4-0-Java-1.7.0_80    GATK/3.4-46-Java-1.7.0_80 (D)

* To select version 3.4-46-Java-1.7.0_80 and check what got loaded:

        module load GATK/3.4-46-Java-1.7.0_80
        module list

   which returns:

        To execute GATK run: java -jar ${EBROOTGATK}/GenomeAnalysisTK.jar
        
        Currently Loaded Modules:
          1) GCC/4.8.4                                                  13) libpng/1.6.17-goolf-1.7.20
          2) numactl/2.0.10-GCC-4.8.4                                   14) NASM/2.11.06-goolf-1.7.20
          3) hwloc/1.10.1-GCC-4.8.4                                     15) libjpeg-turbo/1.4.0-goolf-1.7.20
          4) OpenMPI/1.8.4-GCC-4.8.4                                    16) bzip2/1.0.6-goolf-1.7.20
          5) OpenBLAS/0.2.13-GCC-4.8.4-LAPACK-3.5.0                     17) freetype/2.6-goolf-1.7.20
          6) gompi/1.7.20                                               18) pixman/0.32.6-goolf-1.7.20
          7) FFTW/3.3.4-gompi-1.7.20                                    19) fontconfig/2.11.94-goolf-1.7.20
          8) ScaLAPACK/2.0.2-gompi-1.7.20-OpenBLAS-0.2.13-LAPACK-3.5.0  20) expat/2.1.0-goolf-1.7.20
          9) goolf/1.7.20                                               21) cairo/1.14.2-goolf-1.7.20
         10) libreadline/6.3-goolf-1.7.20                               22) Java/1.8.0_45
         11) ncurses/5.9-goolf-1.7.20                                   23) R/3.2.1-goolf-1.7.20
         12) zlib/1.2.8-goolf-1.7.20                                    24) GATK/3.4-46-Java-1.7.0_80

  The GATK was written in Java and therefore the Java dependency was loaded automatically. 
  R was also loaded as some parts of the GATK use R for creating plots/graphs. 
  R itself was compiled from scratch and has a large list of dependencies of its own ranging from compilers like the GCC to graphics libs like libpng.  
  Java and R have binaries, which can be executed without specifying the path to where they are locate on the system, 
  because the module system has added the directories, where they are located, to the ```${PATH}``` environment variable, which is used as search path for binaries.  
  
  If the GATK was a binary you could now simply call it without specifying the path to it, 
  but as the GATK is a Java ```*.jar``` we need to call the java binary and specify the path to the GATK ```*.jar```.
  To make sure we don't need an absolute path to the GATK ```*.jar``` hard-coded in our jobs/scripts, 
  the GATK module created an environment variable named ```${EBROOTGATK}```, 
  so we can resolve the path to the GATK transparently even if it varies per server.  
  
  The EB stands for [EasyBuild](https://github.com/easybuilders/easybuild), which we use to deploy software. 
  EasyBuild creates environment variables pointing to the root of where the software was installed for each module according to the scheme 
  EB + ROOT + [NAMEOFSOFTWAREPACKAGEINCAPITALS]. Hence for myFavoriteApp it would be ```${EBROOTMYFAVORITEAPP}```.  
  
* Let's see what's installed in ```${EBROOTGATK}```:  

        ls -hl "${EBROOTGATK}"
        
        drwxrwsr-x 2 deployadmin depad 4.0K Aug  5 15:59 easybuild
        -rw-rw-r-- 1 deployadmin depad  13M Jul  9 23:41 GenomeAnalysisTK.jar
        drwxrwsr-x 2 deployadmin depad 4.0K Aug  5 15:58 resources

* Hence we can now execute the GATK and verify we loaded the correct version like this:

        java -jar "${EBROOTGATK}/GenomeAnalysisTK.jar" --version
        
        3.4-46-gbc02625

  Note that we did not have to specify a hard-coded path to java nor to the GATK ```*.jar``` file. 

### Missing software

If the software you need is not yet available, please use the following procedure:

  1. First try to install the software on a UI in a ```/groups/${group}/tmp0*/...``` folder (without EasyBuild).
  2. Test the software and evaluate if it is useful to do a proper reproducible deployment.  
     If yes, continue and otherwise cleanup.
  3. Depending on time involved in a project:
      * If you work on the cluster for < 6 months (interns, master student projects, etc.) we don't expect you to learn how to use EasyBuild.  
        Ask your supervisor first; if he/she is not part of the deploy admins group, you can [send a request to the helpdesk via email](../contact/).
      * If you work on the cluster for > 6 months it's time to learn how to create an EasyConfig for EasyBuild.  
        See instructions below:
        
#### Create your own personal EasyBuild environment and become member of the deploy admins group

* You can use these steps on a UI to 
  [create your own personal EasyBuild environment](https://gist.github.com/mmterpstra/d11ec81bf78c169ab6be5911df384496)
  to deploy software with EasyBuild on a UI in a /groups/${group}/tmp0*/... folder.  
  Please visit [this page](https://easybuild.readthedocs.io/en/latest/Writing_easyconfig_files.html) to learn how to make an EasyConfig file.
* Fork our [easybuild-easyconfigs repo on GitHub](https://github.com/molgenis/easybuild-easyconfigs) and create pull request with your newly created EasyConfig(s).
* If you are not a member of the deploy admins group yet: request membership by [sending an email to the helpdesk](../contact/).  
  Include in your email:
    * a link to the pull request.
    * the path to the module file created at the end of the deployment with EasyBuild in your own personal EasyBuild environment.
  If the EasyConfig is sane and the software was deployed properly, you've passed the test and will be added to the deploy admins group.
* If you already are a member of the deploy admins group: login on a DAI server and deploy with EasyBuild in /apps/...

Note: unless you really need a newer version of the ```foss``` toolchain, we suggest you use the same version as for other software already deployed in the cluster.

### Reference data

We deploy reference data sets like for example the human genome in a central place, which is available on all servers:
```
/apps/data/...
```
Please use them from that location as opposed to downloading yet another copy elsewhere. 
If your pet reference data set is missing [contact the helpdesk via email](../contact/) to have it added.

### Your personal home dir @ /home/${user}

This is were you have limited space to store your personal settings/preferences/configs like terminal colors, terminal font sizes, etc.
Your home is available on all servers of a cluster, but different clusters have separate homes.
A typical home dir contains << 100 Mb of data:

 * ~/.bashrc file with custom settings, aliases, commands for bash.
 * ~/.ssh folder with keys and settings required for SSH access.
 * Various other (hidden) files / folders that contain settings.

Important:

* Your home is designed to be a **private folder**; do not try to change permissions to share data located in your home with other users.
* Your home is on _HA_ and hence not on _HP_ storage. Therefore you should try to minimize the IO load on your home to make sure everyone can enjoy a fast responsive home.
* Do not abuse your home dir, so:
    * Don't waste resources by installing in your private home dir yet another copy of the same software package that is already available centrally from the module system.
    * Don't run anything that causes massive random IO on your home dir.  
      E.g. don't store job scripts submitted to cluster nodes in homes.
    * Don't store experimental data in your home.  
      Your home is for personal preferences; not for experiments. 
      Use a group dir for the latter (see below).

### Group dirs @ /groups/${group}/...

Every user is a member of at least one group. A group has access to large shared storage systems of which we have 4 types:

* ```/groups/${group}/prm*/: PeRManent dirs```: large, fast dirs for rawdata and final results
* ```/groups/${group}/arc*/: ARChive   dirs```: large, slow dirs for archived rawdata and final results
* ```/groups/${group}/tmp*/: TeMPorary dirs```: large, fastest dirs for _shared_ temporary data
* ```/groups/${group}/scr*/: SCRatch   dirs```: small, fastest dirs for _local_ temporary data

Not all groups have access to all types of storage systems and not all types are available on all clusters.
The minimal requirements for a group are as follows:

* Group leaders / PIs can request new groups. When the group is created they will be registered as the group owners.
* Group owners are responsible for
  * Processing (accepting or rejecting) requests for group membership.
  * Securing funding and paying the bills.
  * Appointing data managers for their group.
* Data managers are responsible for the group's data on ```prm``` and ```arc``` storage systems.
  * They ensure the group makes arrangements what to store how and where. E.g file naming conventions, file formats to use, etc.
  * They enforce the group's policy on what to store how and where by reviewing data sets produced by other group members on ```tmp``` or ```scr``` file systems before migrating/copying them to ```prm``` and ```arc```.
  * They have read-write access to all file systems including ```prm``` and ```arc```.
* Other 'regular' group members:
  * Have read-only access to ```prm``` and ```arc``` file systems to check-out existing data sets.
  * Have read-write access to ```tmp``` and ```scr``` file systems to produce new results.
  * Can request a data manager to review and migration a newly produced data set to ```prm``` or ```arc``` file systems.
* A group has at least one owner and one data manager, but to prevent delays in processing membership request and data set reviews a group has preferably more than one owner and more than one data manager.

## Quota

We use a quota system, which limits how much storage space you can consume. 
If you exceed your limits you can not write any new data before you delete something else to free up space. 
Home directories have _user_ quota, which means that if you run out of space, you are the only one affected. 
All other file systems use _group_ or _file set_ quota, which means that if you run out of space everybody from your group (or file set) is also out of space on that file system, but other groups are not affected. 
There are two limits and a timer period that determines how these interact:

* **quota (soft)**: exceed your quota and you can still write data until you've reached the (hard) limit or until the timer that kicks in expires whichever comes first.
* **limit (hard)**: exceed your (hard) limit and you are instantly prohibited from writing any data. You will need to delete something else to free up space before you can write new data.
* **timers**: after exceeding your quota the timer kicks in and if you do not reduce your data volume to less than your quota, the soft quota will temporarily become your hard limit when the timer expires.
  You will need to reduce your data volume to less than your quota to reset the timer as well as the (hard) limit.

The combination of quota, larger limits and timers prevents users from permanently exceeding their quota while allowing them to temporarily consume more space to handle peak loads. 
Note that if you write a lot of data and fast it is possible to exceed both your quota as well as the larger limit in a time frame that is much shorter than the quota reporting interval. 
In that case you may run out of disk space before you received your first warning.

Different types of file systems come with their own quota tools, which produce different reports. 
Therefore we use a custom wrapper to unify the output for various file systems:
```
module load cluster-utils
quota
```
The report will show 11 columns:
```
   1 Quota type = one of:
      (U) = user quota
      (P) = (private) group quota: group with only one user and used exclusively for home dirs.
      (G) = (regular) group quota: group with multiple users.
      (F) = file set quota: different technology used on the {{ slurm_cluster_name | capitalize }} cluster to also manage quota for a group with multiple users.
   2 Path/Filesystem = (part of) a storage system controlled by the quota settings listed.
   3 used   = total amount of disk space ("blocks") your data consumes.
   4 quota  = soft limit for space.
   5 limit  = hard limit for space.
   6 grace  = days left before the timer for space quota expires.
   7 used   = total number of files and folders ("inodes") your data consists of.
   8 quota  = the soft limit for the number of files and folders .
   9 limit  = the hard limit for the number of files and folders.
  10 grace  = days left before the timer for the number of files and folders quota expires.
  11 status = whether you exceeded any of the quota/limits or not.
```

## List of storage devices / mount points used on {{ slurm_cluster_name | capitalize }}

| Path | Function | (Soft) Quota | (Hard) Limit | Backup | Cleanup | Mounted on UIs | Mounted on DAIs | Mounted on compute nodes |
|:---- |:-------- | ----------:| ----------:|:------:|:-------:|:--------------:|:---------------:|:------------------------:|
{% for mount in lfs_mounts | selectattr('lfs', 'match', '^home$') | list %}
| /{{ mount.lfs }} | Home dirs from shard file system for personal settings/preferences. | 1 GB | 2 GB | Yes | No | Yes | Yes | Yes |
{% endfor %}
{% for mount in lfs_mounts | selectattr('lfs', 'search', 'prm[0-9]+$') | list %}
| /{{ mount.lfs }} | High Availability shared file system for permanent data. | Several TBs; varies per group |  quota + ~10%| Yes | No | Yes | No | No |
{% endfor %}
{% for mount in lfs_mounts | selectattr('lfs', 'search', 'arc[0-9]+$') | list %}
| /{{ mount.lfs }} | High Availability shared file system for archived data. | Several TBs; varies per group |  quota + ~10%| Yes | No | Yes | No | No |
{% endfor %}
{% for mount in lfs_mounts | selectattr('lfs', 'search', 'tmp[0-9]+$') | list %}
| {{ mount.lfs }} | High Performance shared file system for temporary data. | Several TBs; varies per group | quota + ~10% | No | Yes, when older than 45 days | Yes | No | Yes |
{% endfor %}
{% for mount in lfs_mounts | selectattr('lfs', 'search', 'scr[0-9]+$') | list %}
| /{{ mount.lfs }} | High Performance local file system for temporary data. | Several TBs; varies per group | quota + ~10% | No | Yes, when older than 45 days | Yes | No | No |
{% endfor %}

## The life cycle of experimental data

 1. Generate _"raw data"_ in a lab and upload that to a folder in ```/groups/${group}/prm*/rawdata/...``` on HA storage.
 1. Select a (sub)set of your _"raw data"_ you want to analyze on the cluster and stage this data by copying it from ```/groups/${group}/prm*/rawdata/...``` to ```/groups/${group}/tmp*/...``` on HP storage.  
    Make sure your in-silico experiment processes a chunk of data that can easily be analysed in << 45 days.
 1. Generate jobs, which will read and write to and from folders in ```/groups/${group}/tmp*/...``` on HP storage systems.
 1. Submit your jobs on the Slurm workload manager with the ```sbatch``` command.
 1. Once all jobs have finished successfully, assess the results and if they pass QC, store your final results by copying them to a folder in ```/groups/${group}/prm*/projects/...``` on HA storage.
 1. Cleanup by deleting data from ```/groups/${group}/tmp*/...``` to free up space for your next experiment.
 1. Document and publish your experiment/data.

