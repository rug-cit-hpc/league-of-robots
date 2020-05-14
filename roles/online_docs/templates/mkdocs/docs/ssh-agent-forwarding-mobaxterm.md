# SSH agent forwarding with MobaXterm on Windows

SSH agent forwarding can be configured for MobaXterm as follows:

* Select the _Configuration_ menu item from the _Settings_ menu  
  ![MobaXterm Configuration](img/MobaXterm10.png)
* Select the _SSH_ tab  
  ![MobaXterm Configuration](img/MobaXterm11.png)  
    1. Enable _**Use internal SSH agent "MobAgent"**_  
    2. Enable _**Forward SSH agents**_  
    3. Click the _**+**_ button to select and load your private key.

When you now start a new session and login to a server optionally via a jumphost your private key key will be forwarded to the machine you login to.

-----

Back to operating system independent [instructions for data transfers](../datatransfers/)