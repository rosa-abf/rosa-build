#!/bin/sh
set -ex

if [ -f /MIGRATE ]
then
        bundle exec rake db:migrate
        rm /MIGRATE
fi

#bundle exec rake assets:precompile
cd public/assets
rm -f new_application.css new_application.js
ln -sv new_application*.css new_application.css
ln -sv new_application*.js new_application.js
cd ../..
bundle exec puma -C /rosa-build/config/puma/production.rb
