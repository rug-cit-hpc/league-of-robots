# Local directory yum repository

## Info

This playbook deploys local yum repository on particular machine. It creates a folder
where user can store custom rpm's. Then creates repository file on the system (that
uses this local folder), sets the priority of the repository to the maximum (the local
repository will be looked first when installing a package with `yum` command and only
then the other repositories will be checked), and will run initial `createrepo` command
(albeit on a empty folder).

The local yum repository is added to the other repositories, and therefore it works
together with Spacewals, Pulp and regular system repositories.

## Deploying playbook

Playbook is part of cluster.yml and gets executed automatically, but gets deplo-
yed on individual server only when it has variable
```
   local_yum_repository == true
```

When the variable is set to `false`, the playbook will remove the repository co-
nfiguration file. The playbook gets skipped if the variable is not set.

## Playbook steps:

### 1.1. Create repository directory

```
    # mkdir /usr/local/repo/
    # chown -R root:root /usr/local/repo/
```

### 1.2. Install system packages

You need a createrepo for making repository's common metadata information and
yum-plugin-priorities for making sure that local repository is used first - this
is defined by priority=1

    `# yum install -y createrepo yum-plugin-priorities`

## 1.3. Deploy .repo configuration file
```
    # cat << EOF > /etc/yum.repos.d/local.repo
    # an integer from 1 to 99. The default priority for repositories is 99.
    # The repositories with the lowest numerical priority number have the highest priority.
    [local]
    name=My RPM System Package Repo
    baseurl=file:///usr/local/repo/
    enabled=1
    gpgcheck=0
    priority=1
    EOF
```

### 1.4. Create repository metadata

```
    # createrepo /usr/local/repo/
    # chmod -R o-w+r /usr/local/repo/
```

## 1.5 Disabling the local yum repository

Setting the `local_yum_repository` to `false` and running the playbook, will remove
the `.repo` file from `/etc/yum.repos.d` folder, but will keep the folder of repository
and its content intact.
In case needed: cleanup needs to be done manually.

## 2. Manual steps

### 2.1. Adding packages

 - Recommended (if `yumdownloader` program is available), download package to
   local folder
       # yumdownloader --destdir={{ yum_local_repo_dir }} vim

 - Alternatively use - for already installed packages

    `# yum reinstall --downloadonly --downloaddir=/usr/local/repo/ vim`

   and if package has not been yet installed, use

    `# yum install --downloadonly --downloaddir=/usr/local/repo/ vim`

 - to create/recreate a repository's metadata

    `# createrepo /usr/local/repo`

 - sometimes the old cache is still in use, and new packages are not shown when
   searched. Manually cleaning the cache solves the problem

    `# yum clean all`

### 2.2. Testing

    `# yum install vim`

and check where it has been downloaded from (note local):

```
    ==============================================================
     Package         Arch      Version              Repository  Size
    ==============================================================
    Installing:
     vim-enhanced    x86_64    2:7.4.629-8.el7_9       local    1.1 M
```

### 2.3. Getting repository info

```
   [root@wh-chaperone ~]# yum repoinfo local
   Loaded plugins: fastestmirror, priorities
   Loading mirror speeds from cached hostfile
    * base: mirror.proserve.nl
    * centos-sclo-rh: nl.mirrors.clouvider.net
    * centos-sclo-sclo: centos.mirror.transip.nl
    * epel: ftp.nluug.nl
    * extras: nl.mirrors.clouvider.net
    * updates: nl.mirrors.clouvider.net
   2 packages excluded due to repository priority protections
   Repo-id      : local
   Repo-name    : Local yum RPM repository
   Repo-status  : enabled
   Repo-revision: 1657714420
   Repo-updated : Wed Jul 13 12:13:41 2022
   Repo-pkgs    : 1
   Repo-size    : 1.1 M
   Repo-baseurl : file:///usr/local/repo/
   Repo-expire  : 21,600 second(s) (last: Wed Jul 13 12:14:52 2022)
     Filter     : read-only:present
   Repo-filename: /etc/yum.repos.d/local_yum.repo
   
   repolist: 1
   [root@wh-chaperone ~]#

```

## Extra

### 3.1. To bypass `local` repository

To install package and not use local repository you can use

```
    yum install --disablerepo="local" vim
```

### 3.2. List `local` packages

To list all packages from `local` repository

```
    yum  --disablerepo='*' --enablerepo='local' list available
```
