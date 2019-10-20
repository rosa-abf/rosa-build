#!/bin/sh
set -ex

rm -f /mnt/gitstore
ln -sv /home/mnt/gitstore /mnt/gitstore

bundle exec rake resque:workers
