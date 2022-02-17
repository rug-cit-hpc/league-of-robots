#jinja2: trim_blocks:False
# Data transfers - How to move data to / from the dedicated data transfer server

Firstly and independent of technical options: make sure you are familiar with the _code of conduct_ / _terms and conditions_ / _license_ or whatever it is called
and that you are allowed to upload / download a data set!
When in doubt contact your supervisor / principal investigator and the group / institute that created the data set.

The {{ slurm_cluster_name | capitalize }} HPC cluster features a dedicated data transfer server _{{ dt_server_address }}_,
which can be used to exchange data with external collaborators,
that do not have a _regular_ cluster account with full shell access.
This dedicated data transfer server can only be used with _guest_ accounts, which can transfer data using

 * SFTP protocol on port 22
 * rsync protocol on port 443

![data-transfers](img/dedicated-dt-server.svg)

 * **R1**: Cluster user uses their _regular_ account with SSH key forwarding enabled to login
    to user interface server _{{ groups['user_interface'] | first }}_
    via jumphost _{{ groups['jumphost'] | first }}_
 * **R2**: Cluster user uses _guest_ account to transfer data from _{{ groups['user_interface'] | first }}_
    to _{{ dt_server_address }}_ or vice versa.
 * **G1**: External collaborator uses _guest_ account to transfer data to/from
    _{{ dt_server_address }}_.

## Arranging a guest account for data transfers

#### Procedure for cluster users who already have a regular account

 * Ask your external collaborator(s) to create a public-private key pair using these instructions
   for [Windows clients](../generate-key-pair-mobaxterm/) or for [macOS/Linux/Unix clients](../generate-key-pair-openssh/).
 * Ask your external collaborator(s) to send **only** their **public** key to our helpdesk.
 * [Contact our helpdesk](../contact/) and request a temporary _guest_ account for you and your external collaborator.
   * You do not need to include your own public key(s) as we already have those.
   * Motivate your request and specify
      * the name and affiliation of your collaborator, 
      * the name of the project for which data will be exchanged and 
      * for how long you will need the _guest_ account.
 * We will assign a temporary _guest_ account for your data transfer and link both your public key(s) as well as the public key(s) of your collaborator(s) to the same _guest_ account.
 * You can now transfer data from/to {{ dt_server_address }} using the _guest_ account and your _private key_.

#### Procedure for external collaborators

 * Your contact (with a _regular_ cluster account) will request a _guest_ account from our helpdesk.
 * Your contact will ask you to create a public-private key pair using these instructions
   for [Windows clients](../generate-key-pair-mobaxterm/) or for [macOS/Linux/Unix clients](../generate-key-pair-openssh/).
 * You will send **only** your **public** key to our [helpdesk](../contact/).
 * We will link your public key to a _guest_ account and notify you when the _guest_ account is ready.
 * You can now transfer data from/to {{ dt_server_address }} using the _guest_ account and your _private key_.

## Using the guest account to transfer data to/from _{{ dt_server_address }}_

 * [Instructions for cluster users](../dedicated-dt-server-cluster-users/)
 * [Instructions for external collaborators](../dedicated-dt-server-external-collaborators/)
