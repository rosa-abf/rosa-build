# -*- encoding : utf-8 -*-
module PlatformsHelper
  def repository_name_postfix(platform)
     return "" unless platform
     return platform.released ? '/update' : '/release'
  end
end
