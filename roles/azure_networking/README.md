# Azure networking

[See compute readme](../azure_computing/README.md)

## Security groups

Note about security groups of Azure
 - they work differently than Openstack
 - security groups can be stacked, but need to be correctly weighted in order to work
 - therefore decision was done that the following structure is used
    - 1xx are for publicly exposed ports
    - 2xx for network cidr limited port access
    - 3xx are for everything else: storage or vlans ports

