#!/bin/sh
set -ex

if [ -f /MIGRATE ]
then
        bundle exec rake db:migrate
        rm /MIGRATE
fi

bundle exec rake assets:precompile
bundle exec puma -C /rosa-build/config/puma/production.rb
