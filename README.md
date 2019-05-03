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

#### Branches and Releases
The master and develop branches of this repo are protected; updates can only be merged into these branches using reviewed pull requests.
Once a while we create releases, which are versioned using the format ```YY.MM.v``` where:

 * ```YY``` is the year of release
 * ```MM``` is the month of release
 * ```v``` is the first release in that month and year. Hence it is not the day of the month.

E.g. ```19.01.1``` is the first release in January 2019.

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
from the [University Medical Center](https://www.umcg.nl) and [University](https://www.rug.nl) of Groningen, in collaboration with [ELIXIR compute platform](https://www.elixir-europe.org/platforms/compute), [EXCELERATE](https://www.elixir-europe.org/about-us/how-funded/eu-projects/excelerate), [EU-Solve-RD](http://solve-rd.eu/), European Joint Project for Rare disease and [CORBEL](https://www.corbel-project.eu/home.html) projects.

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

#### Steps to upgrade the OpenStack cluster

### 3. Steps to deploy HPC compute cluster on top of OpenStack cluster
---

0. Clone this repo.
   ```bash
   mkdir -p ${HOME}/git/
   cd ${HOME}/git/
   git clone https://github.com/rug-cit-hpc/league-of-robots.git
   ```

1. First import the required roles into this playbook:
   
   ```bash
   ansible-galaxy install -r requirements.yml --force -p roles
   ansible-galaxy install -r galaxy-requirements.yml
   ```

2. Create `.vault_pass.txt`.
   * To generate a new Ansible vault password and put it in `.vault_pass.txt`, use the following oneliner:
   ```bash
   tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1 > .vault_pass.txt
   ```
   * Or to use an existing Ansible vault password create `.vault_pass.txt` and use a text editor to add the password.
   Make sure the `.vault_pass.txt` is private:
   ```bash
   chmod go-rwx .vault_pass.txt
   ```

3. Configure Ansible settings including the vault.
   * To create (a new) secrets.yml:
     Generate and encrypt the passwords for the various OpenStack components.
     ```bash
     ./generate_secrets.py
     ansible-vault --vault-password-file=.vault_pass.txt encrypt secrets.yml
     ```
     The encrypted secrets.yml can now safely be committed.
     The `.vault_pass.txt` file is in the .gitignore and needs to be transfered in a secure way.

   * To use use an existing encrypted secrets.yml add .vault_pass.txt to the root folder of this repo
     and create in the same location ansible.cfg using the following template:
     ```[defaults]
     inventory = hosts
     stdout_callback = debug
     forks = 20
     vault_password_file = .vault_pass.txt
     remote_user = your_local_account_not_from_the_LDAP
     ```

4. Configure the Certificate Authority (CA).
   We use an SSH public-private key pair to sign the host keys of all the machines in a cluster.
   This way users only need the public key of the CA in their ```~.ssh/known_hosts``` file
   and will not get bothered by messages like this:
   ```
      The authenticity of host '....' can't be established.
      ECDSA key fingerprint is ....
      Are you sure you want to continue connecting (yes/no)?
   ```
   * The filename of the CA private key is specified using the ```ssh_host_signer_ca_private_key``` variable defined in ```group_vars/*/vars.yml```
   * The filename of the corresponding CA public key must be the same as the one of the private key suffixed with ```.pub```
   * The password required to decrypt the CA private key must be specified using the ```ssh_host_signer_ca_private_key_pass``` variable defined in ```group_vars/*/secrets.yml```,
     which must be encrypted with ```ansible-vault```.
   * Each user must add the content of the CA public key to their ```~.ssh/known_hosts``` like this:
     ```
     @cert-authority [names of the hosts for which the cert is valid] [content of the CA public key]
     ```
     E.g.:
     ```
     @cert-authority reception*,*talos,*tl-* ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDWNAF....VMZpZ5b9+5GA3O8w== UMCG HPC Development CA
     ```
   * Example to create a new CA key pair with the ```rsa``` algorithm:
     ```bash
     ssh-keygen -t ed25519 -a 101 -f ssh-host-ca/ca-key-file-name -C "CA key for ..."
     ```

5. Build Prometheus Node Exporter
   * Make sure you are a member of the `docker` group.
     Otherwise you will get this error:
     ```
        ERRO[0000] failed to dial gRPC: cannot connect to the Docker daemon.
        Is 'docker daemon' running on this host?: dial unix /var/run/docker.sock: connect:
        permission denied
        context canceled
     ```
   * Execute:
     ```bash
     cd promtools
     ./build.sh
     ```
     
6. Generate munge key and encrypt using the ansible-vault.
   * Execute:
   ```
   dd if=/dev/urandom bs=1 count=1024 > roles/slurm-management/files/{clustername}_munge.key
   ansible-vault --vault-password-file=.vault_pass.txt encrypt roles/slurm-management/files/{clustername}_munge.key
   ```   
   The encrypted {clustername}_munge.key can now safely be committed.
   

7. Running playbooks. Some examples:
   * Install the OpenStack cluster.
     ```bash
     ansible-playbook site.yml
     ```
   * Deploying only the SLURM part on test cluster *Talos*
     ```bash
     ansible-playbook site.yml -i talos_hosts slurm.yml
     ```

8. verify operation.
