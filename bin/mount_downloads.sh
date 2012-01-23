#!/bin/bash

for f in `ls /srv/rosa_build/shared/downloads`
do
  if [ -d /home/share ]
    # Staging case
	  if [ -d /home/share/platforms/$f ]
  	then
      sudo umount /srv/rosa_build/shared/downloads/$f 2>&1 >> /dev/null
    	sudo mount --bind /home/share/platforms/$f /srv/rosa_build/shared/downloads/$f
  	fi
  else
    # Production case
	  if [ -d /share/platforms/$f ]
  	then
      sudo umount /srv/rosa_build/shared/downloads/$f 2>&1 >> /dev/null
    	sudo mount --bind /share/platforms/$f /srv/rosa_build/shared/downloads/$f
  	fi
  fi	
done