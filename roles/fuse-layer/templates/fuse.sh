source "/apps/modules//modules.bashrc"
module load Java/8-LTS

java -Xmx2g -jar /usr/local/fuse-layer/ega-fuse-1.0-SNAPSHOT.jar \
-f /usr/local/fuse-layer/config.ini \
-m "{{ fuse_mountpoint }}" \
-u "{{ fuse_user }}" \
-p "{{ fuse_password }}"
