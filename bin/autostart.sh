#!/bin/bash

for f in `ls /srv`
do
  su -l rosa -c "cd /srv/$f/current && APP_NAME=$f bundle exec bluepill --no-privileged load /srv/$f/current/config/production.pill"
done

/srv/rosa_build/current/bin/mount_downloads.sh
