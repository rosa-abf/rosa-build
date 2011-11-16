class Relation < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :object, :polymorphic => true

  #has_many :role_lines
  #has_many :roles, :autosave => true, :through => :role_lines
  
  ROLES = %w[read write]
  
  validates :role, :inclusion => {:in => ROLES}
  
  #bitmask :roles, :as => [:read, :update] 

  after_create {
    with_ga do |ga|
      if repo = ga.find_repo(target.git_repo_name) and key = object.ssh_key and key.present?
        repo.add_key(key, 'RW', :force => true)
        ga.save_and_release
      end
    end if target_type == 'Project' and object_type == 'User'
  }
  after_destroy {
    with_ga do |ga|
      if repo = ga.find_repo(target.git_repo_name) and key = object.ssh_key and key.present?
        repo.rm_key(key)
        ga.save_and_release
      end
    end if target_type == 'Project' and object_type == 'User'
  }
  
  #after_create {
  #  if self.role.blank?
  #    update_attribute(:role, 'read')
  #  end
  #}

  scope :by_object, lambda {|obj| {:conditions => ['object_id = ? AND object_type = ?', obj.id, obj.class.to_s]}}
  scope :by_target, lambda {|tar| {:conditions => ['target_id = ? AND target_type = ?', tar.id, tar.class.to_s]}}
end
