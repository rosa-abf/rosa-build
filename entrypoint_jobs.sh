#!/bin/sh
set -ex

rm -f /mnt/gitstore
ln -sv /home/mnt/gitstore /mnt/gitstore

RUBYOPT="-W0" bundle exec puma -C /rosa-build/config/puma/production_jobs.rb --control-url unix:///tmp/pumactl_jobs.sock --control-token red37
