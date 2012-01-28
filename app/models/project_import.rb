class ProjectImport < ActiveRecord::Base
  belongs_to :project

  validates :name, :uniqueness => {:case_sensitive => false}, :presence => true

  scope :by_name, lambda {|name| where('project_imports.name ILIKE ?', name)}

  after_initialize lambda {|r| r.file_mtime ||= Time.current - 10.years } # default
end
