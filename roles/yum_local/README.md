# Local directory yum repository

This playbook does following steps:

# Create repository directory

```
    # mkdir /var/local/repo/
    # chown -R root:root /var/local/repo/
```

## Install system packages

You need a createrepo for making repository's common metadata information and
yum-plugin-priorities for making sure that local repository is used first - this
is defined by priority=1

    # yum install -y createrepo yum-plugin-priorities

## create .repo configuration file
```
# cat << EOF > /etc/yum.repos.d/local.repo
# an integer from 1 to 99. The default priority for repositories is 99.
# The repositories with the lowest numerical priority number have the highest priority.
[local]
name=My RPM System Package Repo
baseurl=file:///var/local/repo/
enabled=1
gpgcheck=0
priority=1
EOF
```

## make repository metadata
```
# createrepo /var/local/repo/
# chmod -R o-w+r /var/local/repo/
```
## adding packages

 - download the package to local folder - for already installed packages
`# yum reinstall --downloadonly --downloaddir=/var/local/repo/ vim`

 - and if package has not been yet installed, use

`# yum install --downloadonly --downloaddir=/var/local/repo/ vim`

 - to create/recreate a repository's metadata

`# createrepo /var/local/repo`

## Testing

`# yum install vim`

and check where it has been downloaded from (note local):

```
==============================================================
 Package         Arch      Version              Repository  Size
==============================================================
Installing:
 vim-enhanced    x86_64    2:7.4.629-8.el7_9       local    1.1 M
```

## To bypass `local` repository when installing package

```
   yum install --disablerepo="local" vim
```

## List all packages from `local` repository

```
    yum  --disablerepo='*' --enablerepo='local' list available
```
