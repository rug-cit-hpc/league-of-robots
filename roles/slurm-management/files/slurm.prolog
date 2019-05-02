#!/bin/bash

#
# Make sure we are successful in making tmp dirs in /local.
# When this failed the job should not continue as SLURM will default to /tmp,
# which is not suitable for heavy random IO nor large data sets.
# Hammering /tmp may effectively result in the node going down.
# When the prolog fails the node will be set to state=DRAIN instead.
#

if [ -z "${SLURM_JOB_ID}" ]; then
    logger -s "FATAL: SLURM_JOB_ID is empty or unset in SLURM prolog."
    exit 1
#else
#    logger -s "DEBUG: Found SLURM_JOB_ID ${SLURM_JOB_ID} in SLURM prolog."
fi

set -e
set -u

#
# Check if local scratch dir is mountpoint and hence not a dir on the system disk.
#
LOCAL_SCRATCH_DIR='/local'
if [ $(stat -c '%d' "${LOCAL_SCRATCH_DIR}") -eq $(stat -c '%d' "${LOCAL_SCRATCH_DIR}/..") ]; then
    logger -s "FATAL: local scratch disk (${LOCAL_SCRATCH_DIR}) is not mounted."
    exit 1
#else
#    logger -s "DEBUG: local scratch disk (${LOCAL_SCRATCH_DIR}) is mounted."
fi

TMPDIR="${LOCAL_SCRATCH_DIR}/${SLURM_JOB_ID}/"
mkdir -m 700 -p "${TMPDIR}" || logger -s "FATAL: failed to create ${TMPDIR}."
chown "${SLURM_JOB_USER}" "${TMPDIR}" || logger -s "FATAL: failed to chown ${TMPDIR}."
