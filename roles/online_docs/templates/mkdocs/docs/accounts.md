#jinja2: trim_blocks:False
# Request an account

## 1. Accounts

### 1.1. Requesting and account

If you have your own funding and would like to make a new separate group, please read 1.2.

Users can be only added to the existing groups. Therefore before requesting the account on the cluster, user must

 - read this documentation, in particular this page, and sections of Generating key pairs
 - have active contract with UMCG
 
Then user must write email to the [helpdesk](../contact/) and

 - CC group owner(s), asking for approval to be added to their group
 - CC department secretary where user is working, asking the end date of user's contract
 - attach *public* key (.pub) of user's public/private keypair (do not send private key)

Both group owner and secretary must then reply directly to helpdesk. Only when we receive all this information, then we can proceed to create an account for you.

### 1.2. Requesting Groups

Every groups is managed by group owner. This person is therefore reponsible for

 - individual user to be added or removed from their group (only group owners decide this)
 - (depends on the system) appointing data managers - individuals from the group, that have elevated rights on data storage
 - behaviour of all the users within the group
 - being only contact person regarding the group decisions, and responding on time when requested
 - financial costs made by the group

To create a new group, simply contact [helpdesk](../contact/) and we will provide you all the information.

## 2. Security and privacy.

### 2.1. Asymmetric key cryptography

We use asymmetric key cryptography to secure accounts. Hence you will get an account name, but no password. Instead of a password we use two digital keys:

 * A private key
 * A public key

The private key can be used to encrypt data (close the lock) and the associated public key can be used to decrypt the data (open the lock).
As the name suggests the public key is not secret; you can share this with everyone, publish it on your website, etc.
Hence your public key cannot be _compromised_, because it's intended to be public.
The private key on the other hand must be private; if it gets stolen your account is compromised and can be abused.
Therefore, [contact us](../contact/) immediately if you ever suspect your private key may have been stolen/copied!

For additional details and background see [WikiPedia: Asymmetric Key Cryptography](http://en.wikipedia.org/wiki/Public-key_cryptography)

When you try to login you use the private key on the client side to encrypt a small piece of data containing a request to login.
The cluster uses your public key on the server side to decrypt the login request: if this was successful the server has verified that you have the private key corresponding to the public key and will let you in.

The benefit of using key pairs as opposed to passwords is that the secret used to login can remain private if you create the key pair yourself and send _**only**_ the public key to the helpdesk.
Hence we do not have a copy/record/backup of your private key on the server side: if you loose the private key, you have to create a new pair and send the new public key to the helpdesk.

### 2.2. Security & Privacy

* When you request an account your email address will be added automatically to a low volume mailinglist, 
  which is used for information regarding the clusters like maintenance announcements.
* When you use the cluster and are logged in:
  * You can secure the content of files/folders, so only you or only members of a specific group can access the content either with read-only or with read-write permissions.  
    This requires setting the desired permissions for files or folders, which is your own responsibility. When you specify wrong permissions, data may be accessible for others.
  * You **cannot** secure the meta data of files/folders.
    * Hence things like file or folder names, time stamps, size, owner, group, etc. can always be seen by anyone who is logged in.
    * This also applies to the name of and resources requested for job script files: all users can see the meta-data for all queued and all running jobs.  
  Therefore **never ever put privacy sensitive data in the meta-data of files nor of folders**!
  * Your full name, email address, group memberships and role in a group (regular user or data manager or group owner) are visible to all other users.

## 3. Generate a public/private key pair

Use the instructions for your operating system:

 * Instructions for [Windows clients](../generate-key-pair-mobaxterm/).
 * Instructions for [macOS clients](../generate-key-pair-openssh/).
 * Instructions for [Linux/Unix clients](../generate-key-pair-openssh/).
