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

  after_destroy :remove_archive_from_file_store

  def remove_archive_from_file_store(sha = sha1)
    token   = User.find_by_uname('file_store').authentication_token
    system "curl --user #{token}: -X DELETE #{APP_CONFIG['file_store_url']}/api/v1/file_stores/#{sha}.json"
  end
  later :remove_archive_from_file_store, :queue => :clone_build

end
