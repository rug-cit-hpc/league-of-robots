#jinja2: trim_blocks:False
# Crunching on Solve-RD data. How and where to access Solve-RD data on {{ slurm_cluster_name | capitalize }}

### First: getting an account and starting a session on a User Interface (UI) server

In order to work with Slurm and manage jobs on the cluster you'll need a personal account and start a session on a User Interface (UI) server.
If you are completely new here, please:

 * [follow these instructions to request an account](../accounts/).
 * [follow these instructions to login using your account](../logins/).

## Sample availability via EGA FUSE client or manual file transfers using pyEGA3.
Solve-RD samples are readonly available on {{ slurm_cluster_name | capitalize }} via a EGA FUSE layer. You can read more about this [here](https://github.com/EGA-archive/ega-fuse-client).
The mountpoint of the directory with the available samples is located here: {{ fuse_mountpoint }}. From there samples can be checkout to ```/groups/${group}/tmp0*/...``` to do your magic on it.
Unfortunately the download speed is sub-optimal, so you may also choose fetching larger datasets directly from the data-archive via download tool pyEGA3.  

### 1. Fetching files with pyEGA3.
To be able to use pyEGA3 you need a username and password provided by the EGA. To get this follow instructions [here](https://ega-archive.org) or contact you contactperson by the EGA.

Then add your credentials into a ```credentials.json ```[example](https://github.com/EGA-archive/ega-download-client/blob/master/pyega3/config/default_credential_file.json) which is users during  data transfer. 
To read more about pyEGA3 follow this [link](https://github.com/EGA-archive/ega-download-client).

## example for downloading all files corresponding to a E-ID.

```
echo "load module pyEGA3"
module load pyEGA3

echo "make outputdir"
outputdir="/groups/solve-rd/tmp10/username/yourdir"
mkdir  ${yourdir}

echo "Get all sampleID for a datasets into a tmp file"
pyega3 -cf credentials.json files EGAD00001005352 > tmp
 
echo "grep files corresponding for a example sampleID."
grep E577011 tmp | awk '{print $1}' >> ega.ids
 
echo "copy sample"
for i in $( cat ega.ids | awk '{print $1}') ; do pyega3 -cf credentials.json -c 10 fetch $i --saveto ${outputdir} ;done
```

Or see a more extended examples here: ```/groups/solve-rd/prm10/example_scripts```