class ProjectToRepository < ActiveRecord::Base
  belongs_to :project
  belongs_to :repository
  
  delegate :path, :to => :project

  after_create lambda { project.xml_rpc_create(repository) }, :unless => lambda {Thread.current[:skip]}
  after_destroy lambda { project.xml_rpc_destroy(repository) }
  # after_rollback lambda { project.xml_rpc_destroy(repository) rescue true if new_record? }
end
