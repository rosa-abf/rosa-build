#!/bin/bash

mv /opt/nginx/logs/access.log /opt/nginx/logs/access.log.0
/opt/nginx/sbin/nginx -s reload
chown rosa /opt/nginx/logs/access.log.0
touch /home/rosa/i_was_launched.txt