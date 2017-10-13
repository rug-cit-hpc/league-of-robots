# gearshift

This repository contains playbooks and documentation for the UMCG Research HPC cluster Gearshift.

## Git repository
All site specific configuration for the Gearshift cluster will be placed in this git repository.

## protected master.
The master branch is protected; updates will only be pushed to this branch after review.

## Ansible playbooks openstack cluster.
The ansible playbooks in this repository use roles from the [hpc-cloud](https://git.webhosting.rug.nl/HPC/hpc-cloud) repository.
The roles are imported here explicitely by ansible using ansible galaxy.
These roles install various docker images built and hosted by RuG webhosting. They are built from separate git repositories on https://git.webhosting.rug.nl.

## Deployment of openstack.
The steps below describe how to get from machines with a bare ubuntu 16.04 installed to a running openstack installation.

=======
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

# Steps to upgrade openstack cluster.

# Steps to install Compute cluster on top of openstack cluster.
