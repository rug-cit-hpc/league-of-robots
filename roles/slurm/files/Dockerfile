#
# Centos7 Slurm Server
#

FROM centos:7

MAINTAINER Egon Rijpkema <e.m.a.rijpkema@rug.nl>

# Openldap client, installing from spacewalk leads to conflicts.
{% if slurm_ldap %}
RUN yum install -y openldap-clients nss-pam-ldapd openssh-ldap wget

# add openldap config
ADD ldap.conf /etc/openldap/ldap.conf
ADD nslcd.conf /etc/nslcd.conf
ADD pam_ldap.conf /etc/pam_ldap.conf
ADD nsswitch.conf /etc/nsswitch.conf

RUN chmod 600 /etc/nslcd.conf
{% endif %}

# Install spacewalk client
RUN rpm -Uvh https://copr-be.cloud.fedoraproject.org/results/@spacewalkproject/spacewalk-2.8-client/epel-7-x86_64/00742644-spacewalk-repo/spacewalk-client-repo-2.8-11.el7.centos.noarch.rpm
RUN yum install rhn-client-tools rhn-check rhn-setup rhnsd m2crypto yum-rhn-plugin -y
RUN rhnreg_ks --force --serverUrl={{ spacewalk_server_url }}  --activationkey={{ activation_key }}

RUN groupadd -g {{ slurm_gid }} slurm
RUN useradd  -g {{ slurm_gid }} -u {{ slurm_uid }} slurm
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
                   mailx           \
                   ssmtp           \
                   --nogpgcheck

# Slurm needs /sbin/mail to work in order to send mail

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
