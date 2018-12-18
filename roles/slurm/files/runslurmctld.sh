#!/bin/bash

{% if slurm_ldap %}
# Start the nslcd daemon in the background and then start slurm.
nslcd
{% endif %}

/usr/sbin/slurmctld -D
