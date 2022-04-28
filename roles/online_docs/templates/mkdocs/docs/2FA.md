#jinja2: trim_blocks:False

{% if totp is defined %}

# Configure 2-Factor-Authentication to use secure-enhanced jumphost

1. Overview

    1.1. What is the 2FA and how it works

    The 2FA (Two-factor authentication) provides additional mechanism for user to authenticate on remote system. It is implemented when a single authentication, like public/private key pair or just using password, is not enough.

    1.2. What is needed before user can create 2FA (time-based) keys?

    - user needs to have working access to the *UMCG WOM Citrix environment* (or similar trusted system)

    - already created public/private key pair on *UMCG WOM environment* by the user, and public key has already been added by the hpc.helpdesk@umcg.nl personnel to the appropriate user databases 

    If you are missing there two steps, take a look at the section *Generate a public/private key pair for ...* for instructions on how to create everything that is needed for the 2FA.

2. Generating 2FA time-based key for the first time (example for MobaXterm on Windows):

    ![connection overview](img/2FA-initial.png)

    Jumphosts servers with enhanced security are enforcing 2FA for all incoming connections from non-trusted IP addresses. There are servers that are exempt from this and in current configuration this is only UMCG WOM environment. To create a 2FA time-based key, user needs to connect to jumphost from UMCG WOM environment. This step requires only public/private key pair. After the connection to jumphost is established, script will automatically create 2FA key in users environment and QR code will be displayed. As a last step QR code needs to be scanned with mobile phone Authenticator application.

    Step by step instructions

    2.1. Connect to the trusted system (f.e. to UMCG WOM, or use your laptop from within UMCG network) and start the MobaXTerm

    2.2. Create the session to connect to Jumphost {% for jumphost in groups['jumphost'] %}{{ jumphost }}{% endfor %} only

    2.3. **Create session** > **SSH**

    2.4. **Remote host**: {% for jumphost in groups['jumphost'] %}{{ public_ip_addresses[jumphost] }}{% endfor %} 

    2.5. **Specify username**: your-username

    2.6. **Advanced SSH settings** > **Use private key**

      make sure it contains drive letters, like `H:\some\path` and not `\\some\shared\network\path`

    2.7. Click OK, and open this newly created session (you will need to provide password for associated private key)

    2.8. Upon login to the 2FA jumphost, you will be greeted with

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
          * If you loose them and no longer have access to the device you will configure with the QR code below, you will have locked yourself out!
        
        ... multiple lines of QR code to be scanned with mobile Authenticator app ...

    **Save scratch codes somewhere safe**, as they provide access to the system in case you don't have access to the authenticator app and to the WOM (you can also find codes in the file named `.totp` on the jumphosts home folder)

    2.9. Scan the new QR code with your phone and use one of the Authenticator apps to store the secret key (applications links are at the bottom in this page)

    2.10. Now you have configured 2FA and you are able to make connections to the jumphost from non-UMCG IP networks, when you use of Authenticator app.

    2.11. Optional step: if you have more accounts on the jumphost server, simply repeat steps 2.x. for each username

3. Subsequent connections from untrusted IP addresses trough 2FA jumphosts (to limited-access machines)

    ![connection overview](img/2FA-following.png)
            
    After user created the 2FA time-based key, the connections to jumphost server from any IP address will have to provide:

    - the correct public/private key pair, and

    - 2FA Time-based key, that is made on user's mobile app
          
    When user (with already created 2FA key) connects from untrusted IP to the 2FA enhanced jumphost, prompt will appear:

    `(your-username@{% for jumphost in groups['jumphost'] %}{{ public_ip_addresses[jumphost] }}{% endfor %}) Your verification code for {% for jumphost in groups['jumphost'] %}{{ jumphost }}{% endfor %}:`

    Users mobile app generates 2FA code that is valid for short (30 seconds) time, after it expires and another one is generated. Codes are also different for each username on each server, so in case you have more than one, make sure you are using the correct one.

4. Issues

    **I cannot connect to the jumphost**

    When connecting to server you get

    `your-username@{% for jumphost in groups['jumphost'] %}{{ public_ip_addresses[jumphost] }}{% endfor %}: Permission denied (keyboard-interactive).`

    **Solution**:

    - check if you are using the correct username, and that you have created 2FA key for this username

    - if 2FA key is missing, create new 2FA key (steps `2.x`)

###### Links


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
