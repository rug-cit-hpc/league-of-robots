## Role Variables

See `defaults/main.yml` for variables and their defaults.

**It is _very_ important that you quote the 'yes' or 'no' values. Failure to do so may lock you out of your server.**
Hence these values are not "YAML" booleans and you cannot use `true` or `false`.
These values must end up in the sshd.conf as `yes` or `no` and therefore must be treated as strings in YAML.

    basic_security_ssh_allowed_users: []
    # - anna
    # - henk
    # - bobo

A list of users allowed to connect to the host over SSH.  If no user is defined in the list, the task will be skipped.

    basic_security_ssh_allowed_groups: []
    # - admins
    # - sysops

A list of groups allowed to connect to the host over SSH.  If no group is defined in the list, the task will be skipped.

    basic_security_sshd_state: started

The state of the SSH daemon. Typically this should remain `started`.

    basic_security_ssh_restart_handler_state: restarted

The state of the `restart ssh` handler. Typically this should remain `restarted`.

    basic_security_sudoers_passwordless: []
    basic_security_sudoers_passworded: []

A list of users who should be added to the sudoers file so they can run any command as root (via `sudo`) either without a password or requiring a password for each command, respectively.

    basic_security_autoupdate_enabled: true

Whether to install/enable `yum-cron` (RedHat-based systems).
System restarts will not happen automatically in any case, and automatic upgrades are no excuse for sloppy patch and package management, but automatic updates can be helpful as yet another security measure.

    basic_security_fail2ban_enabled: true

Whether to install/enable `fail2ban`. You might not want to use fail2ban if you're already using some other service for login and intrusion detection (e.g. [ConfigServer](http://configserver.com/cp/csf.html)).

    basic_security_fail2ban_custom_configuration_template: "jail.local.j2"

The name of the template file used to generate `fail2ban`'s configuration.