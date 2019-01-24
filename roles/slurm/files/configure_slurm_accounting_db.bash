#!/bin/bash

#
##
### Create Slurm DB for the accounting info of this cluster.
##
#
sacctmgr add cluster {{ slurm_cluster_name }}

#
##
### Create Quality of Service (QoS) levels.
##
#

#
# QoS leftover
#
sacctmgr -i create qos set \
        Name='leftover' \
        Priority=0 \
        UsageFactor=0 \
        Description='Go Dutch: Quality of Service level for cheapskates with zero priority, but resources consumed do not impact your Fair Share.' \
        GrpSubmit=30000 MaxSubmitJobsPU=10000 \
        GrpTRES=cpu=0,mem=0

sacctmgr -i create qos set \
        Name='leftover-short' \
        Priority=0 \
        UsageFactor=0 \
        Description='leftover-short' \
        GrpSubmit=30000 MaxSubmitJobsPU=10000 MaxWall=06:00:00

sacctmgr -i create qos set \
        Name='leftover-medium' \
        Priority=0 \
        UsageFactor=0 \
        Description='leftover-medium' \
        GrpSubmit=30000 MaxSubmitJobsPU=10000 MaxWall=1-00:00:00

sacctmgr -i create qos set \
        Name='leftover-long' \
        Priority=0 \
        UsageFactor=0 \
        Description='leftover-long' \
        GrpSubmit=3000 MaxSubmitJobsPU=1000  MaxWall=7-00:00:00

#
# QoS regular
#
sacctmgr -i create qos set \
        Name='regular' \
        Priority=10 \
        Description='Standard Quality of Service level with default priority and corresponding impact on your Fair Share.' \
        GrpSubmit=30000 MaxSubmitJobsPU=5000 \
        GrpTRES=cpu=0,mem=0

sacctmgr -i create qos set \
        Name='regular-short' \
        Priority=10 \
        Description='regular-short' \
        GrpSubmit=30000 MaxSubmitJobsPU=5000  MaxWall=06:00:00

sacctmgr -i create qos set \
        Name='regular-medium' \
        Priority=10 \
        Description='regular-medium' \
        GrpSubmit=30000 MaxSubmitJobsPU=5000  MaxWall=1-00:00:00 \
        MaxTRESPU=cpu={{ (cluster_cores_total * 0.4) | int }},mem={{ (cluster_mem_total * 0.4) | int }}

sacctmgr -i create qos set \
        Name='regular-long' \
        Priority=10 \
        Description='regular-long' \
        GrpSubmit=3000 MaxSubmitJobsPU=1000  MaxWall=7-00:00:00 \
        GrpTRES=cpu={{ (cluster_cores_total * 0.3) | int }},mem={{ (cluster_mem_total * 0.3) | int }} \
        MaxTRESPU=cpu={{ (cluster_cores_total * 0.15) | int }},mem={{ (cluster_mem_total * 0.15) | int }}

#
# QoS priority
#
sacctmgr -i create qos set \
        Name='priority' \
        Priority=20 \
        UsageFactor=2 \
        Description='High priority Quality of Service level with corresponding higher impact on your Fair Share.' \
        GrpSubmit=5000  MaxSubmitJobsPU=1000 \
        GrpTRES=cpu=0,mem=0

sacctmgr -i create qos set \
        Name='priority-short' \
        Priority=20 \
        UsageFactor=2 \
        Description='priority-short' \
        GrpSubmit=5000  MaxSubmitJobsPU=1000   MaxWall=06:00:00 \
        MaxTRESPU=cpu={{ (cluster_cores_total * 0.25) | int }},mem={{ (cluster_mem_total * 0.25) | int }}

sacctmgr -i create qos set \
        Name='priority-medium' \
        Priority=20 \
        UsageFactor=2 \
        Description='priority-medium' \
        GrpSubmit=2500  MaxSubmitJobsPU=500   MaxWall=1-00:00:00 \
        GrpTRES=cpu={{ (cluster_cores_total * 0.5) | int }},mem={{ (cluster_mem_total * 0.5) | int }} \
        MaxTRESPU=cpu={{ (cluster_cores_total * 0.2) | int }},mem={{ (cluster_mem_total * 0.2) | int }}

sacctmgr -i create qos set \
        Name='priority-long' \
        Priority=20 \
        UsageFactor=2 \
        Description='priority-long' \
        GrpSubmit=250   MaxSubmitJobsPU=50   MaxWall=7-00:00:00 \
        GrpTRES=cpu={{ (cluster_cores_total * 0.2) | int }},mem={{ (cluster_mem_total * 0.2) | int }} \
        MaxTRESPU=cpu={{ (cluster_cores_total * 0.1) | int }},mem={{ (cluster_mem_total * 0.1) | int }}

#
# QoS ds
#
sacctmgr -i create qos set \
        Name='ds' \
        Priority=10 \
        UsageFactor=1 \
        Description='Data Staging Quality of Service level for jobs with access to prm storage.' \
        GrpSubmit=5000  MaxSubmitJobsPU=1000 \
        GrpTRES=cpu=0,mem=0

sacctmgr -i create qos set \
        Name='ds-short' \
        Priority=10 \
        UsageFactor=1 \
        Description='ds-short' \
        GrpSubmit=5000  MaxSubmitJobsPU=1000   MaxWall=06:00:00 \
        MaxTRESPU=cpu=4,mem=4096

sacctmgr -i create qos set \
        Name='ds-medium' \
        Priority=10 \
        UsageFactor=1 \
        Description='ds-medium' \
        GrpSubmit=2500  MaxSubmitJobsPU=500   MaxWall=1-00:00:00 \
        GrpTRES=cpu=2,mem=2048 \
        MaxTRESPU=cpu=2,mem=2048

sacctmgr -i create qos set \
        Name='ds-long' \
        Priority=10 \
        UsageFactor=1 \
        Description='ds-long' \
        GrpSubmit=250   MaxSubmitJobsPU=50   MaxWall=7-00:00:00 \
        GrpTRES=cpu=1,mem=1024 \
        MaxTRESPU=cpu=1,mem=1024

#
# List all QoS.
#
#sacctmgr show qos format=Name%15,Priority,UsageFactor,GrpTRES%30,GrpSubmit,GrpJobs,MaxTRESPerUser%30,MaxSubmitJobsPerUser,MaxJobsPerUser,MaxTRESPerJob,MaxWallDurationPerJob

#
##
### Create accounts and assign QoS to accounts.
##
#

#
# Create 'users' account in addition to the default 'root' account.
#
sacctmgr -i create account users \
         Descr=scientists Org=various

#
# Assign QoS to the root account.
#
sacctmgr -i modify account root set \
         QOS=priority,priority-short,priority-medium,priority-long

sacctmgr -i modify account root set \
         QOS+=leftover,leftover-short,leftover-medium,leftover-long

sacctmgr -i modify account root set \
         QOS+=regular,regular-short,regular-medium,regular-long

sacctmgr -i modify account root set \
         QOS+=dev,dev-short,dev-medium,dev-long

sacctmgr -i modify account root set \
         QOS+=ds,ds-short,ds-medium,ds-long

sacctmgr -i modify account root set \
         DefaultQOS=priority

#
# Assign QoS to the users account.
#
sacctmgr -i modify account users set \
         QOS=regular,regular-short,regular-medium,regular-long

sacctmgr -i modify account users set \
         QOS+=priority,priority-short,priority-medium,priority-long

sacctmgr -i modify account users set \
         QOS+=leftover,leftover-short,leftover-medium,leftover-long

sacctmgr -i modify account users set \
         QOS+=dev,dev-short,dev-medium,dev-long

sacctmgr -i modify account users set \
         QOS+=ds,ds-short,ds-medium,ds-long

sacctmgr -i modify account users set \
         DefaultQOS=regular

#
# List all associations to verify the required accounts exist and the right (default) QoS.
#
#sacctmgr show assoc tree format=Cluster%8,Account,User%-30,Share%5,QOS%-222,DefaultQOS%-8

#
# Allow QoS priority to pre-empt jobs in QoS leftover.
#
sacctmgr -i modify qos Name='priority-short'  set Preempt='leftover-short,leftover-medium,leftover-long'
sacctmgr -i modify qos Name='priority-medium' set Preempt='leftover-short,leftover-medium,leftover-long'
sacctmgr -i modify qos Name='priority-long'   set Preempt='leftover-short,leftover-medium,leftover-long'

#
# Allow QoS regular to pre-empt jobs in QoS leftover.
#
sacctmgr -i modify qos Name='regular-short'   set Preempt='leftover-short,leftover-medium,leftover-long'
sacctmgr -i modify qos Name='regular-medium'  set Preempt='leftover-short,leftover-medium,leftover-long'
sacctmgr -i modify qos Name='regular-long'    set Preempt='leftover-short,leftover-medium,leftover-long'

#
# List all QoS and verify pre-emption settings.
#
#sacctmgr show qos format=Name%15,Priority,UsageFactor,GrpTRES%30,GrpSubmit,GrpJobs,MaxTRESPerUser%30,MaxSubmitJobsPerUser,Preempt%45,MaxWallDurationPerJob

