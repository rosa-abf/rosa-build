#!/bin/bash

for f in `ls /srv/rosa_build/current/tmp/mount`
do
  mkdir -p "/srv/rosa_build/shared/downloads/$f"
  mount --bind "/home/share/platforms/$f" "/srv/rosa_build/shared/downloads/$f"
  cp -f /srv/rosa_build/current/tmp/mount/$f/* /home/share/platforms/$f/
  rm -Rf "/srv/rosa_build/current/tmp/mount/$f"
done
