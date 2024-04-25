# Module Usage Tracking: list how often modules were used on an HPC cluster

Lmod can track which modules are used by sending that info to the syslog each time a user executes ```module load some-module```.
This is done with the ```load_hook``` from a custom ```SitePackage.lua```,
which is deployed with the ```install_easybuild/``` role from the [ansible-pipelines repo](https://github.com/molgenis/ansible-pipelines).

This ```module_usage_tracking``` role configures:

* ```rsydlog``` on the DAIs to receive log messages tagged _ModuleUsageTracking_ and to store them in the log file.
* ```logrotate``` on the DAIs to rotate that log file.

### About the module_usage log file

We do not store the module usage on each cluster node,
but forward this info to the cluster's Deploy Admin Interface (DAI) machine,
which writes the module usage from all clients to the log file ```/var/log/lmod/module_usage``` in the format:

```
YYYY-MM-DDThh:mm:ss+TZ <hostname> ModuleUsageTracking: stack=<stack_prefix> module=<module_name>/<module_version> user=<account_name>
```

For example:
```
2024-04-09T10:33:16+00:00 talos ModuleUsageTracking: stack=tl module=depad-utils/v23.04.1 user=pieter
2024-04-09T10:35:22+00:00 talos ModuleUsageTracking: stack=tl module=cluster-utils/v21.05.1-GCCcore-7.3.0 user=pieter
2024-04-10T18:35:46+00:00 tl-vcompute01 ModuleUsageTracking: stack=tl module=EasyBuild/4.8.0 user=umcg-pneerincx
2024-04-10T18:35:46+00:00 tl-vcompute01 ModuleUsageTracking: stack=tl module=depad-utils/v23.04.1 user=umcg-pneerincx
```

The log file is rotated and compressed weekly resulting in files like this:
```
/var/log/lmod/module_usage-20240204.gz
/var/log/lmod/module_usage-20240211.gz
/var/log/lmod/module_usage-20240218.gz
/var/log/lmod/module_usage-20240225.gz
```

###### parsing the module usage log files to generate a report

In order to summarise module usage for a certain period:
* login on the DAI
* pipe decompressed file(s) content into grep-sorting command
An example of summarizing module usage for period between January and April of 2024 is
```bash
zcat /var/log/lmod/module_usage-20240{01..04}*.gz | grep -oP '(?<=module=)([^ ]*)' | sort -t '/' -k 1,1f -k 2,2rV | uniq -c
```
which will result in something like this:
```
  6 cluster-utils/v21.05.1-GCCcore-7.3.0
  7 depad-utils/v23.04.1
  1 depad-utils/v19.10.1
  3 EasyBuild/4.8.0
  1 Perl/5.34.1-GCCcore-11.3.0
```
