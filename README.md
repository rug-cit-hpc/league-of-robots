# League of Robots

## About this repo

This repository contains playbooks and documentation to deploy virtual Linux HPC clusters, which can be used as *collaborative, analytical sandboxes*.
All production clusters were named after robots that appear in the animated sitcom [Futurama](https://en.wikipedia.org/wiki/Futurama).
Test/development clusters were named after other robots.

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

 * Talos: Development cluster hosted by the [Center for Information Technology (CIT) at the University of Groningen](https://www.rug.nl/society-business/centre-for-information-technology/).
 * Gearshift: [UMCG](https://www.umcg.nl) Research IT production cluster hosted by the [Center for Information Technology (CIT) at the University of Groningen](https://www.rug.nl/society-business/centre-for-information-technology/).
 * Hyperchicken: Development cluster cluster hosted by [The European Bioinformatics Institute (EMBL-EBI)](https://www.ebi.ac.uk/) in the [Embassy Cloud](https://www.embassycloud.org/).
 * Fender: [Solve-RD](solve-rd.eu/) production cluster hosted by [The European Bioinformatics Institute (EMBL-EBI)](https://www.ebi.ac.uk/) in the [Embassy Cloud](https://www.embassycloud.org/).

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

Deploying a fully functional virtual cluster from scratch involves the following steps:

 1. Configure physical machines
    * Off topic for this repo.
 2. Deploy OpenStack virtualization layer on physical machines to create an OpenStack cluster.
    * Off topic for this repo.
    * For the _Shikra_ cloud, which hosts the _Talos_ and _Gearshift_ HPC clusters
      we use the ansible playbooks from the [hpc-cloud](https://git.webhosting.rug.nl/HPC/hpc-cloud) repository
      to create the OpenStack cluster.
    * For other HPC clusters we use OpenStack clouds from other service providers as is.
 3. Create, start and configure virtual machines on an OpenStack cluster to create a Slurm HPC cluster.
    * This repo.
 4. Deploy bioinformatics software and reference datasets.
    * Off topic for this repo.
    * We use the ansible playbook from the [ansible-pipelines](https://github.com/molgenis/ansible-pipelines) repository
      to deploy Lua + Lmod + EasyBuild. The latter is then used to install bioinformatics tools.

---

### 3. Create, start and configure virtual machines on an OpenStack cluster to create a Slurm HPC cluster.

0. Clone this repo.
   ```bash
   mkdir -p ${HOME}/git/
   cd ${HOME}/git/
   git clone https://github.com/rug-cit-hpc/league-of-robots.git
   ```

1. First import the required roles into this playbook:

   ```bash
   ansible-galaxy install -r galaxy-requirements.yml
   ```

2. Create `.vault_pass.txt`.

   The vault passwd is used to encrypt/decrypt the ```secrets.yml``` file per cluster, 
   which will be created in the next step if you do not already have one.
   If you have multiple HPC clusters with their own vault passwd you can have multiple vault password files. 
   The pattern ```.vault_pass.txt*``` is part of ```.gitignore```, so if you use ```.vault_pass.txt.[name-of-the-cluster]```
   for your vault password files they will not accidentally get committed to the repo.
 
   * To generate a new Ansible vault password and put it in ```.vault_pass.txt.[name-of-the-cluster]```, use the following oneliner:
     ```bash
     tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1 > .vault_pass.txt.[name-of-the-cluster]
     ```
   * Or to use an existing Ansible vault password create ```.vault_pass.txt.[name-of-the-cluster]``` and use a text editor to add the password.
   * Make sure the ```.vault_pass.txt.[name-of-the-cluster]``` is private:
     ```bash
     chmod go-rwx .vault_pass.txt.[name-of-the-cluster]
     ```

3. Configure Ansible settings including the vault.

   To create a new virtual cluster you will need ```group_vars``` and an inventory for that HPC cluster:
   
   * See the ```*_hosts.ini``` files for existing clusters for examples to create a new ```[name-of-the-cluster]*_hosts.ini```.
   * Create a ```group_vars/[name-of-the-cluster]/``` folder with a ```vars.yml```.  
     You'll find and example ```vars.yml``` file in ```group_vars/template/```.  
     To generate a new ```secrets.yml``` with new random passwords for the various daemons/components and encrypt this new ```secrets.yml``` file:
     ```bash
     ./generate_secrets.py group_vars/template/secrets.yml group_vars/[name-of-the-cluster]/secrets.yml
     ansible-vault --vault-password-file=.vault_pass.txt.[name-of-the-cluster] encrypt group_vars/[name-of-the-cluster]/secrets.yml
     ```
     The encrypted ```secrets.yml``` can now safely be committed.  
     The ```.vault_pass.txt.[name-of-the-cluster]``` file is excluded from the repo using the ```.vault_pass.txt*``` pattern in ```.gitignore```.
   
   To use use an existing encrypted ```group_vars/[name-of-the-cluster]/secrets.yml```:
   
   * Add a ```.vault_pass.txt.[name-of-the-cluster]``` file to the root folder of this repo and use a text editor to add the vault password to this file.

4. Configure the Certificate Authority (CA).

   We use an SSH public-private key pair to sign the host keys of all the machines in a cluster.
   This way users only need the public key of the CA in their ```~.ssh/known_hosts``` file
   and will not get bothered by messages like this:
   ```
      The authenticity of host '....' can't be established.
      ECDSA key fingerprint is ....
      Are you sure you want to continue connecting (yes/no)?
   ```
   * The filename of the CA private key is specified using the ```ssh_host_signer_ca_private_key``` variable defined in ```group_vars/[name-of-the-cluster] /vars.yml```
   * The filename of the corresponding CA public key must be the same as the one of the private key suffixed with ```.pub```
   * The password required to decrypt the CA private key must be specified using the ```ssh_host_signer_ca_private_key_pass``` variable defined in ```group_vars/[name-of-the-cluster] /secrets.yml```,
     which must be encrypted with ```ansible-vault```.
   * Each user must add the content of the CA public key to their ```~.ssh/known_hosts``` like this:
     ```
     @cert-authority [names of the hosts for which the cert is valid] [content of the CA public key]
     ```
     E.g.:
     ```
     @cert-authority reception*,*talos,*tl-* ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDWNAF....VMZpZ5b9+5GA3O8w== UMCG HPC Development CA
     ```
   * Example to create a new CA key pair with the ```ed25519``` algorithm:
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

   Execute:
   ```
   dd if=/dev/urandom bs=1 count=1024 > roles/slurm-management/files/[name-of-the-cluster] _munge.key
   ansible-vault --vault-password-file=.vault_pass.txt.[name-of-the-cluster] encrypt roles/slurm-management/files/[name-of-the-cluster] _munge.key
   ```
   The encrypted ```[name-of-the-cluster] _munge.key``` can now safely be committed.

7. Running playbooks.
   
   Some examples for the *Talos* development cluster:
   * Configure the dynamic inventory and jumphost for the *Talos* test cluster:
     ```bash
     export AI_INVENTORY='talos_hosts.ini'
     export AI_PROXY='reception'
     export ANSIBLE_VAULT_PASSWORD_FILE='.vault_pass.txt.talos'
     ```
   * Firstly
      * Create local admin accounts, which can then be used to deploy the rest of the playbook.
      * Deploy the signed hosts keys.
     Without local admin accounts we'll need to use either a ```root``` account for direct login or the default user account of the image used to create the VMs.
     In our case the CentOS cloud image comes with a default ```centos``` user.
     ```bash
     export ANSIBLE_HOST_KEY_CHECKING=False
     ansible-playbook -i inventory.py -u centos -l 'jumphost,cluster' local_admin_users.yml
     ansible-playbook -i inventory.py -u root   -l 'docs' local_admin_users.yml
     ansible-playbook -i inventory.py -u [local_admin_account] single_role_playbooks/ssh_host_signer.yml
     export ANSIBLE_HOST_KEY_CHECKING=True
     ```
   * Secondly, deploy the rest of the playbooks/configs:
     * Deploying a complete HPC cluster.
       ```bash
       ansible-playbook -i inventory.py -u [local_admin_account] cluster.yml
       ```
     * Deploying only a specific role - e.g. *slurm-management* - on test cluster *Talos*
       ```bash
       ansible-playbook site.yml -i inventory.py -u [local_admin_account] single_role_playbooks/slurm-management.yml
       ```

8. Verify operation.

   See the end user documentation, that was generated with the ```online_docs``` role for instructions how to submit a job to test the cluster.
