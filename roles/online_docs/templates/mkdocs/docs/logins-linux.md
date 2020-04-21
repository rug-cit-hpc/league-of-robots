#jinja2: trim_blocks:False
# SSH config and login to UI via Jumphost for users on Linux/Unix

The following assumes:

 * you have a ```${HOME}/.ssh``` folder with SSH keys (as generated using the instructions for requesting accounts)
 * and that you received a notification that your account has been activated
 * and that you are on the machine from which you want to connect to the cluster.
 * and that this machine has **OpenSSH 7.3p1 or newer**.  
   Older versions lack several OpenSSH features we need and are incompatible.

##### 1. Create required directories and files if they do not exist yet

```
mkdir -p -m 700 "${HOME}/.ssh/"
mkdir -p -m 700 "${HOME}/.ssh/tmp/"
mkdir -p -m 700 "${HOME}/.ssh/conf.d/"
touch "${HOME}/.ssh/known_hosts"
touch "${HOME}/.ssh/conf.d/{{ slurm_cluster_name }}"
chmod -R go-rwx "${HOME}/.ssh"
```

##### 2. Configure Certificate Authority's (CA) public key to verify the identity of cluster servers

Append the public key from the Certificate Authority we used to sign the host keys of our machines to your ```${HOME}/.ssh/known_hosts``` file.  
Open a terminal and copy paste the following commands:
```
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
```

##### 3. Add include directive to main SSH config file

Use a text editor to add the following line
```
Include conf.d/*
```
to the beginning of your ```${HOME}/.ssh/config``` file.
Important: this _Include_ directive must precede any lines containing _Host_ or _Match_ directives,
otherwise the _Include_ will only apply to a specific set of hosts.

##### 4. Create SSH config file for {{ slurm_cluster_name | capitalize }}

Now we need to configure transparent multi-hop SSH for {{ slurm_cluster_name | capitalize }}.
Open your ```${HOME}/.ssh/conf.d/{{ slurm_cluster_name }}``` file in a text editor and add the lines below 
replacing all occurrences of _**youraccount**_ with the account name you received from the helpdesk.
```
#
# Generic stuff: only for macOS clients.
#
IgnoreUnknown UseKeychain
    UseKeychain yes
IgnoreUnknown AddKeysToAgent
    AddKeysToAgent yes
#
# Host settings.
#
Host reception*
    #
    # Default account name when not specified explicitly.
    #
    User youraccount
    #
    # Prevent timeouts
    #
    ServerAliveInterval 60
    ServerAliveCountMax 5
    #
    # We use public-private key pairs for authentication.
    # Do not use password based authentication as fallback,
    # which may be confusing and won't work anyway.
    #
    PasswordAuthentication No
    #
    # Multiplex connections to
    #   * reduce lag when logging in to the same host in a second terminal
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
# Expand short jumphost names to FQDN or IP address.
#{% if public_ip_addresses is defined and public_ip_addresses | length %}{% for jumphost in groups['jumphost'] %}
Host {{ jumphost | regex_replace('^' + ai_jumphost + '\\+','') }}
    HostName {{ public_ip_addresses[jumphost | regex_replace('^' + ai_jumphost + '\\+','')] }}{% endfor %}{% else %}
Host {% for jumphost in groups['jumphost'] %}{{ jumphost | regex_replace('^' + ai_jumphost + '\\+','') }} {% endfor %}{% if slurm_cluster_domain | length %}!*.{{ slurm_cluster_domain }}{% endif %}
    HostName %h{% if slurm_cluster_domain | length %}.{{ slurm_cluster_domain }}{% endif %}{% endif %}
#
# Universal jumphost settings for triple-hop SSH.
#
Host *+*+*
    ProxyCommand ssh -x -q $(echo %h | sed 's/+[^+]*$//') -W $(echo %h | sed 's/^[^+]*+[^+]*+//'):%p
#
# Double-hop SSH settings to connect via Jumphosts{% if slurm_cluster_domain | length %}{{ slurm_cluster_domain }}{% endif %}.
#
Host {% for jumphost in groups['jumphost'] %}{{ jumphost | regex_replace('^' + ai_jumphost + '\\+','')}}+* {% endfor %}{% raw %}{% endraw %}
    ProxyCommand ssh -x -q youraccount@\$(echo %h | sed 's/+[^+]*$//'){% if slurm_cluster_domain | length %}.{{ slurm_cluster_domain }}{% endif %} -W \$(echo %h | sed 's/^[^+]*+//'):%p
#
# Sometimes port 22 for the SSH protocol is blocked by firewalls; in that case you can try to use SSH on port 443 as fall-back.
# Do not use port 443 by default for SSH as it officially assigned to HTTPS traffic and some firewalls will cause problems when trying to route SSH over port 443.
#
Host {% for jumphost in groups['jumphost'] %}{{ jumphost | regex_replace('^' + ai_jumphost + '\\+','')}}443+* {% endfor %}{% raw %}{% endraw %}
    ProxyCommand ssh -x -q youraccount@\$(echo %h | sed 's/443+[^+]*$//'){% if slurm_cluster_domain | length %}.{{ slurm_cluster_domain }}{% endif %} -W \$(echo %h | sed 's/^[^+]*+//'):%p -p 443
```

##### 5. Login via Jumphost

 * You can now login to the _UI_ named ```{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}``` with the account as specified in your ```${HOME}/.ssh/config``` 
   via the _Jumphost_ named ```{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}{% if slurm_cluster_domain | length %}.{{ slurm_cluster_domain }}{% endif %}``` 
   using the alias ```{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}```. 
   Type the following command in a terminal:

        ssh {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}

 * In order to override the account name specified in your ```${HOME}/.ssh/config``` you can use:

        ssh some_other_account@{{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}

 * If you also added the ```Host *+*+*``` code block from the example ```${HOME}/.ssh/config``` you can do tripple hops starting with a _Jumphost_ like this:

        ssh jumphost+intermediate_server+destination_server

 * In case you are on a network where the default port for _SSH_ (22) is blocked by a firewall you can try to setup _SSH_ over port 443, which is the default for HTTPS and almost always allowed, using an alias like this:

        ssh {{ groups['jumphost'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}443+{{ groups['user-interface'] | first | regex_replace('^' + ai_jumphost + '\\+','') }}

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

