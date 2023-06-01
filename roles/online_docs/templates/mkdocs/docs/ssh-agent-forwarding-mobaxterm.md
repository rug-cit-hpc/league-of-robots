# SSH agent forwarding with MobaXterm on Windows

SSH agent forwarding can be configured for MobaXterm as follows:

* Select the _Configuration_ menu item from the _Settings_ menu  
  ![MobaXterm Configuration](img/MobAgent1.png)
* Select the _SSH_ tab in the popup window  
  ![MobaXterm Configuration](img/MobAgent2.png)  
    1. Enable _**Use internal SSH agent "MobAgent"**_  
    2. Click the _**+**_ button to select and load your private key.
    3. Click the _**Ok**_ button to save these settings.
* For each SSH connection where you want to use an SSH Agent to forward your private key,
  you must enable this explicitly in the _Advanced SSH settings tab_ tab for that _SSH_ session.
  In addition to the required values/settings as described in [SSH config and login for Windows clients](../logins-windows/),
  you must also:
  ![MobaXterm Configuration](img/MobAgent3.png)  
    4. Click the _**Expert SSH settings**_ button  
* In the _Advanced SSH protocol settings_ popup window  
  ![MobaXterm Configuration](img/MobAgent4.png)  
    4. Enable the _**Allow agent forwarding**_ checkbox  
    5. Click the _**Ok**_ button to save the settings for this SSH session.

When you now (re)start this SSH session and login to a server optionally via a jumphost your private key key will be forwarded to the machine you login to.

-----

Back to operating system independent [instructions for data transfers](../datatransfers/)