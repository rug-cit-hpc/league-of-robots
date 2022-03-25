#jinja2: trim_blocks:False

# Creating 2FA time-based keys for the enhanced jumphost servers

1. What is the 2FA and how it works
   2FA stands for Two-factor authentication. The 2FA provides additional mechanism to the user to authenticate on the remote system. It is implemented when a single authentication (f.e. only public/private key pair or just password authentication) is not enough.

   What is needed before user can create 2FA (time-based) keys?
   - user needs to have working access to the *UMCG WOM Citrix environment* (or similar trusted system)
   - already generated public/private key pair on *UMCG WOM environment* by the user, and this public key needs to be added by the hpc.helpdesk@umcg.nl to the appropriate user databases
     Instructions on how to create key-pair are avaiable at https://docs.gcc.rug.nl/ look at the *Generate a public/private key pair for ...*

2. Overview
    0. This instructions are split into two parts:
       - initial connection when user does not yet have 2FA key (steps on how to create it)
            ![connection overview](img/2FA-initial.png)
       - direct connections through jumphost with created 2FA keys
            ![connection overview](img/2FA-following.png)
    1. First connection and creation of 2FA key
        Jumphosts servers with 2FA enhanced security enforce the usage of 2FA Time-based keys on all incoming connections fron non-trusted IP addresses. There are servers that are exempt from 2FA. In current configuration this is only UMCG WOM environment. Therefore to initially create a 2FA time-based key, user first needs to connect from UMCG WOM environment to the 2FA jumphost. User needs only his/her public/private key pair. After the connection is established, the 2FA time-based key will be created automaticaly in users environment and user only needs to store this key (by reading the printed QR code with his mobile phone Authenticator application). See steps `3.x.` for detailed instructions.
    2. Subsequent connections
        After user created the 2FA time-based key, the connections to jumphost server from any IP address will have to provide:
        - the correct public/private key pair, and
        - 2FA Time-based key, that is made on user's mobile app

3. Generating 2FA time-based key for the first time:
    0.  Connect to WOM and start the MobaXTerm
    1. Create the session to connect to Jumphost {% for jumphost in groups['jumphost'] %}{{ jumphost }}{% endfor %} only
    2. **Create session** > **SSH**
    3. **Remote host**: {% for jumphost in groups['jumphost'] %}{{ public_ip_addresses[jumphost] }}{% endfor %}
    4. **Specify username**: your-username
    5. **Advanced SSH settings** > **Use private key**
        (f.e. `H:\desktop\myprivate-key.ppk`, make sure it contains drive letters, like `H:\some\path` and not `\\some\shared\network\path`)
    6. Start this ^ newly created session and provide password for associated private key
    7. Upon login to the 2FA jumphost, you will be greeted with (see Appendix 1)
         **Save scratch codes somewhere safe**, as they provide access to the system in case you don't have access to the authenticator app and to the WOM
         (tip: codes are also stored on the jumphost in the user home folder inside the `~/.totp` file)
    8. Scan the new QR code with your phone and use one of the Authenticator apps to store the secret key (applications links are at the bottom in the Appendix 2)
         "Microsoft authenticator" and "Google authenticator"
    9. Done. Future connections from non-UMCG IP to the jumphost will require the use of Authenticator app
         (in case you create multiple short time connections, use "ssh ControlPersist" option, as it will keep the session alive for predefined time and you won't need to use 2FA every time)
    10. Repeat the 3.x. steps for each username that has access to the jumphosts and that you would like to access from non-UMCG IP's
         for each username like umcg-myusername (regular user group) and firstname (admin group)

4. Subsequent connections from untrusted IP addresses trough 2FA jumphosts (to limited-access machines)
    1. when user connects (from untrusted IP) to the 2FA enhanced jumphost, prompt will appear:
        `(your-username@{% for jumphost in groups['jumphost'] %}{{ public_ip_addresses[jumphost] }}{% endfor %}) Your verification code for {% for jumphost in groups['jumphost'] %}{{ jumphost }}{% endfor %}:`
       Users mobile generates 2FA code, that is valid for 30 seconds, after it expires and another is generated. The codes are valid only for this short time and are specific for each system and for each username.

5. Connecting Issues:
    - **Problem**: I cannot connect to the jumphost, server returns:
    `your-username@{% for jumphost in groups['jumphost'] %}{{ public_ip_addresses[jumphost] }}{% endfor %}: Permission denied (keyboard-interactive).`
    **Solution**: 
        - check if you are using the correct username, and that you have created 2FA key for this username
        - if 2FA key is missing, create new 2FA key (follow steps `3.x`)

###### Appendix 1
When you connect to the system for the first time, you will be greeted with something like (example values):
```
    INFO: Two factor authentication was not yet configured; generating new secret and recovery codes ...
   
    Your new secret key is: OUD734ISSD7YIJ3N3D
    Your verification code is 73571833
    Your emergency scratch codes are:
      29628806
      50135461
      90557681
      62811935
      42597833
    
    INFO: Make sure you save the recovery codes and optionally the secret in a secure location;
           * You will not see these codes again upon next login!
           * If you loose them and no longer have access to the device you will configure with the QR code                                                              below,
             you will have locked yourself out!

... multiple lines of QR code to be scanned with mobile Authenticator app ...
```

###### Appendix 2: Links


**Mobile authentication applications for Android and iOS**
- Android apps from Google app store
    - [Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2)
    - [Microsoft Authenticator](https://play.google.com/store/apps/details?id=com.azure.authenticator&hl=en&gl=US)
- iOS apps from Apple app store
    - [Google Authenticator](https://apps.apple.com/us/app/google-authenticator/id388497605)
    - [Microsoft Authenticator](https://apps.apple.com/us/app/microsoft-authenticator/id983156458)

**About 2-factor-authentication**
   - [What is Google Authenticator](https://en.wikipedia.org/wiki/Google_Authenticator)
   - [More about Time-based one-time password](https://en.wikipedia.org/wiki/Time-based_one-time_password)
