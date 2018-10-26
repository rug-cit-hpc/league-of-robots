#!/bin/bash

# Start the nslcd daemon in the background and then start slurmdbd.

nslcd

/usr/sbin/slurmdbd -D
