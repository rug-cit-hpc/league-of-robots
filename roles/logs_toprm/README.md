# Logs to prm role

See also

 - [Logs Clients Readme](../logs_toprm/README.md)
 - [Logs Servers Readme](../logs_server/README.md)

This role is running on the machine that has access to the `logs_server` machines.
It deploys the script that is executed with cron.
The script collects the packaged logs from the servers and stores them in the
permanent storage location.

## Deployment procedure

Order
- run this script on the chaperones
- then deploy the ansible-pipelines on the chaperon to define the crons jobs that
  trigger this script

![Overview](overview.png)

## Debugging

Checking logs on the chaperone machine

   `root@chaperoneXX ~ # journalctl -t logstoprm`

