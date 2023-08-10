# GRUB ROLE README

Some of the cloud environments are displaying the VM console with a substantial
delay. Therefore in case of corrupted virtual machines, the grub display can be
difficult to catch and edit.
This role sets the timeout of the grub to the predefined time (60 seconds set by
default in defaults/main.yml). This should give ample of time to cache the grub
upon booting.
