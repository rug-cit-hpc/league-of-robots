# Azure compute

Define host in static inventory
```
    jumphost:
      hosts:
        testmachine:
          azure_flavor: Standard_DS1_v2
          host_networks:
            - name: logs-vnet
```
then in the group vars configure

```
azure_networks:
  - name: "{{ stack_prefix }}_internal_management"
    external: false
    cidr: '10.10.1.0/24'
    type: management
azure_resource_group: 'logs'

```
