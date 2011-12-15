#!/bin/bash

for f in `ls /srv/rosa_build/shared/downloads`
do
	if [ -d /home/share/platforms/$f ]
	then
    sudo umount /srv/rosa_build/shared/downloads/$f 2>&1 >> /dev/null
  	sudo mount --bind /home/share/platforms/$f /srv/rosa_build/shared/downloads/$f
	fi
done
