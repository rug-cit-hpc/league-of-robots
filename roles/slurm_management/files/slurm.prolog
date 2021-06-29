#!/bin/bash

if [[ -z "${SLURM_JOB_ID}" ]]; then
    logger -s "FATAL: SLURM_JOB_ID is empty or unset in SLURM prolog."
    exit 1
elif [[ -z "${SLURM_JOB_QOS}" ]]; then
    logger -s "FATAL: SLURM_JOB_QOS is empty or unset in SLURM prolog."
    exit 1
#else
#    logger -s "DEBUG: Found SLURM_JOB_ID ${SLURM_JOB_ID} and SLURM_JOB_QOS ${SLURM_JOB_QOS} in SLURM prolog."
fi

set -e
set -u

LOCAL_SCRATCH_DIR='/local'
#
# Check if local scratch dir is mountpoint and hence not a dir on the system disk.
#
if [[ $(stat -c '%d' "${LOCAL_SCRATCH_DIR}") -eq $(stat -c '%d' "${LOCAL_SCRATCH_DIR}/..") ]]; then
    if [[ "${SLURM_JOB_QOS}" =~ ^ds.* ]]; then
        #
        # For the data staging QoS "ds", which executes jobs only on the UI,
        # a dedicated tmp dir per job may be absent as not all UIs have a /local mount.
        #
        logger -s "WARN: local scratch disk (${LOCAL_SCRATCH_DIR}) is not mounted."
    else
        #
        # Make sure we can create tmp dirs in /local on compute nodes.
        # When this fails the job must not continue as SLURM will default to /tmp,
        # which is not suitable for heavy random IO nor large data sets.
        # Hammering /tmp may effectively result in the node going down.
        # When the prolog fails the node will be set to state=DRAIN instead.
        #
        logger -s "FATAL: local scratch disk (${LOCAL_SCRATCH_DIR}) is not mounted."
        exit 1
    fi
else
    #
    # Create dedicated tmp dir for this job.
    #
    TMPDIR="${LOCAL_SCRATCH_DIR}/${SLURM_JOB_ID}/"
    #logger -s "DEBUG: local scratch disk (${LOCAL_SCRATCH_DIR}) is mounted. Trying to create ${TMPDIR} ..."
    mkdir -m 700 -p "${TMPDIR}" || logger -s "FATAL: failed to create ${TMPDIR}."
    chown "${SLURM_JOB_USER}" "${TMPDIR}" || logger -s "FATAL: failed to chown ${TMPDIR}."
fi
