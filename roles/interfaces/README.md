# Network interfaces

### Commands and config files for Debugging

```
#
# Track what udev does
#
sudo udevadm test /sys/class/net/[current_interface_name]

#
# Order of naming schemes used by udev
#
/usr/lib/systemd/network/99-default.link
#
# Slot-based naming scheme has priority over path-based naming scheme,
# but is not stable: was introduced later and the removed again for virtual network interfaces,
# because it can cause naming conflicts.
# To rename an interface based on slot into one based on path, we must:
#  * 
#
# Create override in /etc/systemd/network/99-default.link
#
mkdir -m 755 /etc/systemd/network
cp /usr/lib/systemd/network/99-default.link /etc/systemd/network/99-default.link
#
# and change:
#
#NamePolicy=keep kernel database onboard slot path
#AlternativeNamesPolicy=database onboard slot path
NamePolicy=kernel database onboard path slot
AlternativeNamesPolicy=database onboard path slot
#
# Also delete /etc/udev/rules.d/70-persistent-net.rules, which will contain the outdated info
#
rm /etc/udev/rules.d/70-persistent-net.rules
#
# reboot
#
shutdown -r now
#
# When the renaming worked you can no longer login:
# Need to update the name of the internal network interface in /etc/sysconfig/iptables-init.bash too!
#

#
# Note: You have to update-initramfs -u for these changes to take effect during early boot.
# This copies the /etc/systemd/network/99-default.link file you created into the initramfs 
# to be around at early system boot when udev needs it.
#
# Make backup
#
cp /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r)-$(date +%Y-%m-%d-%H%M%S).img
#
# Regenerate initramfs
#
dracut -f /boot/initramfs-$(uname -r).img $(uname -r)
#
# lsinitrd show this does not work, the override file is ignored.
#
lsinitrd /boot/initramfs-5.14.0-427.31.1.el9_4.x86_64.img | fgrep 99-default.link
-rw-r--r--   1 root     root          763 Apr  8 01:06 usr/lib/systemd/network/99-default.link




#
# Change device name for first network connection: 'ens3' in this case.
# See https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html-single/configuring_and_managing_networking/index#configuring-user-defined-network-interface-names-by-using-udev-rules_consistent-network-interface-device-naming
#
nmcli connection modify 'System ens3' connection.interface-name ""
nmcli connection modify 'System ens3' match.interface-name "enp0s3 ens3"
shutdown -r now
nmcli connection modify 'System ens3' match.interface-name "enp0s3"
nmcli connection up 'System ens3'
```
