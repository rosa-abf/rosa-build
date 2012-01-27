class ProjectImport < ActiveRecord::Base
  belongs_to :project

  after_initialize lambda {|r| r.file_mtime ||= Time.current - 10.years } # default
end
