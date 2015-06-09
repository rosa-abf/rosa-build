#!/bin/bash -e

rspec="bundle exec rspec"

if [ $SPEC_GROUP = 'controllers' ]
then
  $rspec spec/controllers/*_spec.rb spec/controllers/admin/ spec/controllers/groups/ spec/controllers/projects/ spec/controllers/users/
elif [ $SPEC_GROUP = 'platform_controllers' ]
then
  $rspec spec/controllers/platforms/
elif [ $SPEC_GROUP = 'api-slow' ]
then
  $rspec spec/controllers/api/v1/ --pattern build_lists*
elif [ $SPEC_GROUP = 'api' ]
then
  $rspec spec/controllers/api/v1/ --exclude-pattern build_lists*
elif [ $SPEC_GROUP = 'models' ]
then
  $rspec spec/models/ spec/jobs/
elif [ $SPEC_GROUP = 'others' ]
then
  # $rspec spec/helpers/ spec/integration/ spec/lib/ spec/mailers/ spec/mailers/ spec/routing/
  $rspec spec/integration/ spec/services/ spec/mailers/ spec/mailers/ spec/routing/
fi
