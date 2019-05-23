#jinja2: trim_blocks:False
# Request an account

## 1. Accounts, security and privacy.

#### Asymmetric key cryptography

We use asymmetric key cryptography to secure accounts. Hence you will get an account name, but no password. Instead of a password we use two digital keys:

 * A private key
 * A public key

The private key can be used to encrypt data (close the lock) and the associated public key can be used to decrypt the data (open the lock).
As the name suggests the public key is not secret; you can share this with everyone, publish it on your website, etc.
Hence your public key cannot be _compromised_, because it's intended to be public.
The private key on the other hand must be private; if it gets stolen your account is compromised and can be abused.
Therefore, [contact us](../contact/) immediately if you ever suspect your private key may have been stolen/copied!

For additional details and background see [WikiPedia: Asymmetric Key Cryptography](http://en.wikipedia.org/wiki/Public-key_cryptography)

When you try to login you use the private key on the client side to encrypt a small piece of data containing a request to login.
The cluster uses your public key on the server side to decrypt the login request: if this was successful the server has verified that you have the private key corresponding to the public key and will let you in.

The benefit of using key pairs as opposed to passwords is that the secret used to login can remain private if you create the key pair yourself and send _**only**_ the public key to the helpdesk.
Hence we do not have a copy/record/backup of your private key on the server side: if you loose the private key, you have to create a new pair and send the new public key to the helpdesk.

#### Security & Privacy 

* When you request an account you're email address will be added automatically to a low volume mailinglist, which is used for information regarding the clusters like maintenance announcements.
* When you use the cluster and are logged in:
  * You can secure the content of files/folders, so only you or only members of a specific group can access the content either with read-only or with read-write permissions.  
    This requires setting the desired permissions for files or folders, which is your own responsibility. When you specify wrong permissions, data may be accessible for others.
  * You **cannot** secure the meta data of files/folders.
    * Hence things like file or folder names, time stamps, size, owner, group, etc. can always be seen by anyone who is logged in.
    * This also applies to the name of and resources requested for job script files: all users can see the meta-data of all queued and all running jobs.  
  Therefore **never ever put privacy sensitive data in the meta-data of files or folders**!
  * Your full name, email address, group memberships and role in a group (regular user or data manager or group owner) are visible to all other users.

## 2. Generate a public/private key pair

#### 2.A On Linux / Unix / macOS

###### Open a terminal/shell

 * On **macOS**: A terminal app is already part of the OS by default. Optionally you may want to install the [XQuartz X server](http://xquartz.macosforge.org/) for graphical apps.  
   Open the Terminal application, which is located in _**Applications**_ -> _**Utilities**_ -> _**Terminal.app**_.
 * On **Linux / Unix**: A terminal app is already part of the OS by default and usually you also already have an X window server installed for graphical apps. Consult your distro documentation for details.

###### Generate key pair

To generate an RSA key pair with OpenSSH, type the following command:
```no-highlight
ssh-keygen -t ed25519 -C "your_comment_see_below"
```
As comment/label for your keys please use **your first initial followed by (optionally your middle name followed by) your family name** all in lowercase and without any separators like spaces, dots or underscores. 
So if your name is _**Jack the Hippo**_, please use _**jthehippo**_ as comment, so we can easily identify the key as yours.

###### Select where to store the key pair

The ssh-keygen application will now ask you where you want to save the private key:
```no-highlight
Enter file in which to save the key (/path/to/your/home_dir/.ssh/id_ed25519): <return>
```
By default it will be stored in your ```~/.ssh/``` folder where ```~``` is your home directory.
The public key will be stored in the same location as the private key, start with the same name as the private key and have a ```.pub``` suffix.  
WARNING:
 1. Accepting the default may overwrite existing keys, so check first if you already have a key in that location!  
    Only accept the default by pressing the *\<return\>* key if you have no key in the default location.
 2. OpenSSH will by default use the key from the default location. 
    If you create the key in a non-default location, you will need to explicitly specify which key file to use when connecting via ssh or sftp.

###### Secure the private key

Secure your private key with a good password. DO NOT choose a simple password or even worse an empty one!
```no-highlight
Enter passphrase (empty for no passphrase): <Type the passphrase>
```
Note: this is a password to encrypt your private key. It is not a password for you account. 
The ssh-keygen command will now generate two files. In case you chose the default location these will be:

 * Your private key in ```~/.ssh/id_ed25519```
 * Your public key in ```~/.ssh/id_ed25519.pub```

If you forgot to add a password to your private key or if you want to change the password later on, you can add a (new) password to your existing private key with:
```no-highlight
ssh-keygen -p -f ~/.ssh/id_ed25519
```

[Proceed to step 3. Request account and have the public key linked to your account](#request-account)

#### 2.B On Windows

###### Get PuTTYgen

You can use the ```PuTTYgen``` application, which is distributed as part of the **PuTTY** suite and also bundled with **WinSCP**, to generate a key pair.

 * Install [WinSCP](http://winscp.net/eng/download.php) if you only want to transfer data to/from the cluster via a graphical user interface.
 * Install [PuTTY](http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html) if you want to login via SSH to process data or if you want to transfer data via the commandline.

1. Launch PuTTYgen as shown in the screenshot below.
![launch PuTTYgen](img/puttygen1.png)

###### Configure

![Select key type](img/puttygen2.png)

 * 2: From the **parameters** section at the bottom of the window choose: ```Type of key to generate:``` **ED25519**
 * 3: Click the **Generate** button...

###### Generate key pair

![Generate randomness and subsequently key pair](img/puttygen3.png)

 * 4: Yes you really have to move the mouse now: computers are pretty bad at generating random numbers and PuTTYgen uses the coordinates of your mouse movement as a seed to generate a random number.

###### Secure private key and save pair to disk

Your key pair was generated.

![Save keys](img/puttygen4.png)

Now make sure you:

 * 5:  Replace the comment in **Key comment** with  
       **your first initial followed by (optionally your middle name followed by) your family name** all in lowercase and without any separators like spaces, dots or underscores.  
       So if your name is _**Jack the Hippo**_, please use _**jthehippo**_ as comment, so we can easily identify the key as yours.
 * 6:  Secure your private key with a good password **before** saving the private key. DO NOT choose a simple password or even worse an empty one!
 * 7:  Confirm the password
 * 8:  Click the **Save public key** button.
 * 9:  Click the **Save private key** button.
 * 10: Select and copy all the text in the text box at the top of the window underneath **Public key for pasting into OpenSSH authorized_keys file**.
       You can paste it in the email you'll send in the next step.

<a name="request-account"></a>

## 3. Request account and have the public key linked to your account

To request an account, [contact the helpdesk via email](../contact/) and

 * 3.A If on Linux / Unix / macOS:  
   Attach the id_rsa.pub public key file generated with ssh-keygen.  
   If you cannot see / find the key file, you most likely stored the file in a folder starting with a ```.```; e.g. in your ```~/.ssh``` folder which is the default.
   Folders and files that start with a ```.``` are *hidden* files and not displayed by default.
   On macOS you can press ```<Shift>+<Cmd>+<.>``` to toggle the visibility of hidden files in *Open...* and *Save...* dialog windows.
   Please use a search engine for a solution to display hidden files in other situations like Finder windows or on other platforms.
 * 3.B If on Windows:  
   Paste the contents of the public key as displayed in PuTTYgen's *Public key for pasting into OpenSSH authorized_keys file* field in the email.
 * Motivate your account request by specifying the project your are working on and by adding your collaborators on CC.
 * Never ever email/give anyone your private key! If you do, the key is no longer private and useless for security: trash the key pair and start over by generating a new pair.
 * If you ever suspect that your private key may have been compromised (laptop got stolen, computer got infected with a virus/trojan/malware, etc.): 
    * [notify the helpdesk](../contact/) immediately, so we can revoke the public key for the compromised private key
    * and start over by generating a new pair

## 4. Start using servers/services

Once you get notified by email that your account is ready you can proceed to [login](../logins/)