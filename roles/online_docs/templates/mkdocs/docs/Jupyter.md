#jinja2: trim_blocks:True
# Jupyter - How to use Jupyter in your local web browser to crunch data on {{ slurm_cluster_name | capitalize }}

## Introduction

The [_Jupyter project_](https://jupyter.org/) provides a collection of tools for interactive computing across various programming languages.

_JupyterLab_ is one of the project's most well known products and the latest web-based, interactive development environment for _Jupyter notebooks_, code, and data.
The documentation below explains how to create and connect to a _JupyterLab_ session on {{ slurm_cluster_name | capitalize }}.
For documentation on how to use _JupyterLab_ itself see [https://jupyterlab.readthedocs.io](https://jupyterlab.readthedocs.io)

## How to use JupyterLab

![How to use Jupyter](img/jupyter.svg)

You can use _Jupyter_ by:

 * Running a ```jupyter lab``` session on {{ slurm_cluster_name | capitalize }}.
 * Creating an SSH tunnel from your local computer to the {{ slurm_cluster_name | capitalize }} compute node where that _Jupyter_ session is running.
 * Starting a web browser on your local computer to work with the _Jupyter_ session via the SSH tunnel.

This setup will ensure:

 * The original data sets can stay on {{ slurm_cluster_name | capitalize }}
 * Communication between your local client computer and {{ slurm_cluster_name | capitalize }} is encrypted via the SSH protocol.
 * Code to crunch data can be written on your local client and will be send to {{ slurm_cluster_name | capitalize }} for analysis of the data sets.
 * Result files can also stay on {{ slurm_cluster_name | capitalize }}.

#### 0. Install software on your own computer

You only need a web browser and an SSH client, which you most likely already have by the time your read this documentation.
There is no need to install any _Jupyter_ components locally.

#### 1. Login on {{ slurm_cluster_name | capitalize }}

[Login on {{ slurm_cluster_name | capitalize }} with your SSH client](../logins/)

#### 2. Create a screen or tmux session on {{ slurm_cluster_name | capitalize }}

Optionally start a ```screen``` or ```tmux``` session.  
Working with ```screen``` or ```tmux``` is beyond the scope of this documentation, but highly recommended.
It allows you to disconnect from {{ slurm_cluster_name | capitalize }} while leaving your session running,
so you can re-login and re-connect later.
Without ```screen``` or ```tmux``` a dropped network connection will result in loosing the session and loosing any unsaved work in it.

There is a good article [How to Use Linux’s screen Command](https://www.howtogeek.com/662422/how-to-use-linuxs-screen-command/) on the _How-To Geek website_.
Use the ```-S``` argument to give your ```screen``` session a name. E.g. to create one named ```jupyter```:
```bash
screen -S jupyter
```

#### 3. Create an interactive Slurm session on {{ slurm_cluster_name | capitalize }}

See [Crunch - How to manage jobs on {{ slurm_cluster_name | capitalize }}](../analysis/) for details.  
Simple example requesting a single core and 1 GB RAM memory for max one hour:
```bash
srun --cpus-per-task=1 --mem=1gb --nodes=1 --qos=interactive --time=01:00:00 --pty bash -i
hostname
```
The ```hostname``` command will report the name of the compute node where your interactive Slurm session is running;
You will need this name later on when creating the SSH tunnel...  

#### 4. Load and start Jupyter in your interactive Slurm session on {{ slurm_cluster_name | capitalize }}

```bash
module load JupyterLab
jupyter lab --no-browser
```
_Jupyter_ will now create a session and report

 * which _port_ it selected
 * the _secret_ / _cookie_ it generated to secure the session
 * the _URL_ you can use locally to access your _Jupyter_ session on {{ slurm_cluster_name | capitalize }}

E.g.:
```bash
[I 2023-05-23 17:19:18.578 ServerApp] jupyterlab | extension was successfully linked.
[I 2023-05-23 17:19:18.590 ServerApp] nbclassic | extension was successfully linked.
[I 2023-05-23 17:19:18.599 ServerApp] Writing Jupyter server cookie secret to /home/*******/.local/share/jupyter/runtime/jupyter_cookie_secret
[I 2023-05-23 17:19:25.788 ServerApp] notebook_shim | extension was successfully linked.
[I 2023-05-23 17:19:26.141 ServerApp] notebook_shim | extension was successfully loaded.
[I 2023-05-23 17:19:26.142 LabApp] JupyterLab extension loaded from /apps/software/JupyterLab/3.5.0-GCCcore-11.3.0/lib/python3.10/site-packages/jupyterlab
[I 2023-05-23 17:19:26.142 LabApp] JupyterLab application directory is /apps/software/JupyterLab/3.5.0-GCCcore-11.3.0/share/jupyter/lab
[I 2023-05-23 17:19:26.148 ServerApp] jupyterlab | extension was successfully loaded.
[I 2023-05-23 17:19:26.232 ServerApp] nbclassic | extension was successfully loaded.
[I 2023-05-23 17:19:26.233 ServerApp] Serving notebooks from local directory: /path/to/dir/from/where/jupyter/was/started/
[I 2023-05-23 17:19:26.233 ServerApp] Jupyter Server 1.21.0 is running at:
[I 2023-05-23 17:19:26.233 ServerApp]     http://localhost:8888/lab?token=b23e4350********************************db01a09e
[I 2023-05-23 17:19:26.233 ServerApp]  or http://127.0.0.1:8888/lab?token=b23e4350********************************db01a09e
[I 2023-05-23 17:19:26.233 ServerApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
[C 2023-05-23 17:19:26.257 ServerApp] 
    
    To access the server, open this file in a browser:
        file:///home/*******/.local/share/jupyter/runtime/jpserver-16777-open.html
    Or copy and paste one of these URLs:
        http://localhost:8888/lab?token=b23e4350********************************db01a09e
     or http://127.0.0.1:8888/lab?token=b23e4350********************************db01a09e
```
Each session needs its own unique port and ```jupyter lab``` automatically selected one that is free.
You will need this port number later on when creating the SSH tunnel.
Once the SSH tunnel is established you can user either of the URLs in a web browser on your local computer.

Keep the _token_ safe and treat it like a password to prevent others from hijacking your _Jupyter_ session.

Optionally in case you are running this inside ```screen```:  
Now press ```CTRL+a``` followed by ```CTRL+d``` to detach from the ```screen```.
The ```jupyter lab``` session inside the interactive Slurm job inside the ```screen``` session will continue to run in the background.
You can reconnect to the existing screen session using ```-r``` argument and the name of the ```screen``` session.  
E.g.:
```bash
screen -r jupyter
```

#### 5. Create an SSH tunnel on your own computer

Now we need to create an SSH tunnel from your local client computer to the server and connect to the remote R session.

###### For Windows clients

The instructions below we assume you use _MobaXterm_ to connect to {{ slurm_cluster_name | capitalize }} as described in
[SSH config and login to UI via Jumphost for users on Windows](../logins-windows/).

![configure MobaSSHTunnel](img/MobaSSHTunnel1.png)

 * 1: Select _**MobaSSHTunnel**_ from the _**Tools**_ menu.

![configure MobaSSHTunnel](img/MobaSSHTunnel2.png)

 * 2: Click the _**New SSH tunnel**_ button.

![configure MobaSSHTunnel](img/MobaSSHTunnel3.png)

 * In the popup window fill in / select:
    * 3: _**Local port forwarding**_
    * 4: _Remote server_ field: The _**hostname**_ of the _compute node_ where ```jupyter lab``` is running.
    * 5: _Remote port_ field: The _**port number**_ chosen by ```jupyter lab``` on the server side.
    * 6: _SSH server_ field: Use _jumphost_ address _**{{ first_jumphost_address }}**_.
    * 7: _SSH login_ field: Use your _**account name**_ as you received it by email from the helpdesk.
    * 8: _SSH port_ field: _**22**_
    * 9: _Forwarded port_ field: The _**port number**_ you chose on the client side.  
      For the _Forwarded port_ you have to chose a free port yourself.
      Hence, it must be a port that is not yet used by another process.
      We suggest you simply try to use the same number as the one that ```jupyter lab``` selected on the server side.
      If that one does not work because it is already taken, simply increment by one and retry until you found one that is free.
    * 10: Click the _**Save**_ button.

![configure MobaSSHTunnel](img/MobaSSHTunnel4.png)

 * 11: Give the tunnel config a _**name**_.
 * 12: Click the key icon to select your _**private key file**_.
 * 13: Click the _**play**_ button to start the SSH tunnel.

###### For Linux & macOS clients

Use the ```ssh``` command in a terminal to create an SSH tunnel from your local machine via _jumphost_ {{ groups['jumphost'] | first }}
to the {{ slurm_cluster_name | capitalize }} _compute node_ on which ```jupyter lab``` is running in your interactive Slurm session.
The general syntax is:
```bash
ssh -N -L localhost:<port_number_on_client>:localhost:<port_number_on_server> {{ groups['jumphost'] | first }}+<hostname_of_jupyter_server>
```
The example below uses the same port number on the client side as the one chosen by ```jupyter lab```
running on {{ slurm_cluster_name | capitalize }} compute node {{ groups['compute_node'] | first }}.
```bash
ssh -N -L localhost:8888:localhost:8888 {{ groups['jumphost'] | first }}+{{ groups['compute_node'] | first }}
```
If you get a message like this:
```bash
bind [127.0.0.1]:8888: Address already in use
channel_setup_fwd_listener_tcpip: cannot listen to port: 8888
Could not request local forwarding.
```
then the selected port on the client side is not free and already used by another process.
Try the next port number until you find one that is free: in that case you will not get any message.
E.g.:
```bash
ssh -N -L localhost:8889:localhost:8888 {{ groups['jumphost'] | first }}+{{ groups['compute_node'] | first }}
```

#### 6. Using the Jupyter session in a web browser on your own computer

You can now connect to the remote _Jupyter_ session by pasting the URL in a web browser on your own computer.
Make sure to paste the complete URL including the generated session _token_ (e.g. ```http://localhost:8888/lab?token=b23e4350********************************db01a09e```) in the address bar.
Depending on the web browser used the _token_ may be hidden from the address bar once you hit the ```[ENTER]``` key.

![use Jupyter on your own computer](img/Jupyter.png)

#### 7. Cleaning up

**Don’t keep Jupyter running forever on {{ slurm_cluster_name | capitalize }}!**
Make sure to really exit your session on {{ slurm_cluster_name | capitalize }} when you are done to prevent wasting resources,
which is not nice for others waiting in the queue.

 * Without ```screen```:  
   Press ```CTRL+c``` and answer ```y``` to quit the ```jupyter lab``` session. Next, type ```exit``` or ```CTRL+x``` to exit your interactive Slurm job.
 * With ```screen```:  
   First re-attach to your screen session if you were detached.
   Now, press ```CTRL+c``` and answer ```y``` to quit the ```jupyter lab``` session. Next, type ```exit``` or ```CTRL+x``` to exit ```screen``` and another ```exit``` or ```CTRL+x``` to exit your interactive Slurm job.

```bash
Shutdown this Jupyter server (y/[n])? y
[C 2023-05-23 18:07:34.005 ServerApp] Shutdown confirmed
[I 2023-05-23 18:07:34.008 ServerApp] Shutting down 3 extensions
[I 2023-05-23 18:07:34.008 ServerApp] Shutting down 0 terminals
```

