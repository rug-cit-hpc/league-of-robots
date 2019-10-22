ml Java/8-JDK

${EBROOTJAVA}/java -Xmx2g -jar /usr/local/fuse-layer/ega-fuse-1.0-SNAPSHOT.jar \
-f /usr/local/fuse-layer/config.ini \
-m "{{ fuse_mountpoint }}" \
-u "{{ fuse_user }}" \
-p "{{ fuse_password }}"
