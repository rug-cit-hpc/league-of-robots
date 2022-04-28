#!/bin/bash

# Make sure we're not confused by old, incompletely-shutdown httpd
# context after restarting the container.  httpd won't start correctly
# if it thinks it is already running.
rm -rf /run/httpd/* /tmp/httpd*

if [ -f /config/davrods-vhost.conf ]; then
    if [ -f /etc/httpd/conf.d/davrods-vhost.conf ]; then
        mv /etc/httpd/conf.d/davrods-vhost.conf /etc/httpd/conf.d/davrods-vhost.conf.org
    fi
    cp /config/davrods-vhost.conf /etc/httpd/conf.d/davrods-vhost.conf
    chmod 0644 /etc/httpd/conf.d/davrods-vhost.conf
fi

if [ -f /config/irods_environment.json ]; then
    cp -f /config/irods_environment.json /etc/httpd/irods/irods_environment.json
    chmod 0644 /etc/httpd/irods/irods_environment.json
fi

# start the apache daemon
exec /usr/sbin/apachectl -DFOREGROUND

# this script must end with a persistent foreground process
tail -F /var/log/httpd/access.log /var/log/httpd/error.log |awk '/^==> / {a=substr($0, 5, length-8); next} {print a":"$0}'
