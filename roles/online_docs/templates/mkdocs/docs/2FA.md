{% if totp is defined %}

#jinja2: trim_blocks:False

# Configure 2-Factor-Authentication to use secure-enhanced jumphost

1. Overview

    1.1. What is the 2FA and how it works

        2FA stands for Two-factor authentication. The 2FA provides additional mechanism to the user to authenticate on the remote system. It is implemented when a single authentication (f.e. only public/private key pair or just password) is not enough.

    1.2. What is needed before user can create 2FA (time-based) keys?
        - user needs to have working access to the *UMCG WOM Citrix environment* (or similar trusted system)
        - already generated public/private key pair on *UMCG WOM environment* by the user, and this public key needs to be added by the hpc.helpdesk@umcg.nl to the appropriate user databases
    Instructions on how to create key-pair are avaiable at https://docs.gcc.rug.nl/ look at the *Generate a public/private key pair for ...*


2. Generating 2FA time-based key for the first time:

            Jumphosts servers with 2FA enhanced security enforce the usage of 2FA Time-based keys on incoming connections from all non-trusted IP addresses. There are servers that are exempt from additinal 2FA (in current configuration this is only UMCG WOM environment). Therefore to initially create a 2FA time-based key, user first needs to connect to jumphost from UMCG WOM environment. For this step only public/private key pair is needed. When the connection to jumphost is created, the automatic script will create in users environment 2FA key, that needs to be stored (by reading the printed QR code with mobile phone Authenticator application). See steps `2.x.` for detailed instructions.

    Overview on how the 2FA is implemented
            
            ![connection overview](img/2FA-initial.png)
            

    2.1.  Connect to the trusted system (f.e. to UMCG WOM, or use your laptop from within UMCG network) and start the MobaXTerm
    2.2. Create the session to connect to Jumphost {% for jumphost in groups['jumphost'] %}{{ jumphost }}{% endfor %} only
    2.3. **Create session** > **SSH**
    2.4. **Remote host**: {% for jumphost in groups['jumphost'] %}{{ public_ip_addresses[jumphost] }}{% endfor %}
    2.5. **Specify username**: your-username
    2.6. **Advanced SSH settings** > **Use private key**
        (f.e. `H:\desktop\myprivate-key.ppk`, make sure it contains drive letters, like `H:\some\path` and not `\\some\shared\network\path`)
    2.7. Start this ^ newly created session and provide password for associated private key
    2.8. Upon login to the 2FA jumphost, you will be greeted with (see Appendix 1)

         **Save scratch codes somewhere safe**, as they provide access to the system in case you don't have access to the authenticator app and to the WOM

         (you can also find codes in the file named `.totp` on the jumphosts home folder)

    2.9. Scan the new QR code with your phone and use one of the Authenticator apps to store the secret key (applications links are at the bottom in the Appendix 2)

         "Microsoft authenticator" and "Google authenticator"

    2.10. Done. Future connections from non-UMCG IP to the jumphost will require the use of Authenticator app

         (in case you create multiple short time connections, use "ssh ControlPersist" option, as it will keep the session alive for predefined time and you won't need to use 2FA every time)

    2.11. Repeat the 2.x. steps for each username that has access to the jumphosts and that you would like to access from non-UMCG IP's

         for each username like umcg-myusername (regular user group) and firstname (admin group)

3. Subsequent connections from untrusted IP addresses trough 2FA jumphosts (to limited-access machines)

    After user created the 2FA time-based key, the connections to jumphost server from any IP address will have to provide:

        - the correct public/private key pair, and
   
        - 2FA Time-based key, that is made on user's mobile app

          
    ![connection overview](img/2FA-following.png)
            

    When user connects (from untrusted IP) to the 2FA enhanced jumphost, prompt will appear:

        `(your-username@{% for jumphost in groups['jumphost'] %}{{ public_ip_addresses[jumphost] }}{% endfor %}) Your verification code for {% for jumphost in groups['jumphost'] %}{{ jumphost }}{% endfor %}:`

        Users mobile generates 2FA code, that is valid for 30 seconds, after it expires and another is generated. The codes are valid only for this short time and are specific for each system and for each username.

4. Connecting Issues:
    - **Problem**:
        I cannot connect to the jumphost, server returns:
        `your-username@{% for jumphost in groups['jumphost'] %}{{ public_ip_addresses[jumphost] }}{% endfor %}: Permission denied (keyboard-interactive).`
    - **Solution**:
        - check if you are using the correct username, and that you have created 2FA key for this username
        - if 2FA key is missing, create new 2FA key (follow steps `2.x`)

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

{% endif %}
