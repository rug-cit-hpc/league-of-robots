# Technical specifications of the High Performance Computing (HPC) environment on {{ slurm_cluster_name | capitalize }}

## Software

Key ingredients of the High Performance Computing (HPC) environment of the {{ slurm_cluster_name | capitalize }} cluster

 * Linux OS: [CentOS](https://www.centos.org/) {{ hostvars[groups['user-interface'][0]]['ansible_distribution_version'] }} with [Spacewalk](https://spacewalkproject.github.io/) for package distribution/management.
 * Job scheduling: [Slurm Workload Manager](https://slurm.schedmd.com/) {{ slurm_version.stdout }}
 * Module system: [Lmod](https://github.com/TACC/Lmod) {{ lmod_version.stdout }}
 * Deployment of (Bioinformatics) software: [EasyBuild](https://github.com/easybuilders/easybuild)

## Virtual Servers

 * Jumphosts: _{% for server in groups['jumphost'] %}{{ server | regex_replace('^' + ai_jumphost + '\\+','')}}{% if not loop.last %}, {% endif %}{% endfor %}_
 * User Interfaces (UIs): _{% for server in groups['user-interface'] %}{{ server | regex_replace('^' + ai_jumphost + '\\+','')}}{% if not loop.last %}, {% endif %}{% endfor %}_
 * Deploy Admin Interfaces (DAIs): _{% for server in groups['deploy-admin-interface'] %}{{ server | regex_replace('^' + ai_jumphost + '\\+','')}}{% if not loop.last %}, {% endif %}{% endfor %}_
 * Sys Admin Interfaces (SAIs): _{% for server in groups['sys-admin-interface'] %}{{ server | regex_replace('^' + ai_jumphost + '\\+','')}}{% if not loop.last %}, {% endif %}{% endfor %}_
 * Compute Nodes: _{% for server in groups['compute-vm'] %}{{ server | regex_replace('^' + ai_jumphost + '\\+','')}}{% if not loop.last %}, {% endif %}{% endfor %}_

## Resources available to Slurm jobs


| Resource            | Amount/value/name                      |
|:------------------- | --------------------------------------:|
| Compute nodes       | {{ stack_prefix }}-vcompute\[01-03\]   |
| Cores/node          | {{ vcompute_max_cpus_per_node }}       |
| RAM/node \(MB\)     | {{ vcompute_max_mem_per_node }}        |
| Storage/node \(GB\) | {{ vcompute_local_disk }}              |
| Node features       | {{ vcompute_features }}                |

