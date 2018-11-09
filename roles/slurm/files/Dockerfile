#
# Centos7 Slurm Server
#

FROM centos:7

MAINTAINER Egon Rijpkema <e.m.a.rijpkema@rug.nl>

# Openldap client, installing from spacewalk leads to conflicts.
RUN yum install -y openldap-clients nss-pam-ldapd openssh-ldap wget

# add openldap config
ADD ldap.conf /etc/openldap/ldap.conf
ADD nslcd.conf /etc/nslcd.conf
ADD pam_ldap.conf /etc/pam_ldap.conf
ADD nsswitch.conf /etc/nsswitch.conf

RUN chmod 600 /etc/nslcd.conf

# Add umcg repo
RUN yum-config-manager --add-repo http://repo.hpc.rug.nl/umcg-repo/

RUN wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm  && \
    rpm -ivh epel-release-latest-7.noarch.rpm

RUN adduser -u 497 slurm
# Slurm and dependencies
RUN yum install -y slurm           \
                   slurm-lua       \
                   slurm-munge     \
                   slurm-perlapi   \
                   slurm-plugins   \
                   slurm-sjobexit  \
                   slurm-sjstat    \
                   slurm-slurmctld \
                   slurm-slurmdbd  \
                   slurm-sql       \
                   slurm-munge     \
                   munge-libs      \
                   lua-posix       \
                   --nogpgcheck

# Slurm needs /sbin/mail to work in order to send mail
RUN yum install -y mailx ssmtp

# Add ssmtp config
ADD ssmtp.conf /etc/ssmtp/ssmtp.conf

RUN mkdir /var/log/slurm
RUN chown slurm: /var/log/slurm

RUN mkdir /var/spool/slurm
RUN chown slurm: /var/spool/slurm

ADD runslurmctld.sh /runslurmctld.sh
RUN chmod +x /runslurmctld.sh

ADD runslurmdbd.sh /runslurmdbd.sh
RUN chmod +x /runslurmdbd.sh

# our users find UTC confusing
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
