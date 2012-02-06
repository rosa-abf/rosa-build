# -*- encoding : utf-8 -*-
class ProjectToRepository < ActiveRecord::Base
  belongs_to :project
  belongs_to :repository
  
  delegate :path, :to => :project

  after_create lambda { project.xml_rpc_create(repository) }, :unless => lambda {Thread.current[:skip]}
  after_destroy lambda { project.xml_rpc_destroy(repository) }
  # after_rollback lambda { project.xml_rpc_destroy(repository) rescue true if new_record? }

  validate :one_project_in_platform_repositories

  protected

  def one_project_in_platform_repositories
    errors.add(:project, 'should be one in platform') if Project.joins(:repositories => :platform).
                                                                 where('platforms.id = ?', repository.platform_id).by_name(project.name).count > 0
  end
end
