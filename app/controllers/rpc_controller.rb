class RpcController < ApplicationController
  exposes_xmlrpc_methods

  before_filter :authenticate_user!
  
  ## Usage example:
  #
  # require 'xmlrpc/client'
  # client = XMLRPC::Client.new("127.0.0.1", '/api/xmlrpc', 3000, nil, nil, 'user@email', 'password', false, 900)
  # client.call("project_versions", 1)

  def platforms
    return Platform.select('id, unixname').where("platform_type = ?", 'main').map(&:attributes)
  end
  
  def user_projects
    current_user.projects.map{|pr| { :id => pr.id, :unixname => pr.unixname } }
  end
  
  def project_versions id
    pr = Project.findby_id(id)
    return nil if pr.blank?
    pr.project_versions.collect { |tag| [tag.name.gsub(/^\w+\./, ""), tag.name] }.select { |pv| pv[1] =~ /^v\./  }
  end
  
  def build_status id
    BuildList.find_by_id(id).try(:status)
  end
  
  def build_packet project_id, repo_id
    # TODO: build packet
  end
  
  

end