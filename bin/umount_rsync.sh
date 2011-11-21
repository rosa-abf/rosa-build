#!/bin/bash

for f in `ls /srv/rosa_build/current/tmp/umount`
do
  umount "/srv/rosa_build/shared/downloads/$f"
  rm -Rf "/srv/rosa_build/shared/downloads/$f"
  rm -Rf "/srv/rosa_build/current/tmp/umount/$f"
done
