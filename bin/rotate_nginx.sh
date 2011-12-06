#!/bin/bash

mv /srv/rosa_build/shared/log/nginx.access.log /srv/rosa_build/shared/log/nginx.access.log.0
/etc/init.d/nginx reload
chown rosa /srv/rosa_build/shared/log/nginx.access.log.0
# touch /home/rosa/i_was_launched.txt
