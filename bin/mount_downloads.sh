#!/bin/bash

for f in `ls /srv/rosa_build/shared/downloads`
do
	if [ -d "/home/share/platforms/$f" ]
	then
  	mount --bind "/home/share/platforms/$f" "/srv/rosa_build/shared/downloads/$f"
	fi
done
