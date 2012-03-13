# -*- encoding : utf-8 -*-
module BuildListsHelper
  
  def build_list_status(build_list)
    if [BuildList::BUILD_PUBLISHED, BuildServer::SUCCESS].include? build_list.status
      "success"
    elsif [BuildServer::BUILD_ERROR, BuildServer::PLATFORM_NOT_FOUND, BuildServer::PROJECT_NOT_FOUND, 
      BuildServer::PROJECT_VERSION_NOT_FOUND, BuildList::FAILED_PUBLISH].include? build_list.status
      "error"
    end
  end
  
end