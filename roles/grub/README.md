# Tweaking the Grub bootloader

## GRUB_TIMEOUT

Some of the cloud environments are displaying the VM console with a substantial delay.
Therefore, in case of corrupted virtual machines, the grub display can be difficult to catch and edit.

This role sets the Grub timeout to a predefined time (60 seconds default configured in `defaults/main.yml`).
This should give ample of time to catch and edit the boot options upon booting.

## GRUB_DEFAULT

In Rocky 9.3 the system can fail to automatically activate a new kernel update after

```
dnf update kernel
```

The default kernel is usually the one with offset 0 listed by

```
grubby --info=ALL
```

which should list kernels in reverse order by version number: newest kernel first.

Workaround when ```dnf``` fails to update the kernel is

#### 1. Configure GRUB_DEFAULT

This role will set ```GRUB_DEFAULT=saved``` in ```/etc/default/grub```

#### 2. Update grub.cfg

This role will

```
grub2-mkconfig -o /boot/grub2/grub.cfg
```

when ```/etc/default/grub``` was changed;
This should change
```set default="0"```
into
```set default="${saved_entry}"```
in the ```/boot/grub2/grub.cfg``` config file.

#### 3. Manually set another kernel as the default.

You can check the current default kernel with:

```grubby --default-kernel```

List all available kernels with:

```
grubby --info=ALL
```

If that is not the one that should be used, then use ```grubby --set-default``` to change the default; E.g.
```
[root]# grubby --set-default /boot/vmlinuz-5.14.0-362.13.1.el9_3.x86_64
The default is /boot/loader/entries/e2b217c330724d869b4f2686057579d6-5.14.0-362.13.1.el9_3.x86_64.conf with index 2 and kernel /boot/vmlinuz-5.14.0-362.13.1.el9_3.x86_64
```
The ```saved_entry``` option reported by ```grub2-editenv list``` should now list that new default kernel; E.g.
```
[root]# grub2-editenv list
saved_entry=e2b217c330724d869b4f2686057579d6-5.14.0-362.13.1.el9_3.x86_64
```

#### 4. Reboot server

Reboot the machine and confirm the machine booted the correct kernel:

```
[root]# shutdown -h now
# Log back in after reboot and check active kernel version
[admin]# uname -a
```
