#jinja2: trim_blocks:False
# How to start a session and connect to a User Interface server

## User Interface (UI) and jumphost servers

To submit jobs, check their status, test scripts, etc. you need to login on a _**User Interface (UI)**_ server using SSH.
Each cluster has its own _**UI**_ and the one for the {{ slurm_cluster_name | capitalize }} HPC cluster is named _**{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}**_.
The UI and various other servers that make up the cluster receive updates during scheduled maintenance, 
but as this disrupts the processing of jobs scheduled maintenance is planned only ~twice a year.

Not applying updates for several months could become a serious security risk for machines that are directly accessible via the internet.
Therefore the servers of the {{ slurm_cluster_name | capitalize }} cluster are on an internal network that is not directly accessible from the internet.
In order to access the UI you will need to hop via a _**jumphost**_, 
which is a security hardened machine that is not in any way involved in the processing of jobs nor in storing data and does receive daily (security) updates.
In order to apply/activate security patches the jumphost may be temporarily unavailable, which means you cannot login to the _UI_ and hence cannot manage jobs nor create new ones, 
but existing jobs (running or queued) won't be affected and the cluster will continue to process those.
The _**jumphost**_ for the {{ slurm_cluster_name | capitalize }} HPC cluster is named _**{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}{% if slurm_cluster_domain | length %}.{{ slurm_cluster_domain }}{% endif %}**_

## Request an account

First make sure you have an account. If you are new, please [follow these instructions to request an account](../accounts/).

## SSH config and login to UI via jumphost for users on macOS, Linux or Unix

The following assumes:

* you have a ```${HOME}/.ssh``` folder with SSH keys (as generated using the instructions for requesting accounts)
* and that you received a notification that your account has been activated
* and that you are on the machine from which you want to connect to the cluster.

##### 1. Configure Certificate Authority's (CA) public key to verify the identity of cluster servers

 * Create a ```${HOME}/.ssh/known_hosts``` file if it does not exist yet
 * Append the public key from the Certificate Authority we used to sign the host keys of our machines to your ```${HOME}/.ssh/known_hosts``` file.  
   Open a terminal and type the following commands:

        #
        # Create new known_hosts file and append the UMCG HPC CA's public key.
        #
        printf '%s\n' \
            "@cert-authority {% for jumphost in groups['jumphost'] %}{{ jumphost | regex_replace('^' + ai_jumphost + '\\+','')}}*,{% if public_ip_addresses is defined and public_ip_addresses[jumphost] | length %}{{ public_ip_addresses[jumphost] }},{% endif %}{% endfor %}{% for adminhost in groups['administration'] %}*{{ adminhost | regex_replace('^' + ai_jumphost + '\\+','')}},{% endfor %}*{{ stack_prefix }}-* {{ lookup('file', ssh_host_signer_ca_private_key+'.pub') }} for {{ slurm_cluster_name }}" \
            > "${HOME}/.ssh/known_hosts.new"
        if [[ -e "${HOME}/.ssh/known_hosts" ]]; then
            #
            # When user already had a known_hosts file, then 
            # remove a potentially outdated CA public key for the same machines based on the slurm_cluster_name: {{ slurm_cluster_name }}
            # and append all other lines to the new known_hosts file. 
            #
            sed '/^\@cert-authority .* for {{ slurm_cluster_name }}$/d' "${HOME}/.ssh/known_hosts" \
                | sort >> "${HOME}/.ssh/known_hosts.new"
        fi
        #
        # Make new known_hosts file the default.
        #
        mv "${HOME}/.ssh/known_hosts.new" "${HOME}/.ssh/known_hosts"

##### 2. Configure transparent multi-hop SSH for logins via the jumphost

 * Create a ```${HOME}/.ssh/tmp``` folder. Open a terminal and type the following command:

        mkdir -p -m 700 "${HOME}/.ssh/tmp"

 * Create a ```${HOME}/.ssh/config``` file if it does not exist.
 * Add to your ```${HOME}/.ssh/config``` something like the following:

        #
        # Generic stuff: only for macOS clients.
        #
        IgnoreUnknown UseKeychain
            UseKeychain yes
        IgnoreUnknown AddKeysToAgent
            AddKeysToAgent yes
        #
        # Generic stuff: prevent timeouts 
        #
        Host *
            ServerAliveInterval 60
            ServerAliveCountMax 5
        #
        # Generic stuff: connection multiplexing
        #
        # Multiplex connections to
        #   * reduce lag when logging into the same host in a second shell
        #   * reduce the amount of connections that are made to prevent excessive DNS lookups
        #     and to prevent getting blocked by a firewall, because it thinks we are executing a DoS attack.
        #
        # Name/location of sockets for connection multiplexing are configured using the ControlPath directive.
        # In the ControlPath directive %C expands to a hashed value of %l_%h_%p_%r, where:
        #    %l = local hostname
        #    %h = remote hostname
        #    %p = remote port
        #    %r = remote username
        # This makes sure that the ControlPath is
        #   * a unique socket that is local to machine on which the sessions are created,
        #     which means it works with home dirs from a shared network file system.
        #     (as sockets cannot be shared by servers.)
        #   * not getting to long as the hash has a fixed size not matter how long %l_%h_%p_%r was.
        #
        ControlMaster auto
        ControlPath ~/.ssh/tmp/%C
        ControlPersist 1m
        #
        ##
        ### HPC cluster hosts
        ##
        #
        #  A. With DNS entry.
        #{% if public_ip_addresses is defined and public_ip_addresses | length %}{% for jumphost in groups['jumphost'] %}
        Host {{ jumphost | regex_replace('^' + ai_jumphost + '\\+','') }}
            HostName {{ public_ip_addresses[jumphost | regex_replace('^' + ai_jumphost + '\\+','')] }}
            User youraccount{% endfor %}{% else %}
        Host {% for jumphost in groups['jumphost'] %}{{ jumphost | regex_replace('^' + ai_jumphost + '\\+','') }} {% endfor %}{% if slurm_cluster_domain | length %}!*.{{ slurm_cluster_domain }}{% endif %}
            HostName %h{% if slurm_cluster_domain | length %}.{{ slurm_cluster_domain }}{% endif %}
            User youraccount{% endif %}
        #
        #  B. Without DNS entry.
        #     These can only be resolved when already logged in on one of the machines with DNS entry listed above.
        #
        Host {% for adminhost in groups['administration'] %}*{{ adminhost | regex_replace('^' + ai_jumphost + '\\+','') }} {% endfor %}*{{ stack_prefix }}-*
            User youraccount
        #
        ##
        ### Jumphost settings for multi-hop SSH.
        ##
        # 
        # The syntax in all the ProxyCommand rules below assumes your private key is in the default location.
        # The default location is:
        #     ${HOME}/.ssh/id_ed25519
        # for keys generated with the ed25519 algorithm.
        # In case your private key file is NOT in the default location you must:
        #  1. Specify the path to your private key file on the command line when logging in with SSH.
        #     For example:
        #         $> ssh -i ${HOME}/.ssh/some_other_private_key_file youraccount@jumphost_server+destination_server
        #  2. Add the path to your private key file in the ProxyCommand rules below.
        #     For example:
        #         Host jumphost_server+*
        #             PasswordAuthentication No
        #             ProxyCommand ssh -X -q -i ${HOME}/.ssh/some_other_private_key_file youraccount@$(echo %h | sed 's/+[^+]*$//').some.sub.domain -W $(echo %h | sed 's/^[^+]*+//'):%p
        #
        # Universal jumphost settings for triple-hop SSH.
        #
        Host *+*+*
            ProxyCommand ssh -X -q $(echo %h | sed 's/+[^+]*$//') -W $(echo %h | sed 's/^[^+]*+[^+]*+//'):%p
        #
        # Double-hop proxy settings for jumphosts{% if slurm_cluster_domain | length %} in {{ slurm_cluster_domain }} domain{% endif %}.
        #
        Host {% for jumphost in groups['jumphost'] %}{{ jumphost | regex_replace('^' + ai_jumphost + '\\+','')}}+* {% endfor %}{% raw %}{% endraw %}
            PasswordAuthentication No
            ProxyCommand ssh -X -q youraccount@$(echo %h | sed 's/+[^+]*$//'){% if slurm_cluster_domain | length %}.{{ slurm_cluster_domain }}{% endif %} -W $(echo %h | sed 's/^[^+]*+//'):%p
        #
        # Sometimes port 22 for the SSH protocol is blocked by firewalls; in that case you can try to use SSH on port 80 as fall-back.
        # Do not use port 80 by default for SSH as it officially assigned to HTTP traffic and some firewalls will cause problems when trying to route SSH over port 80.
        #
        Host {% for jumphost in groups['jumphost'] %}{{ jumphost | regex_replace('^' + ai_jumphost + '\\+','')}}80+* {% endfor %}{% raw %}{% endraw %}
            PasswordAuthentication No
            ProxyCommand ssh -X -q youraccount@$(echo %h | sed 's/+[^+]*$//'){% if slurm_cluster_domain | length %}.{{ slurm_cluster_domain }}{% endif %} -W $(echo %h | sed 's/^[^+]*+//'):%p -p 80
    Replace all occurences of _**youraccount**_ with the account name you received from the helpdesk.  
    If you are **not on a Mac or on a very old Mac** your OpenSSH client may not understand the ```IgnoreUnknown``` configuration option and you may have to comment/disable the  
    ```# Generic stuff: only for macOS clients``` section listed at the top of the example ```${HOME}/.ssh/config```.

 * Make sure you are the only one who can access your ```${HOME}/.ssh``` folder. Type the following command in a terminal:

        chmod -R go-rwx "${HOME}/.ssh"

##### 3. Login via jumphost

 * You can now login to the _UI_ named ```{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}``` with the account as specified in your ```${HOME}/.ssh/config```. 
   via the _jumphost_ named ```{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}{% if slurm_cluster_domain | length %}.{{ slurm_cluster_domain }}{% endif %}``` 
   using the alias ```{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}```. 
   Type the following command in a terminal:

        ssh {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}

 * In order to override the account name specified in your ```${HOME}/.ssh/config``` you can use:

        ssh some_other_account@{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}

 * If you also added the ```Host *+*+*``` code block from the example ```${HOME}/.ssh/config``` you can do tripple hops starting with a jumphost like this:

        ssh jumphost+intermediate_server+destination_server

 * In case you are on a network where the default port for _SSH_ (22) is blocked by a firewall you can try to setup _SSH_ over port 80, which is the default for HTTP and almost always allowed, using an alias like this:

        ssh {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}80+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}

#### Frequent Asked Questions (FAQs) and trouble shooting

* Q: Why do I get the error ```muxserver_listen bind(): No such file or directory.```?  
  A: You may have failed to create the ```${HOME}/.ssh/tmp``` folder or the permissions on this folder are wrong.
* Q: Why do I get the error ```ControlPath too long```?  
  A: The ```ControlPath ~/.ssh/tmp/%C``` line in your ```${HOME}/.ssh/config``` file expands to a path that is too long.
     Change the ```ControlPath``` line in your ```${HOME}/.ssh/config``` file to create a shorter path for the automagically created sockets.
* Q: Why do I get the error ```ssh_exchange_identification: Connection closed by remote host```?  
  A: Either this server does not exist (anymore). You may have a typo in the name of the server you are trying to connect to.
     Check both the command you typed as well as your ```${HOME}/.ssh/config``` for typos in server names.  
     Or you are using the wrong private key. If your private key is not saved with the default name in the default location,
     check if you specified the correct private file both for the ```ProxyCommand``` in your ```${HOME}/.ssh/config``` 
     as well as with the ```-i``` option for the ```ssh``` command.
* Q: Why do I get the error ```Permission denied (publickey).```?  
  A: This error can be caused by various configuration issues:  
      * Either you are using the wrong account name  
      * or you are using the wrong private key file  
      * or the permissions on your ```${HOME}/.ssh/``` dir and/or on its content are wrong  
      * or your account is misconfigured on our account server.  
     Firstly, check your account name, private key and permissions.  
     Secondly, check if you can login to the jumphost with a single hop  

        ssh {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}

     If you can login to the jumphost, but cannot use double hop SSH to login to the UI via the jumphost,
     you may have to add your private key to the SSH agent on you local machine. 
     To check which private key(s) are available to your SSH agent you can list them with on your local computer with:

        ssh-add -l

     If you get:

        The agent has no identities.

     then you have to add your private key with the ```ssh-add``` command, which should return output like this:

        Identity added: /path/to/your/home/dir/.ssh/id_ed25519 (key_comment)

     Your private key should now be listed when you check with ```ssh-add -l```, which should look like this:

        256 SHA256:j/ZNnUvHYW3U$wgIapHw73SnhojjxlWkAcGZ6qDX6Lw key_comment (ED25519)

     If that did not resolve the issue, then increase the verbosity to debug connection problems (see below).
* Q: Can I increase the verbosity to debug connection problems?  
  A: Yes try adding ```-vvv``` like this:  
     ```ssh -vvv youraccount@{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}```  
     If that does not help to figure out what is wrong please [contact the helpdesk](../contact/) and include:  
      1. The command you used for your failed login attempt  
      2. The output of that failed login attempt with ```-vvv``` debugging enabled  
      3. A copy of your ```${HOME}/.ssh/config``` file.  
     **Never ever send us your private key**; It does not help to debug your connection problems, but will render the key useless as it is no longer private.

## SSH config and login to UI via jumphost for users on Windows

##### 1. Install PuTTY and Pageant

 * Download and install _**[PuTTY](http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html)**_  
   If you downloaded the standalone _PuTTY_ app as opposed to the whole _PuTTY_ suite, then make sure to also download the key manager _Pageant_.

##### 2. Load your private key in Pageant

 * Start _**Pageant**_
 * Load your private key into _**Pageant**_

##### 3. Configure PuTTY for transparent multi-hop SSH for logins via the jumphost

 * Start _**Putty**_
 * Go to _**Connection**_ -> _**SSH**_ -> _**Auth**_ and select _**Allow agent forwarding**_
 * Go to _**Connection**_ -> _**SSH**_ -> _**Auth**_ -> _**Private key file for authentication**_ and add your private key.
 * Go to _**Connection**_ -> _**Data**_ and fill in your accountname in the _**auto-login username**_ option

##### 4. Login via jumphost

You can now connect to for example UI {{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }} 
via jumphost {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }} using a double hop like this:

 * In a _**Putty**_ configuration window supply the _hostname_ _**{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}**_, your **accountname** and
 * Click the _**Connect**_ button...
 * Once the connection is established type the following command in a terminal:

        ssh youraccount@{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}

#### 5. Connecting to sandbox {{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }} via jumphost {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }} using MobaXterm.

MobaXterm for windows is a great toolbox for remote computing. has It has a user friendly interface for supporting drag and drop file transfers directly into the sandbox, 
but also a UNIX terminal functionality to support basic commands (bash, grep, awk, sed, rsync, etc etc ) or SFTP support.
MobaXterm makes it easy to connect to _**{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}**_ via a jumphost. 

To set up a connection to {{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}  in MobaXterm you do the following:

 * Download and install [MobaXterm](https://mobaxterm.mobatek.net/download.html)
 * create a new SSH, session
 * put _**{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}**_ in the "remote host" field
 * open the "advanced SSH settings" section and import your private key.
 * open the "Network settings" section
 * check "Connect through SSH gateway \(jump host\)"
{% if public_ip_addresses is defined and public_ip_addresses | length %}{% for jumphost in groups['jumphost'] %}
* fill-in _**{{ public_ip_addresses[jumphost] }}**_ in order to connect to _**{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}**_
{% endfor %}{% else %}
 * fill-in _**{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}**_ in order to connect to _**{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}**_
{% endif %}
 * This will silently create an encrypted SSH tunnel to _**{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}**_ and then use this tunnel in order to connect to _**{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}**_.
 * Use the 'browser or sftp' tab for the more windows drag and drop interface, or the 'Shell' tab to make se of a terminal interface.
 



Fore more advanced information about MobaXterm please have a look at [these instructions to automate such a double hop on Windows](https://mobaxterm.mobatek.net/documentation.html#2_1_5)
