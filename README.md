# League of Robots

## About this repo

This repository contains playbooks and documentation to deploy virtual Linux HPC clusters, which can be used as *collaborative, analytical sandboxes*.
All clusters were named after robots that appear in the animated sitcom [Futurama](https://en.wikipedia.org/wiki/Futurama)

#### Software/framework ingredients

The main ingredients for (deploying) these clusters:
 * [Ansible playbooks](https://github.com/ansible/ansible) for system configuration management.
 * [OpenStack](https://www.openstack.org/) for virtualization. (Note that deploying the OpenStack itself is not part of the configs/code in this repo.)
 * [Spacewalk](https://spacewalkproject.github.io/index.html) to create freezes of Linux distros.
 * [CentOS 7](https://www.centos.org/) as OS for the virtual machines.
 * [Slurm](https://slurm.schedmd.com/) as workload/resource manager to orchestrate jobs.

#### Protected branches
The master and develop branches of this repo are protected; updates can only be merged into these branches using reviewed pull requests.

#### Code style and naming conventions

We follow the [Python PEP8 naming conventions](https://www.python.org/dev/peps/pep-0008/#naming-conventions) for variable names, function names, etc.

## Clusters

This repo currently contains code and configs for the following clusters:
 * Gearshift: [UMCG](https://www.umcg.nl) Research IT cluster hosted by the [Center for Information Technology (CIT) at the University of Groningen](https://www.rug.nl/society-business/centre-for-information-technology/).
 * Talos: Development cluster hosted by the [Center for Information Technology (CIT) at the University of Groningen](https://www.rug.nl/society-business/centre-for-information-technology/).
 * Hyperchicken: [Solve-RD](solve-rd.eu/) cluster hosted by [The European Bioinformatics Institute (EMBL-EBI)](https://www.ebi.ac.uk/) in the [Embassy Cloud](https://www.embassycloud.org/).

Deployment and functional administration of all clusters is a joined effort of the
[Genomics Coordination Center (GCC)](http://wiki.gcc.rug.nl/)
and the 
[Center for Information Technology (CIT)](https://www.rug.nl/society-business/centre-for-information-technology/)
from the [University Medical Center](https://www.umcg.nl) and [University](https://www.rug.nl) of Groningen.

#### Cluster components

The clusters are composed of the following type of machines:
 * **Jumphost**: security-hardened machines for SSH access.
 * **User Interface (UI)**: machines for job management by regular users.
 * **Deploy Admin Interface (DAI)**: machines for deployment of bioinformatics software and reference datasets without root access.
 * **Sys Admin Interface (SAI)**: machines for maintenance / management tasks that require root access.
 * **Compute Node (CN)**: machines that crunch jobs submitted by users on a UI.
 
The clusters use the following types of storage systems / folders:

| Filesystem/Folder           | Shared/Local | Backups | Mounted on           | Purpose/Features |
| :-------------------------- | :----------: | :-----: | :------------------- | :--------------- |
| /home/${home}/              | Shared       | Yes     | UIs, DAIs, SAIs, CNs | Only for personal preferences: small data == tiny quota.|
| /groups/${group}/prm[0-9]/  | Shared       | Yes     | UIs, DAIs            | **p**e**rm**anent storage folders: for rawdata or *final* results that need to be stored for the mid/long term. |
| /groups/${group}/tmp[0-9]/  | Shared       | No      | UIs, DAIs, CNs       | **t**e**mp**orary storage folders: for staged rawdata and intermediate results on compute nodes that only need to be stored for the short term. |
| /groups/${group}/scr[0-9]/  | Local        | No      | Some UIs             | **scr**atch storage folders: same as **tmp**, but local storage as opposed to shared storage. Optional and available on all UIs. |
| /local/${slurm_job_id}      | Local        | No      | CNs                  | Local storage on compute nodes only available during job execution. Hence folders are automatically created when a job starts and deleted when it finishes. |
| /mnt/${complete_filesystem} | Shared       | Mixed   | SAIs                 | Complete file systems, which may contain various `home`, `prm`, `tmp` or `scr` dirs. |

## Deployment phases

Deploying a fully functional virtual cluster involves the following steps:
 1. Configure physical machines
 2. Deploy OpenStack virtualization layer on physical machines to create an OpenStack cluster
 3. Create and configure virtual machines on the OpenStack cluster to create an HPC cluster on top of an OpenStack cluster
 4. Deploy bioinformatics software and reference datasets 

---

### 2. Ansible playbooks OpenStack cluster
The ansible playbooks in this repository use roles from the [hpc-cloud](https://git.webhosting.rug.nl/HPC/hpc-cloud) repository.
The roles are imported here explicitely by ansible using ansible galaxy.
These roles install various docker images built and hosted by RuG webhosting. They are built from separate git repositories on https://git.webhosting.rug.nl.

#### Deployment of OpenStack
The steps below describe how to get from machines with a bare ubuntu 16.04 installed to a running openstack installation.

---

1. First import the required roles into this playbook:
   
   ```bash
   ansible-galaxy install -r requirements.yml --force -p roles
   ansible-galaxy install -r galaxy-requirements.yml
   ```

2. Generate an ansible vault password and put it in `.vault_pass.txt`. This could be done by running the following oneliner:

   ```bash
   tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1 > .vault_pass.txt
   ```

3. Configure Ansible settings including the vault.
   * To create (a new) secrets.yml:
     Generate and encrypt the passwords for the various openstack components.
     ```bash
     ./generate_secrets.py
     ansible-vault --vault-password-file=.vault_pass.txt encrypt secrets.yml
     ```
     The encrypted secrets.yml can now safely be comitted.
     The `.vault_pass.txt` file is in the .gitignore and needs to be tranfered in a secure way.

   * To use use an existing encrypted secrets.yml add .vault_pass.txt to the root folder of this repo
     and create in the same location ansible.cfg using the following template:
     ```[defaults]
     inventory = hosts
     stdout_callback = debug
     forks = 20
     vault_password_file = .vault_pass.txt
     remote_user = your_local_account_not_from_the_LDAP
     ```

4. Running playbooks. Some examples:
   * Install the OpenStack cluster.
     ```bash
     ansible-playbook site.yml
     ```
   * Deploying only the SLURM part on test cluster *Talos*
     ```bash
     ansible-playbook site.yml -i talos_hosts slurm.yml
     ```

5. verify operation.

#### Steps to upgrade openstack cluster.

### 3. Steps to install Compute cluster on top of openstack cluster.
