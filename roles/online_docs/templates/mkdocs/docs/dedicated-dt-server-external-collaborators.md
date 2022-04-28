#jinja2: trim_blocks:False
# Data transfers - How to move data to / from {{ dt_server_address }}

Firstly and independent of technical options: make sure you are familiar with the _code of conduct_ / _terms and conditions_ / _license_ or whatever it is called and that you are allowed to upload/download a data set!
When in doubt contact your supervisor / principal investigator and the group/institute that created the data set.

## Instructions for external collaborators

For both macOS and Windows users who prefer a graphical user interface (GUI) we recommend [FileZila](https://filezilla-project.org/download.php?show_all=1).
There are various other good and free SFTP clients, but note that not all SFTP clients support authentication with all types of SSH keys.
Alternatively you can also use rsync on the commandline to transfer data. The rsync protocol is more efficient especially for resuming partially succeeded transfers,
but unfortunately there are no good GUIs for rsync. See below for detailed instructions to transfer data with:

 * [FileZilla SFTP client app on Windows](#FileZila-Windows)
 * [FileZilla SFTP client app on macOS](#FileZila-macOS)
 * [rsync over SSH on the commandline](#rsync-commandline)

#### Transfer data with FileZilla SFTP client app on Windows

<a name="FileZila-Windows"></a>

If you work in a restricted environment that does not allow you to install software yourself,
then make sure you download the _portable_ version that does not need to be installed 
(filename of the download [on this page](https://filezilla-project.org/download.php?show_all=1) ends in _.zip_ extension)
as opposed to the FileZilla _installer_ (filename of the download ends in _.exe_ extension)

###### Start FileZilla

![Start FileZilla and open the Site Manager](img/FileZilla-Windows-1.png)

 * 1: Click the _**Site Manager**_ button to configure the connection to {{ dt_server_address }}

###### Create new site with connection details for {{ dt_server_address }}

![FileZilla Site Manager](img/FileZilla-Windows-2.png)

 * 2: Click the _**New Site**_ button.
 * 3: Provide a name for the new site.
 * 4: Select the _**SFTP**_ protocol.
 * 5: Enter the address **{{ dt_server_address }}** in the _**Host**_ field.
 * 6: Use _**Port**_ **22** (default).
 * 7: Select _**Logon Type**_ **Key File**.
 * 8: Enter the guest **accountname** you received from the helpdesk in the _**User**_ field.
 * 9: Click the _**Browse**_ button to select your **private key**.
 * 10: Click the _**Connect**_ button.

###### Remember passwords?

![FileZilla Site Manager](img/FileZilla-Windows-3.png)

 * 11: Select _**Do not save passwords**_.
 * 12: Click the _**OK**_ button.

###### Unknown host key

If this is the first time you connect to {{ dt_server_address }},
FileZilla will show you the _**fingerprint**_ of the server's host key. 

![FileZilla Site Manager](img/FileZilla-Windows-4.png)

 * 13: Verify if the shown _**fingerprint**_ matches one of:  
   {% for fingerprint in data_transfer_host_key_fingerprints.stdout | default('missing', true) | split('\n') %}```{{ fingerprint }}```
   {% endfor %}
 * 14: Only if the **fingerprint** shown **matches** the expected fingerprint: click the _**OK**_ button to continue.  
   Otherwise, if the **fingerprint does not match**, click the _**Cancel**_ button and [contact our helpdesk](../contact/).

###### Password for the private key

![FileZilla Site Manager](img/FileZilla-Windows-5.png)

 * 15: Provide the password for the private key. (You chose this password yourself when you created your key pair.)
 * 16: Click the _**OK**_ button.

###### Drag and drop files or folders to start a transfer

FileZilla will login and start a session.
You can browse files/folders on your local machine in the left column and on {{ dt_server_address }} in the right column.
Drag files/folder from the left column to the right one to upload or vice versa to download.

![FileZilla Site Manager](img/FileZilla-Windows-6.png)

#### Transfer data with FileZilla SFTP client app on macOS

<a name="FileZila-macOS"></a>

###### Start FileZilla

![Start FileZilla and open the Site Manager](img/FileZilla-macOS-1.png)

 * 1: Click the _**Site Manager**_ button to configure the connection to {{ dt_server_address }}

###### Create new site with connection details for {{ dt_server_address }}

![FileZilla Site Manager](img/FileZilla-macOS-2.png)

 * 2: Click the _**New Site**_ button.
 * 3: Provide a name for the new site.
 * 4: Select the _**SFTP**_ protocol.
 * 5: Enter the address **{{ dt_server_address }}** in the _**Host**_ field.
 * 6: Use _**Port**_ **22** (default).
 * 7: Select _**Logon Type**_ **Key File**.
 * 8: Enter the guest **accountname** you received from the helpdesk in the _**User**_ field.
 * 9: Click the _**Browse**_ button to select your **private key**.
   Note: if your private key was stored in a _hidden_ folder (folder name starts with a dot), you can press [SHIFT]+[.] to show hidden files and folders in dialog windows.
 * 10: Click the _**Connect**_ button.

###### Convert key file

FileZilla stores private keys in _PuTTY Private Key_ file format (*.ppk).
It cannot use private keys in OpenSSH format, but can convert a private key generated with OpenSSH into a *.ppk file.

![FileZilla Site Manager](img/FileZilla-macOS-3.png)

 * 11: Click the _**Yes**_ button.

###### Password for the private key

![FileZilla Site Manager](img/FileZilla-macOS-4.png)

 * 12: Provide the password for the private key. (You chose this password yourself when you created your key pair.)
 * 13: Click the _**OK**_ button.

###### Select filename for converted key file

![FileZilla Site Manager](img/FileZilla-macOS-5.png)

 * 14: Provide a new name for the converted private key. (Hence, do not overwrite the existing private key file.)
 * 15: Click the _**Save**_ button.

###### Remember passwords?

![FileZilla Site Manager](img/FileZilla-macOS-6.png)

 * 16: Select _**Do not save passwords**_.
 * 17: Click the _**OK**_ button.

###### Unknown host key

If this is the first time you connect to {{ dt_server_address }},
FileZilla will show you the _**fingerprint**_ of the server's host key.

![FileZilla Site Manager](img/FileZilla-macOS-7.png)

 * 18: Verify if the shown _**fingerprint**_ matches one of:  
   {% for fingerprint in data_transfer_host_key_fingerprints.stdout | default('missing', true) | split('\n') %}```{{ fingerprint }}```
   {% endfor %}
 * 19: Only if the **fingerprint** shown **matches** the expected fingerprint: click the _**OK**_ button to continue.  
   Otherwise, if the **fingerprint does not match**, click the _**Cancel**_ button and [contact our helpdesk](../contact/).

###### Drag and drop files or folders to start a transfer

FileZilla will login and start a session.
You can browse files/folders on your local machine in the left column and on {{ dt_server_address }} in the right column.
Drag files/folder from the left column to the right one to upload or vice versa to download.

![FileZilla Site Manager](img/FileZilla-macOS-8.png)

#### Transfer data with rsync over SSH on the commandline

<a name="rsync-commandline"></a>

You can use rsync (over ssh) to transfer data to/from _{{ dt_server_address }}_.
Note that the data transfer uses _rsync modules_, which uses double colon syntax (::) to separate the name/address of the server from the path on the server.
The rsync protocol is more efficient for large data sets and easier to automate, but unfortunately there are no free and good rsync client apps with a Graphical User Interface (GUI).
See below for some syntax examples.

```
#
##
### Specify only source and leave a destination out to get a listing of modules, files and folders available on the source side.
##
#
# Request a list of rsync modules available for user some-guest-account.
#
rsync -v --rsh='ssh -p 443 -l some-guest-account' {{ dt_server_address }}::
#
# List contents in the home module.
#
rsync -v --rsh='ssh -p 443 -l some-guest-account' {{ dt_server_address }}::home/
#
##
### Specify both a source as well as a destination to transfer data.
##
#
# Push a file from user interface to data transfer server.
#
rsync -av --rsh='ssh -p 443 -l some-guest-account' path/to/file_on_local_computer {{ dt_server_address }}::home/
#
# Reverse source and destination to pull a file from data transfer server onto user interface server.
#
rsync -av --rsh='ssh -p 443 -l some-guest-account' {{ dt_server_address }}::home/data_on_transfer_server path/to/dir_on_local_computer/
```

-----

Back to [overview for dedicated data transfer server](../dedicated-dt-server-overview/)