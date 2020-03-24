#jinja2: trim_blocks:False
# SSH config and login to UI via Jumphost for users on macOS

The following assumes:

 * you have a ```${HOME}/.ssh``` folder with SSH keys (as generated using the instructions for requesting accounts)
 * and that you received a notification with your account name and that your account has been activated
 * and that you are on the machine from which you want to connect to the cluster.

##### 1. Configure your SSH client

 * We've compiled a script that will configure your SSH client. This script is designed such that it
    * Creates an SSH client config from scratch if none exists.
    * Appends to an existing one leaving the config for other servers/machines untouched.  
      This is accomplished by only adding an ```Include conf.d/*``` directive to your main ```${HOME}/.ssh/config```  
      All the {{ slurm_cluster_name | capitalize }} specific code is added to a ```${HOME}/.ssh/conf.d/{{ slurm_cluster_name }}``` config file.
    * Updates the config for {{ slurm_cluster_name | capitalize }} if the script is executed again.
 * Download the zipped [ssh-client-config-for-{{ slurm_cluster_name }}.app](../attachments/ssh-client-config-for-{{ slurm_cluster_name }}.zip) script.
 * Locate and unzip the downloaded archive, which will result in an ```ssh-client-config-for-{{ slurm_cluster_name }}.app```
 * The ssh-client-config-for-{{ slurm_cluster_name }}.app is a wrapper for the configuration script and can be executed by double clicking it in the ```Finder```.
 * The app will open the script in the ```Terminal``` application and prompt for your account name.  
   Type your account name and hit the [ENTER] key on your keyboard.
 * Done!
 * If you made a mistake, you can simply re-run the script again to update/fix your config.

##### 3. Login via Jumphost

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

#### Frequent Asked Questions (FAQs) and trouble shooting

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

