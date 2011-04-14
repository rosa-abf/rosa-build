require 'xmlrpc/client'
class BuildServer

  SUCCESS = 0
  ERROR = 1

  PLATFORM_NOT_FOUND = 1
  PLATFORM_PENDING = 2
  PROJECT_NOT_FOUND = 3
  BRANCH_NOT_FOUND = 4

  BUILD_ERROR = 2500
  MOCK_NOT_FOUND = 256
  DEPENDENCIES_FAIL = 7680
  SRPM_NOT_FOUND = 12800

  def self.client
    Rails.logger.info "Client called"
    @@client ||= XMLRPC::Client.new3('host' => APP_CONFIG['build_server_ip'], 'port' => APP_CONFIG['build_server_port'], 'path' => APP_CONFIG['build_server_path'])
    Rails.logger.info "Client finished"
    return @@client
  end


  def self.add_platform name, root_folder, repos = []
    Rails.logger.info "add_platform start"
    Rails.logger.info "#{name.inspect}, #{root_folder.inspect}, #{repos.inspect}"
    self.client.call('add_platform', name, root_folder, repos)
    Rails.logger.info "add_platform ok"
  end


  def self.delete_platform name
    self.client.call('delete_platform', name)
  end


  def self.clone_platform new_name, old_name, new_root_folder
    self.client.call('clone_platform', new_name, old_name, new_root_folder)
  end


  def self.create_repo name, platform_name
    self.client.call('create_repository', name, platform_name)
  end


  def self.delete_repo name, platform_name
    self.client.call('delete_repository', name, platform_name)
  end

  def self.clone_repo new_name, old_name, new_platform_name
    self.client.call('clone_repo', new_name, old_name, new_platform_name)
  end


  def self.publish_container container_id
    self.client.call('publish_container', container_id)
  end

  def self.delete_container container_id
    self.client.call('delete_container', container_id)
  end

  def self.create_project name, platform_name, repo_name
    self.client.call('create_project', name, platform_name, repo_name)
  end

  def self.delete_project name, platform_name
    self.client.call('delete_project', name, platform_name)
  end

  def self.add_to_repo name, repo_name
    self.client.call('add_to_repo', name, repo_name)
  end

  def self.add_build_list project_name, branch_name, platform_name, arch_name
    self.client.call('add_build_list', project_name, branch_name, platform_name, arch_name)
  end

  def self.freeze platform_name, new_repo_name = nil
    self.client.call('freeze_platform', platform_name, new_repo_name)
  end
end
