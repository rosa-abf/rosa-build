#!/bin/bash

for f in `ls /srv`
do
  sudo -u rosa bundle exec bluepill --no-privileged load /srv/$f/current/config/production.pill APP_NAME=$f
done

/srv/rosa_build/current/bin/mount_downloads.sh
