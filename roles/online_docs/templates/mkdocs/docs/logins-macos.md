#jinja2: trim_blocks:False
# SSH config and login to UI via Jumphost for users on macOS

The following assumes:

 * you have a ```${HOME}/.ssh``` folder with SSH keys (as generated using the instructions for requesting accounts)
 * and that you received a notification with your account name and that your account has been activated
 * and that you are on the machine from which you want to connect to the cluster
 * and that this machine runs macOS _Sierra_ 10.12.2, which includes OpenSSH 7.3p1, or newer.  
   Older versions lack several OpenSSH features we need and are incompatible.

## 1. Configure your SSH client

We've compiled an AppleScript app to configure your SSH client, which will:

 * Create an SSH client config from scratch if none exists.
 * Append to an existing one leaving the config for other servers/machines untouched.
 * Update the config for {{ slurm_cluster_name | capitalize }} if the app is executed again.

#### Quick Install

 * Download the zipped [ssh-client-config-for-{{ slurm_cluster_name }}](../attachments/ssh-client-config-for-{{ slurm_cluster_name }}-macos.zip) AppleScript application.
 * Locate and unzip the downloaded archive, which will result in an ```ssh-client-config-for-{{ slurm_cluster_name }}``` application  
   (optionally with ```.app``` extension depending on your display preferences).
 * Start the ```ssh-client-config-for-{{ slurm_cluster_name }}``` app by double clicking in the ```Finder``` application.
 * Follow the instructions ...

#### Detailed Walkthrough

The ```ssh-client-config-for-{{ slurm_cluster_name }}``` app is a wrapper for an installation script that will be executed in the ```Terminal``` application.
It will configure your SSH client by:

 * Adding an ```Include conf.d/*``` directive to your main ```${HOME}/.ssh/config``` file
 * Adding a ```${HOME}/.ssh/conf.d/{{ slurm_cluster_name }}``` config file for the {{ slurm_cluster_name | capitalize }} specific code.

The ```ssh-client-config-for-{{ slurm_cluster_name }}``` app will guide you through the following steps:

 * Depending on your macOS version, you may receive a pop-up requesting permission to allow access to the ```Terminal``` application:  
   ![Allow access to the Terminal.app](img/ssh-client-config-macos-1.png)  
   Click _Ok_ to allow access to the ```Terminal```.  
   If you want to revoke this permission or change it back to allow later on, you can do so in 
    _System Preferences_ -> _Security & Privacy_ prefs -> _Privacy_ tab -> _Automation_
 * The ```ssh-client-config-for-{{ slurm_cluster_name }}``` app will open the configuration script in the ```Terminal``` application and prompt for your account name.  
   ![Type your account name](img/ssh-client-config-macos-2.png)  
   Type your account name as you received it from the helpdesk and hit the \[ENTER\] key on your keyboard.
 * Your SSH client will now be configured for logins to {{ slurm_cluster_name }} via the corresponding jumphost
   followed by a connection test: the script will try to login using the created config with the account you supplied and the ssh command  
   ```ssh {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}```  
   Make sure you are connected to the internet and hit the \[ENTER\] key on your keyboard to start the connection test.  
   ![Test SSH connection](img/ssh-client-config-macos-3.png)
 * If this was the first time you use your private key for an SSH session, you will get prompted to supply the password for your private key.  
   ![Enter password for your private key](img/ssh-client-config-macos-4.png)  
   Note that this is the password you chose yourself when you created the public private key pair.
   We have no backup whatsoever; If you forgot the password, you will have to start over by creating a new key pair.
 * Done! Hit the \[ENTER\] key on your keyboard to exit the configuration script.  
   ![Done](img/ssh-client-config-macos-5.png)
 * If you made a mistake, you can simply re-run the ```ssh-client-config-for-{{ slurm_cluster_name }}``` app again to update/fix your config.

## Log in to {{ slurm_cluster_name | capitalize }}

#### 2A. Logins on the commandline in a Terminal

Note: If you only need to transfer data and prefer a Graphical User Interface (GUI), you can skip this and scroll down to the section _2B. Transfer data using a GUI_.

If you want to transfer data using the commandline or analyze data on the cluster using jobs:

 * You can now login to the _UI_ named ```{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}``` 
   with the account as specified in your ```${HOME}/.ssh/conf.d/{{ slurm_cluster_name }}``` 
   via the _Jumphost_ named ```{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}{% if slurm_cluster_domain | length %}.{{ slurm_cluster_domain }}{% endif %}``` 
   using the alias ```{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}```. 
   Type the following command in a terminal:

        ssh {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}

 * In order to override the account name specified in your ```${HOME}/.ssh/conf.d/{{ slurm_cluster_name }}``` you can use:

        ssh some_other_account@{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}

 * If you also added the ```Host *+*+*``` code block from the example ```${HOME}/.ssh/config``` you can do tripple hops starting with a _Jumphost_ like this:

        ssh jumphost+intermediate_server+destination_server

 * In case you are on a network where the default port for _SSH_ (22) is blocked by a firewall you can try to setup _SSH_ over port 443, which is the default for HTTPS and almost always allowed, using an alias like this:

        ssh {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}443+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}

##### 2B. Data transfers using a GUI

To the best of our knowledge there is only one file transfer application with a Graphical User Interface that is both free and supports multi-hop SSH via a jumphost by using your OpenSSH config: _ForkLift 2_
You can get _ForkLift 2_ from the [App store](https://apps.apple.com/app/forklift-file-manager-and-ftp-sftp-webdav-amazon-s3-client/id412448059).
Please note that there is a newer version _ForkLift 3_, but this one is not available from the App store neither is it free.
There are other options, but those are either paid apps or they don't support multi-hop SSH using your OpenSSH config. 

To start a session with _ForkLift 2_ use:

 * _Protocol:_ **SFTP**
 * _Name_: **{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}**
 * _Server_: **{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}**
 * _Username_: your account name as you received it from the helpdesk
 * Leave empty and use defaults for all remaining fields.  
   Hence leave the _Password_ field empty too!

## Frequent Asked Questions (FAQs) and trouble shooting

 * Q: Why do I get the error ```Bad configuration option: IgnoreUnknown```?  
   A: Your OpenSSH client is an older one that does not understand the ```IgnoreUnknown``` configuration option.
      You have to comment/disable the  
      ```# Generic stuff: only for macOS clients```  
      section listed at the top of the ```${HOME}/.ssh/conf.d/{{ slurm_cluster_name }}``` config file.
 * Q: Why do I get the error ```muxserver_listen bind(): No such file or directory.```?  
   A: You may have failed to create the ```${HOME}/.ssh/tmp``` folder or the permissions on this folder are wrong.
 * Q: Why do I get the error ```ControlPath too long```?  
   A: The ```ControlPath ~/.ssh/tmp/%C``` line in your ```${HOME}/.ssh/conf.d/{{ slurm_cluster_name }}``` file expands to a path that is too long.
      Change the ```ControlPath``` line in your ```${HOME}/.ssh/conf.d/{{ slurm_cluster_name }}``` file to create a shorter path for the automagically created sockets.
 * Q: Why do I get the error ```ssh_exchange_identification: Connection closed by remote host```?  
   A: Either this server does not exist (anymore). You may have a typo in the name of the server you are trying to connect to.
      Check both the command you typed as well as your ```${HOME}/.ssh/conf.d/{{ slurm_cluster_name }}``` for typos in server names.  
      Or you are using the wrong private key. If your private key is not saved with the default name in the default location,
      check if the correct private key file is specified both for the ```ProxyCommand``` and ```IdentityFile``` directives 
      in your ```${HOME}/.ssh/conf.d/{{ slurm_cluster_name }}```.
 * Q: Why do I get the error ```Permission denied (publickey).```?  
   A: This error can be caused by various configuration issues:
     * Either you are using the wrong account name
     * or you are using the wrong private key file
     * or the permissions on your ```${HOME}/.ssh/``` dir and/or on its content are wrong
     * or your account is misconfigured on our account server.  
   Firstly, check your account name, private key and permissions.  
   Secondly, check if you can login to the _Jumphost_ with a single hop using

              ssh {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}

        * If you can login to the _Jumphost_, but cannot use double hop SSH to login to the _UI_ via the _Jumphost_,
          you may have to add your private key to the SSH agent on you local machine. 
          To check which private key(s) are available to your SSH agent you can list them with on your local computer with:

                  ssh-add -l

        * If you cannot login and get:

                  The agent has no identities.

          then you have to add your private key with the ```ssh-add``` command, which should return output like this:

                  Identity added: /path/to/your/home/dir/.ssh/id_ed25519 (key_comment)

          Your private key should now be listed when you check with ```ssh-add -l```, which should look like this:

                  256 SHA256:j/ZNnUvHYW3U$wgIapHw73SnhojjxlWkAcGZ6qDX6Lw key_comment (ED25519)

     If that did not resolve the issue, then increase the verbosity to debug connection problems (see below).
   
 * Q: Can I increase the verbosity to debug connection problems?  
   A: Yes try adding ```-vvv``` like this:  
   ```ssh -vvv youraccount@{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}```  
   If that does not help to figure out what is wrong please [contact the helpdesk](../contact/) and
     * Do include:
        1. The command you used for your failed login attempt
        2. The output of that failed login attempt with ```-vvv``` debugging enabled
        3. A copy of your ```${HOME}/.ssh/config``` file.
     * **Never ever send us your private key**; It does not help to debug your connection problems, but will render the key useless as it is no longer private.

-----

Back to operating system independent [instructions for logins](../logins/)
