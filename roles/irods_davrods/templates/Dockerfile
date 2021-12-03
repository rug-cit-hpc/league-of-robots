FROM centos:7

ARG ENV_DAVRODS_IRODS_VERSION
ARG ENV_DAVRODS_VERSION
ARG ENV_FILEBEAT_VERSION=7.14.1

RUN yum install -y \
    # Add EPEL repository to download extra packages
    epel-release

# install required packages
RUN ( yum -y install wget nano \
                     git zlib \
                     openssl openssl-libs \
                     boost boost-system boost-filesystem \
                     boost-chrono boost-regex boost-thread \
                     jansson fuse-libs \
                     httpd)

# create temporary directory
RUN ( mkdir -p /tmp )
WORKDIR /tmp

# install iRODS runtime and icommands
ARG irods_version=${ENV_DAVRODS_IRODS_VERSION}
RUN ( rpmkeys --nosignature --import https://packages.irods.org/irods-signing-key.asc || exit ) && echo "== .asc imported"
RUN curl -o /etc/yum.repos.d/renci-irods.yum.repo https://packages.irods.org/renci-irods.yum.repo && echo "== yum installed"
RUN cat /etc/yum.repos.d/renci-irods.yum.repo
RUN yum repolist -y    # this imports the key
RUN yum install -y \
    irods-runtime-${irods_version} \
    irods-icommands-${irods_version}

# install Davrods
ARG davrods_version=${ENV_DAVRODS_VERSION}
ARG davrods_github_tag=$davrods_version
RUN ( wget https://github.com/UtrechtUniversity/davrods/releases/download/$davrods_github_tag/davrods-$davrods_version-1.rpm )
RUN ( rpm -ivh davrods-$davrods_version-1.rpm )
RUN ( mv /etc/httpd/conf.d/davrods-vhost.conf /etc/httpd/conf.d/davrods-vhost.conf.org )

# cleanup RPMs
RUN ( yum clean all && rm -rf *.rpm )


# the executable 'run-httpd.sh' expects the following files to be provided
# and will move them into proper locations before starting the HTTPd service
#
# The expected files:
#   - davrods-vhost.conf: the Apache configuration for the WebDAV vhost
#   - irods_environment.json: runtime environment of iRODS
ADD config/davrods-vhost.conf /config/davrods-vhost.conf
ADD config/irods_environment.json /config/irods_environment.json

#### 443 settings

## dhparm
#         this is not needded anymore, as the dhparams is copied from host.
#         This also speeds up potential docker rebuilds
#RUN openssl dhparam -out /etc/ssl/certs/{{ irods_ssl_dh_params_file }} 2048

# copy existing key into VM
ADD config/{{ irods_ssl_certificate_key_file }} /config/{{ irods_ssl_certificate_key_file }}
ADD config/{{ irods_ssl_certificate_key_file }} /etc/ssl/private/{{ irods_ssl_certificate_key_file }}
RUN chmod 600 /etc/ssl/private/{{ irods_ssl_certificate_key_file }}

# copy existing crt into VM
ADD config/{{ irods_ssl_certificate_chain_file }} /config/{{ irods_ssl_certificate_chain_file }}
ADD config/{{ irods_ssl_certificate_chain_file }} /etc/ssl/certs/{{ irods_ssl_certificate_chain_file }}
RUN chmod 644 /etc/ssl/certs/{{ irods_ssl_certificate_chain_file }}

# copy existing dhparams into VM
ADD config/{{ irods_ssl_dh_params_file }} /config/{{ irods_ssl_dh_params_file }}
ADD config/{{ irods_ssl_dh_params_file }} /etc/ssl/certs/{{ irods_ssl_dh_params_file }}
RUN chmod 644 /etc/ssl/certs/{{ irods_ssl_dh_params_file }}

RUN yum install -y mod_ssl.x86_64

#### end 443 settings
# S.C. 3.12.2021 delete if works after test
# Conditionally trust the custom DataHub Certificate Authority (CA) for iRODS-SSL-connections
# ADD config/test_only_dev_irods_dh_ca_cert.pem /tmp/test_only_dev_irods_dh_ca_cert.pem
# ARG SSL_ENV
# RUN if [[ $SSL_ENV != "acc" ]] && [[ $SSL_ENV != "prod" ]]; then \
#       echo "Adding custom DataHub iRODS-CA-certificate to the CA-rootstore (FOR DEV & TEST ONLY!)..." ; \
#       cp /tmp/test_only_dev_irods_dh_ca_cert.pem /etc/pki/ca-trust/source/anchors/test_only_dev_irods_dh_ca_cert.pem ; \
#       update-ca-trust ; \
#       echo "done!" ; \
#    else \
#       echo "Skipping update of the CA-rootstore" ; \
#    fi

# start httpd
COPY run-httpd.sh /opt/run-httpd.sh
RUN ( chmod +x /opt/run-httpd.sh )

RUN sed -ri \
        -e 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g' \
        -e 's!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g' \
        "/etc/httpd/conf/httpd.conf"


ARG ENV_FILEBEAT_VERSION

###############################################################################
#                                INSTALLATION FILEBEAT
###############################################################################

RUN wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${ENV_FILEBEAT_VERSION}-x86_64.rpm -O /tmp/filebeat.rpm \
 && rpm -Uvh /tmp/filebeat.rpm
ADD filebeat.yml /etc/filebeat/filebeat.yml
RUN chmod go-w /etc/filebeat/filebeat.yml

# EXPOSE 80
EXPOSE 443
CMD ["/opt/run-httpd.sh"]
# To debug: 
# comment out the line above and uncommend one below, then
# rebuild, run the docker and then connect inside instance with
# docker shell ...
#ENTRYPOINT ["tail", "-f", "/dev/null"]


