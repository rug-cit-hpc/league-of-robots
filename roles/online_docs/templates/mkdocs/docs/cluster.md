# The {{ slurm_cluster_name | capitalize }} HPC cluster

The {{ slurm_cluster_name | capitalize }} High Performance Compute (HPC) cluster is part of the league of robots - a collection of HPC clusters, 
which are named after robots from the the animated sitcom [Futurama](https://en.wikipedia.org/wiki/Futurama).
Deployment and functional administration of all clusters is a joined effort of the
[Genomics Coordination Center (GCC)](http://wiki.gcc.rug.nl/)
and the 
[Center for Information Technology (CIT)](https://www.rug.nl/society-business/centre-for-information-technology/)
from the [University Medical Center](https://www.umcg.nl) and [University](https://www.rug.nl) of Groningen, 
in collaboration with and as part of several research projects including

* [ELIXIR compute platform](https://www.elixir-europe.org/platforms/compute)
* [EXCELERATE](https://www.elixir-europe.org/about-us/how-funded/eu-projects/excelerate)
* [EU-Solve-RD](http://solve-rd.eu/), the European Joint Project for Rare disease
* [CORBEL](https://www.corbel-project.eu/home.html)

![RUG-UMCG](img/RUGUMCGduobrand.png)

The key features of the the {{ slurm_cluster_name | capitalize }} cluster:

 * Linux OS: [CentOS](https://www.centos.org/) 7.x with [Spacewalk](https://spacewalkproject.github.io/) for package distribution/management.
 * Completely virtualised on an [OpenStack](https://www.openstack.org/) cloud
 * Deployment of HPC cluster with [Ansible playbooks](https://docs.ansible.com/ansible/latest/index.html) under version control in a Git repo: [league-of-robots](https://github.com/rug-cit-hpc/league-of-robots)
 * Job scheduling: [Slurm Workload Manager](https://slurm.schedmd.com/)
 * Account management:
    * Local admin users+groups provisioned using Ansible.
    * Regular users+groups in a dedicated LDAP for this cluster and provisioned either with Ansible playbook too or using info from federated AAIM.
 * Module system: [Lmod](https://github.com/TACC/Lmod)
 * Deployment of (Bioinformatics) software using [EasyBuild](https://github.com/easybuilders/easybuild)

## Cluster components

The HPC cluster consists of various types of server. Some of these can be accessed directly by users, whereas others cannot be accessed directly.

![cluster](img/cluster-small.svg)

 * Jumphost:
     * For all users
     * Security hardened machine for multi-hop SSH access to UI, DAI & SAI.
     * Nothings else: no job management, no mounts of shared file systems, no homes, no /apps, etc.
 * User Interface (UI):
     * Logins for all users (via the jumphost).
     * Slurm tools/commands installed job management: submitting batch jobs, canceling batch jobs, interactive jobs, job profiling, etc.
     * Read-only access to software, modules and reference data deployed with EasyBuild+Lmod in /apps/…
     * Both tmp and prm folders from large, shared, parallel file systems mounted (with root squash) for data transfers/staging.
 * Deploy Admin Interface (DAI):
     * Only for deploy admins (via the jumphost).
     * For deployment of centrally managed software or reference data sets using:
       Ansible playbooks + Lmod + EasyBuild
     * No slurm tools/commands installed, so no accidental job management.
     * Read-write access to software, modules and reference data deployed with EasyBuild+Lmod in /apps/...
     * No access to large, shared, parallel file systems.
 * Sys Admin Interface (SAI):
     * Only for sys admins (via the jumphost).
     * Used to manage and monitor the cluster components: generate quota and slurm usage reports, run cron jobs, etc.
     * Runs SLURM scheduling daemon that determines when jobs will be executed on which nodes.
     * Access to (complete) large shared parallel file systems (without root squash).
 * Compute Nodes:
     * No direct logins.
     * Crunch batch jobs submitted to SLURM scheduler.

#### Themes:

The {{ slurm_cluster_name | capitalize }} HPC cluster is part of a family of clusters that use the same themes for naming various components:

 * Cluster itself and UIs are named after robots from the [Futurama scifi sitcom](https://futurama.fandom.com/wiki/Category:Robots)  
   E.g.: {{ slurm_cluster_name | capitalize }} UI = _{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_
 * Jumphosts are named after rooms preceding other rooms.  
   E.g.: {{ slurm_cluster_name | capitalize }} Jumphost = _{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}.{{ slurm_cluster_domain }}_
 * Other machines that are part of the cluster and only accessible using internal network interfaces (schedulers, compute nodes, account servers, etc.)  
   will use a two character prefix _{{ stack_prefix }}_ followed by a dash and the function of the machine.  
   E.g. {{ slurm_cluster_name | capitalize }} compute node = _{{ groups['compute-vm'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_
 * SAIs & DAIs may be named after root/carrot varieties or simply use the two character prefix _{{ stack_prefix }}_ plus function of the machine.  
   E.g.: {{ slurm_cluster_name | capitalize }} DAI = _{{ groups['deploy-admin-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_  
   E.g.: {{ slurm_cluster_name | capitalize }} SAI = _{{ groups['sys-admin-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}_
