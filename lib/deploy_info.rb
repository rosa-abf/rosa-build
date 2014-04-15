# This file gets overwritten during deploy process
module DeployInfo
  BRANCH=`git rev-parse --abbrev-ref HEAD`.strip
  GIT_COMMIT=`git rev-parse HEAD`.strip
  BUILD_NUMBER='dev'
  BUILD_ID='dev'
  DEPLOYER=`git config user.name`.strip

  def message
    `git log -1 --pretty=medium`.strip
  end

  module_function :message
end
