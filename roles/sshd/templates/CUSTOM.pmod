############################################################################################
# Mapping ciphers/algorithms to cipher suites / families is a mess.                        #
# For available mappings see Python code in repo at                                        #
#     https://gitlab.com/redhat-crypto/fedora-crypto-policies/tree/master\                 #
#     /python/policygenerators/*.py                                                        #
# or on the machine at                                                                     #
#     /usr/share/crypto-policies/python/policygenerators/*.py s.                           #
# E.g. one of the mappins is:                                                              #
#    ECDHE-SECP256R1-SHA2-256': 'ecdh-sha2-nistp256',                                      #
# where                                                                                    #
#    ECDHE-SECP256R1-SHA2-256 = value used by the system wide "crypto_policies",           #
#                               which is in the format key_exchange-group-hash:            #
#        ECDHE     = value for key_exchange@SSH in this config file.                       #
#        SECP256R1 = value for group@SSH in this config file.                              #
#        SHA2-256  = value for hash@SSH in this config file.                               #
#    ecdh-sha2-nistp256 = corresponding value for "KexAlgorithms" in OpenSSH config files. #
# See the policy files in                                                                  #
#     /usr/share/crypto-policies/policies/*.pol                                            #
# for possible values for key_exchange@SSH, group@SSH, hash@SSH, etc.                      #
# All subpolicy files must have a name consisting of subpolicy in UPPERCASE                #
# and extension in lowercase: SUBPOLICY.pmod                                               #
############################################################################################

#
# Require at least 4096 bits for all RSA ciphers.
#
min_rsa_size@SSH = 4096
#
# CBC ciphers in SSH are considered vulnerable to plaintext recovery attacks
# and disabled by default in client OpenSSH 7.6 (2017) and server OpenSSH 6.7 (2014).
#
cipher@SSH = -*-CBC
#
# For Key EXchange (KEX):
#  * Disable NIST ecdh-sha2-nistp* algorithms (SECP* groups)
#  * Disable diffie-hellman-group algorithms with < 4096 bits (FFDHE groups < 4096)
#  * Enable sntrup761x25519-sha512@openssh.com (SNTRUP key_exchange).
#    The post-quantum sntrup761 algorithm is already available in the OpenSSH suite
#    and provides better security against attacks from quantum computers.
#
group@SSH = -SECP256R1 -SECP521R1 -SECP384R1 -FFDHE-2048 -FFDHE-3072
key_exchange@SSH = +SNTRUP
mac@SSH = -HMAC-SHA1*
sign@SSH = -ECDSA-*