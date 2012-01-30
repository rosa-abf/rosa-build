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
    ActiveSupport::Notifications.instrument "event_log.observer", :message => I18n.t('event_log.notices.platforms_list')
    Platform.select('name').where("platform_type = ?", 'main').map(&:name)
  end

  def user_projects
    ActiveSupport::Notifications.instrument "event_log.observer", :message => I18n.t('event_log.notices.users_list')
    current_user.projects.map{|p| { :id => p.id, :name => p.name } }
  end

  def project_versions id
    p = Project.find_by_id(id)
    ActiveSupport::Notifications.instrument "event_log.observer", :object => p, :message => I18n.t('event_log.notices.versions_list')
    p.tags.map(&:name) rescue 'not found'
  end

  def build_status id
    bl = BuildList.find_by_id(id)
    ActiveSupport::Notifications.instrument "event_log.observer", :object => bl, :message => I18n.t('event_log.notices.status')
    bl.try(:status) || 'not found'
  end

  def build_packet project_id, repo_id
    # p = Project.find_by_id(project_id); r = Repository.find_by_id(repo_id)
    ActiveSupport::Notifications.instrument "event_log.observer", :message => I18n.t('event_log.notices.project_build')
    'unknown' # TODO: build packet
  end
end
