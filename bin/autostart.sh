#!/bin/bash

for f in `ls /srv`
do
  sudo -u rosa bundle exec APP_NAME=$f bluepill --no-privileged load /srv/$f/current/config/production.pill
done

/srv/rosa_build/current/bin/mount_downloads.sh
