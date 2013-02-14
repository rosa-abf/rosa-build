# -*- encoding : utf-8 -*-
class ProjectTag < ActiveRecord::Base
  FORMATS = {
    'zip'     => 0,
    'tar.gz'  => 1
  }

  belongs_to :project

  validates :project_id, :commit_id, :sha1, :tag_name, :format_id, :presence => true
  validates :project_id, :uniqueness => {:scope => [:tag_name, :format_id]}

  attr_accessible :project_id,
                  :commit_id,
                  :sha1,
                  :tag_name,
                  :format_id

end
