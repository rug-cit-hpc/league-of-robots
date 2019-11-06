# Creating patched Slurm for HPC cluster #

Table of Contents:

* [Summary](#-summary)
* [Patch and Build RPM](#-patch-and-build)

---

# <a name="Summary"/> Summary

We use a patched Slurm version in order to allow all users to retrieve job stats for all jobs with ```sstat```
and tools that depend on ```sstat``` (e.g. ```ctop``` from the ```cluster-utils``` module).
In a plain vanilla Slurm version only the root user can get the jobs stats for running of all jobs.
Regular users can only retrieve job stats for their own running jobs 
(and for all completed jobs using sacct and the Slurm accounting DB).
The rationale for the default behaviour is that fetching the stats for all jobs can cause quite some load on very large clusters
(thousands of nodes), but on the smaller clusters we use the load from ```sstat``` is negligible.

# <a name="Patch-and-Build"/> Patch and Build

### 1. Setup rpmbuild

```
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
if [ -f ~/.rpmmacros ];then
    echo '~/.rpmmacros already exists.'
else
    echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros
    echo 'Initialized ~/.rpmmacros'
fi
```

### 2. Download and unpack Slurm

```
wget https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2
tar -xvjf slurm-${SLURM_VERSION}.tar.bz2
```


### 3. Patching slurmd source

Disabled UID check in **_rpc_stat_jobacct** function of
```
slurm-${SLURM_VERSION}/src/slurmd/slurmd/rec.c
```
to allow all users to retrieve job stats for all jobs with ```sstat```:
```
    /*
     * check that requesting user ID is the SLURM UID or root
     * DISABLED to allow sstat to retrieve job stats for all running jobs of all users.
     * This may have a negative impact on highly parallellized apps or large clusters.
     */
    /*if ((req_uid != uid) && (!_slurm_authorized_user(req_uid))) {
    *    error("stat_jobacct from uid %ld for job %u " 
    *             "owned by uid %ld",
    *             (long) req_uid, req->job_id, (long) uid);
    *
    *    if (msg->conn_fd >= 0) {
    *               slurm_send_rc_msg(msg, ESLURM_USER_ID_MISSING);
    *               close(fd);
    *               return ESLURM_USER_ID_MISSING;
    *    }
    }*/
```

### 4. Append umcg suffix to version/release number

Patch the SLURM ```slurm-${SLURM_VERSION}/slurm.spec``` file.

 * Append ```.umcg``` suffix to release in the SLURM ```slurm-${SLURM_VERSION}/slurm.spec``` file.
   Example for Slurm 18.08.8 where the patch level (last number) is ```8```:
   Change:
   ```
       Release: 8%{?dist}
   ```
   into:
   ```
       Release: 8%{?dist}.umcg
   ```
   The patch level number may be different for other releases.
 * Change:
   ```
       # when the rel number is one, the directory name does not include it
       %if "%{rel}" == "1"
       %global slurm_source_dir %{name}-%{version}
       %else
       %global slurm_source_dir %{name}-%{version}-%{rel}
       %endif
   ```
   into:
   ```
       %global slurm_source_dir %{name}-%{version}-%{rel}.umcg
   ```

Make sure to also add the ```.umcg``` suffix to the folder name:

```
mv slurm-${SLURM_VERSION} slurm-${SLURM_VERSION}.umcg
```

### 5. Create new tar.bz2 source code archive with patched code

```
tar -cvjf ~/rpmbuild/SOURCES/slurm-${SLURM_VERSION}.umcg.tar.bz2  slurm-${SLURM_VERSION}.umcg
```

### 6. Build patched RPMs

```
rpmbuild -ta --with lua --with mysql ~/rpmbuild/SOURCES/slurm-${SLURM_VERSION}.umcg.tar.bz2
```
When successful, add patched RPMs to custom repo and don't forget to contact admin to update relevant spacewalk channels!
E.g.:
```
rsync -av ~/rpmbuild/RPMS/x86_64/slurm-${SLURM_VERSION}-*.x86_64.rpm  spacewalk02:umcg-centos7/
```