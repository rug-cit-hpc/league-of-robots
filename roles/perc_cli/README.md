# Working with the PERC CLI to configure RAID arrays.

Some of the new machines we got were misconfigured with the local scratch set to JBOD.
To check and change to RAID 0:

* Add _percli RPM_ to Pulp repo server.
* Install the _perccli RPM_ with this role
* Login on machine and then:

```
#
# Become root user on machine.
#
sudo su
#
# Check all info for Controller, Enclosure, Virtual drives and physical diSks.
#
/opt/MegaRAID/perccli/perccli64 /c0 show
#
# Check if controller c0, enclosure 252, disk 0 is configured as JBOD.
#
/opt/MegaRAID/perccli/perccli64 /c0/e252/s0 show jbod
#
# Change that JBOD disk to RAID 0 config
#
/opt/MegaRAID/perccli/perccli64 /c0/e252/s0 set good
/opt/MegaRAID/perccli/perccli64 /c0 add vd r0 drives=252:0
#
# Optionally delete Virtual Drive (VD) if it was misconfigured
# and recreate it again. The first VD is somehow always number 239.
#
/opt/MegaRAID/perccli/perccli64 /c0/v239 delete
/opt/MegaRAID/perccli/perccli64 /c0 add vd r0 drives=252:0
```
