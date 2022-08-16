# Ansible Role: iptables

This role configures host-based firewalls using iptables: both for IPv4 (`iptables`) and for IPv6 (`ip6tables`).
After deployment, `iptables` and `ip6tables` init services will be available on the server.
Use `service ip[6]tables [start|stop|restart|status]` to control the firewall.

## Role Variables

See `defaults/main.yml`. All role variables are prefixed with` iptables_`

## Logic

#### IPv4

We first create a list of IPv4 addresses used by a host and determine if these addresses are publicly exposed.
This role considers an IP _publicly exposed_ when it is

 * either a _public_ IP address
 * or a private address and traffic from a _floating_, _public_ IP is routed to this private IP. 

Next we fetch the network interface names for all _publicly exposed_ IP addresses:

 * **internal** interfaces = those who do **not** use a _publicly exposed_ IP address.
 * **external** interfaces = those who do use a _publicly exposed_ IP address.

Finally we configure the IPv4 firewall to:

 * **internal** interfaces (including loopback interfaces): Allow anything.
 * **external** interfaces:
   * Disable anything by default
   * Allow specific services on specific ports to/from specific subnets.
   * A subnet is specified with mask as [0-9].[0-9].[0-9].[0-9]/[0-9] and may contain one or more IP addresses.
     E.g. 111.111.111.111/32 is the single machine 111.111.111.111
     and 111.111.111.0/24 is the range from 111.111.111.1 up to and including 111.111.111.254.
   * Defaults for supported services for which this role can configure the firewall are listed in `defaults/main.yml`.

#### IPv6

We do not use IPv6 and configure the IPv6 firewall to:
 * Allow anything over the loopback interface.
 * Disable anything else over any other interface both internal and external.
