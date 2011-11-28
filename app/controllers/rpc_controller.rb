class RpcController < ApplicationController
  exposes_xmlrpc_methods

  before_filter :authenticate_user!
  before_filter lambda { EventLog.current_controller = self }, :only => :xe_index # should be after auth callback

  ## Usage example:
  #
  # require 'xmlrpc/client'
  # client = XMLRPC::Client.new("127.0.0.1", '/api/xmlrpc', 3000, nil, nil, 'user@email', 'password', false, 900)
  # client.call("project_versions", 1)

  def platforms
    ActiveSupport::Notifications.instrument("event_log.observer", :message => 'список платформ')
    Platform.select('name').where("platform_type = ?", 'main').map(&:name)
  end

  def user_projects
    ActiveSupport::Notifications.instrument("event_log.observer", :message => 'список пользовательских проектов')
    current_user.projects.map{|p| { :id => p.id, :name => p.name } }
  end

  def project_versions id
    p = Project.find_by_id(id)
    ActiveSupport::Notifications.instrument("event_log.observer", :object => p, :message => "список версий")
    p.project_versions.collect {|tag| tag.name.gsub(/^\w+\./, "")} rescue 'not found'
  end

  def build_status id
    bl = BuildList.find_by_id(id)
    ActiveSupport::Notifications.instrument("event_log.observer", :object => bl, :message => 'статус сборки')
    bl.try(:status) || 'not found'
  end

  def build_packet project_id, repo_id
    # p = Project.find_by_id(project_id); r = Repository.find_by_id(repo_id)
    ActiveSupport::Notifications.instrument("event_log.observer", :message => 'сборка пакета')
    'unknown' # TODO: build packet
  end
end
